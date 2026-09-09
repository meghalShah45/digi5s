import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../auth/session.dart';
import '../config/app_config.dart';

/// Thrown for any failed call. [statusCode] is the *logical* code from the
/// response body when present (the backend answers HTTP 200 for most
/// logical failures), otherwise the transport code.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  const ApiException(this.statusCode, this.message, {this.data});

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// A decoded backend response. Handles both envelopes the backend uses:
///   `{ statusCode, status, error, message, data }`
///   `{ statusCode, message, data }`
class ApiResponse {
  final int statusCode;
  final String message;
  final dynamic data;
  final Map<String, dynamic> raw;

  const ApiResponse({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.raw,
  });

  bool get ok => statusCode >= 200 && statusCode < 300;

  /// `data` as a list of maps (empty when absent).
  List<Map<String, dynamic>> get list {
    final d = data;
    if (d is List) {
      return d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  /// `data` as a map (empty when absent). If `data` is a one-element list the
  /// first element is returned, which matches several "returning('*')" routes.
  Map<String, dynamic> get map {
    final d = data;
    if (d is Map) return Map<String, dynamic>.from(d);
    if (d is List && d.isNotEmpty && d.first is Map) {
      return Map<String, dynamic>.from(d.first as Map);
    }
    return const {};
  }
}

/// A file to attach to a multipart request.
class ApiFile {
  final String field;
  final String path;
  final String? filename;
  final String? mimeType;
  const ApiFile({required this.field, required this.path, this.filename, this.mimeType});
}

/// Single HTTP entry point. Attaches the Bearer token, decodes the envelope,
/// and throws [ApiException] on failure.
class ApiClient {
  ApiClient({
    required SessionStore sessionStore,
    http.Client? client,
    this.onUnauthorized,
    String? baseUrl,
  })  : _store = sessionStore,
        _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final SessionStore _store;
  final http.Client _client;
  final String baseUrl;

  /// Called when the server rejects the token (transport 401).
  final FutureOr<void> Function()? onUnauthorized;

  Uri uri(String path, [Map<String, String?>? query]) {
    final clean = path.startsWith('/') ? path : '/$path';
    final q = query?.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .map((e) => MapEntry(e.key, e.value!));
    return Uri.parse('$baseUrl$clean').replace(
      queryParameters: (q == null || q.isEmpty) ? null : Map.fromEntries(q),
    );
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _store.readToken();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse> get(String path, {Map<String, String?>? query}) =>
      _send(() async => _client.get(uri(path, query), headers: await _headers()));

  Future<ApiResponse> post(String path, {Object? body, Map<String, String?>? query}) =>
      _send(() async => _client.post(uri(path, query),
          headers: await _headers(), body: body == null ? null : jsonEncode(body)));

  Future<ApiResponse> put(String path, {Object? body, Map<String, String?>? query}) =>
      _send(() async => _client.put(uri(path, query),
          headers: await _headers(), body: body == null ? null : jsonEncode(body)));

  Future<ApiResponse> patch(String path, {Object? body, Map<String, String?>? query}) =>
      _send(() async => _client.patch(uri(path, query),
          headers: await _headers(), body: body == null ? null : jsonEncode(body)));

  Future<ApiResponse> delete(String path, {Object? body, Map<String, String?>? query}) =>
      _send(() async => _client.delete(uri(path, query),
          headers: await _headers(), body: body == null ? null : jsonEncode(body)));

  /// Multipart request. [fields] are sent as form fields, [files] as file
  /// parts. Null field values are skipped.
  Future<ApiResponse> multipart(
    String method,
    String path, {
    Map<String, String?> fields = const {},
    List<ApiFile> files = const [],
    Map<String, String?>? query,
  }) {
    return _send(() async {
      final req = http.MultipartRequest(method.toUpperCase(), uri(path, query));
      req.headers.addAll(await _headers(json: false));
      fields.forEach((k, v) {
        if (v != null) req.fields[k] = v;
      });
      for (final f in files) {
        final file = File(f.path);
        if (!await file.exists()) continue;
        final name = f.filename ?? file.uri.pathSegments.last;
        req.files.add(await http.MultipartFile.fromPath(
          f.field,
          f.path,
          filename: name,
          contentType: _mediaType(f.mimeType ?? _guessMime(name)),
        ));
      }
      final streamed = await req.send().timeout(AppConfig.uploadTimeout);
      return http.Response.fromStream(streamed);
    }, timeout: AppConfig.uploadTimeout);
  }

  Future<ApiResponse> _send(Future<http.Response> Function() fn, {Duration? timeout}) async {
    http.Response res;
    try {
      res = await fn().timeout(timeout ?? AppConfig.requestTimeout);
    } on SocketException {
      throw const ApiException(0, 'No internet connection. Please check your network.');
    } on TimeoutException {
      throw const ApiException(0, 'The server took too long to respond. Please try again.');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Network error: ${e.message}');
    }

    if (res.statusCode == 401) {
      await onUnauthorized?.call();
      throw const ApiException(401, 'Your session has expired. Please log in again.');
    }

    Map<String, dynamic> body;
    try {
      final decoded = res.body.isEmpty ? {} : jsonDecode(res.body);
      body = decoded is Map ? Map<String, dynamic>.from(decoded) : {'data': decoded};
    } catch (_) {
      throw ApiException(res.statusCode, 'Unexpected response from server (${res.statusCode}).');
    }

    final code = _asInt(body['statusCode']) ?? res.statusCode;
    final message = _message(body, res.statusCode);
    final response = ApiResponse(statusCode: code, message: message, data: body['data'], raw: body);

    // Envelope A carries `status: false` on failure even with a 2xx code.
    final flaggedFailure = body['status'] == false && code < 400;
    if (!response.ok || flaggedFailure) {
      throw ApiException(flaggedFailure ? 400 : code, message, data: body['data']);
    }
    return response;
  }

  static String _message(Map<String, dynamic> body, int httpCode) {
    for (final key in ['message', 'error']) {
      final v = body[key];
      if (v is String && v.trim().isNotEmpty) return v;
      if (v is Map && v['message'] is String) return v['message'] as String;
    }
    return httpCode >= 400 ? 'Request failed ($httpCode).' : 'OK';
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt();
    return null;
  }

  static MediaType? _mediaType(String? mime) {
    if (mime == null) return null;
    final parts = mime.split('/');
    return parts.length == 2 ? MediaType(parts[0], parts[1]) : null;
  }

  static String? _guessMime(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      default:
        return null;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    sessionStore: ref.read(sessionStoreProvider),
    onUnauthorized: () => ref.read(sessionProvider.notifier).clear(),
  );
});
