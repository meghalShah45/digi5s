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
} 