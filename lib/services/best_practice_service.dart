import 'dart:io';

import '../core/api/api_client.dart';
import '../core/auth/session.dart';

/// Best practices. Methods return the raw response envelope
/// (`{statusCode, message, data}`) because the screen reads it directly.
class BestPracticeService {
  BestPracticeService([ApiClient? api, SessionStore? store])
      : _store = store ?? SessionStore(),
        _api = api ?? ApiClient(sessionStore: store ?? SessionStore());

  final ApiClient _api;
  final SessionStore _store;

  Future<Map<String, dynamic>> createBestPractice({
    required String title,
    required String zone,
    required String description,
    required File file,
  }) async {
    final orgId = (await _store.read())?.orgId ?? '';
    if (orgId.isEmpty) throw const ApiException(400, 'Your account is not linked to an organisation.');
    final res = await _api.multipart(
      'POST',
      '/best-practices',
      fields: {'orgId': orgId, 'title': title.trim(), 'zone': zone, 'description': description.trim()},
      files: [ApiFile(field: 'file', path: file.path)],
    );
    return res.raw;
  }

  Future<Map<String, dynamic>> updateBestPractice({
    required String id,
    required String title,
    required String zone,
    required String description,
    File? file,
  }) async {
    final res = await _api.multipart(
      'PUT',
      '/best-practices/$id',
      fields: {'title': title.trim(), 'zone': zone, 'description': description.trim()},
      files: [if (file != null) ApiFile(field: 'file', path: file.path)],
    );
    return res.raw;
  }

  Future<void> deleteBestPractice(String id) => _api.delete('/best-practices/$id');

  /// Best practices for the logged-in user's organisation
  /// (`GET /best-practices/org/{orgId}`), newest first.
  Future<Map<String, dynamic>> getBestPractices() async {
    final orgId = (await _store.read())?.orgId ?? '';
    final res = await _api.get(orgId.isEmpty ? '/best-practices' : '/best-practices/org/$orgId');
    final list = res.list..sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    return {...res.raw, 'data': list};
  }
}
