import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/red_tag.dart';

class RedTagService {
  static const String baseUrl = 'http://localhost:8081';

  Future<Map<String, dynamic>> createRedTag({
    required String orgId,
    required String zoneId,
    required String redTagBy,
    required String description,
    required String remarks,
    required File file,
    required String createdBy,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/redtags'));

      // Add text fields
      request.fields['orgId'] = orgId;
      request.fields['zoneId'] = zoneId;
      request.fields['redTagBy'] = redTagBy;
      request.fields['description'] = description;
      request.fields['remarks'] = remarks;
      request.fields['createdBy'] = createdBy;

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'png'),
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'error': responseBody};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<RedTag>> getRedTags(String orgId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/redtags/org/$orgId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => RedTag.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load red tags');
      }
    } catch (e) {
      throw Exception('Error fetching red tags: $e');
    }
  }

  Future<void> updateRedTagStatus(String redTagId, String newStatus, String activity, String actionBy) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/redtags/status/$redTagId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': newStatus,
          'activity': activity,
          'actionBy': actionBy,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update red tag status');
      }
    } catch (e) {
      throw Exception('Error updating red tag status: $e');
    }
  }

  Future<String?> deleteRedTag(String redTagId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/redtags/$redTagId'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        return errorBody['message'] ?? 'Failed to delete red tag';
      }
      return 'Red tag deleted successfully';
    } catch (e) {
      return 'Error deleting red tag: $e';
    }
  }

  Future<void> updateRedTag(String redTagId, {
    required String description,
    required String path,
    required String status,
    required String remarks,
    required String modifiedBy,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/redtags/$redTagId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'description': description,
          'path': path,
          'status': status,
          'remarks': remarks,
          'modifiedBy': modifiedBy,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update red tag');
      }
    } catch (e) {
      throw Exception('Error updating red tag: $e');
    }
  }
} 