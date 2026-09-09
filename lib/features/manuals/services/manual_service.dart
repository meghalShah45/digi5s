import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/manual.dart';
import '../../../core/config/app_config.dart';

class ManualService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();

  Future<List<Manual>> getManuals() async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/manual'),
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Manual.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load manuals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching manuals: $e');
    }
  }

  Future<List<Manual>> getManualsByZoneId(String zoneId) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/manual/zone/$zoneId'),
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Manual.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load manuals for zone: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching zone manuals: $e');
    }
  }

  Future<List<Manual>> uploadManual({
    required String orgId,
    required String zoneId,
    required String zoneName,
    required String name,
    File? file,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/manual'));
      
      // Add headers (matching the curl command)
      request.headers['accept'] = 'application/json';
      // Temporarily commenting out auth to test
      // if (token != null) {
      //   request.headers['Authorization'] = 'Bearer $token';
      // }
      
      // Add fields (matching the curl command format)
      request.fields['orgId'] = orgId;
      request.fields['zoneId'] = zoneId;
      request.fields['name'] = name;
      // Note: Removed zoneName field as it's not in the curl command
      
      // Debug logging
      print('=== Manual Upload Request Debug ===');
      print('URL: ${request.url}');
      print('Headers: ${request.headers}');
      print('Fields: ${request.fields}');
      print('Has file: ${file != null}');
      if (file != null) {
        print('File path: ${file.path}');
        print('File exists: ${file.existsSync()}');
      }
      
      // Add file if provided
      if (file != null) {
        // Determine content type based on file extension
        final fileName = file.path.split('/').last.toLowerCase();
        MediaType contentType;
        
        if (fileName.endsWith('.png')) {
          contentType = MediaType('image', 'png');
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          contentType = MediaType('image', 'jpeg');
        } else if (fileName.endsWith('.pdf')) {
          contentType = MediaType('application', 'pdf');
        } else {
          throw Exception('Unsupported file type. Supported types are PNG, JPG, JPEG, and PDF');
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: contentType,
          ),
        );
        
        print('File added with content type: $contentType');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Manual upload response status: ${response.statusCode}');
      print('Manual upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Manual.fromJson(json)).toList();
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to upload manual: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading manual: $e');
    }
  }

  Future<void> deleteManual(String manualId) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('$baseUrl/manual/$manualId'),
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to delete manual: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting manual: $e');
    }
  }
} 