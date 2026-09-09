import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../core/config/app_config.dart';

class BestPracticeService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> createBestPractice({
    required String title,
    required String zone,
    required String description,
    required File file,
  }) async {
    final orgId = await storage.read(key: 'orgId') ?? '';
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/best-practices'),
    );

    request.fields['orgId'] = orgId;
    request.fields['title'] = title;
    request.fields['zone'] = zone;
    request.fields['description'] = description;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', 'png'),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseBody);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to create best practice');
    }
  }

  Future<Map<String, dynamic>> updateBestPractice({
    required String id,
    required String title,
    required String zone,
    required String description,
    File? file,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/best-practices/$id'),
    );

    request.fields['title'] = title;
    request.fields['zone'] = zone;
    request.fields['description'] = description;

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to update best practice');
    }
  }

  Future<void> deleteBestPractice(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/best-practices/$id'),
      headers: {
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final jsonResponse = json.decode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Failed to delete best practice');
    }
  }

  Future<Map<String, dynamic>> getBestPractices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/best-practices'),
      headers: {
        'accept': 'application/json',
      },
    );

    final jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to fetch best practices');
    }
  }
} 