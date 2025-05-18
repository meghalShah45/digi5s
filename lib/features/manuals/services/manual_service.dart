import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/manual.dart';

class ManualService {
  static const String baseUrl = 'http://localhost:8081';

  Future<List<Manual>> getManuals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manual'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Manual.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load manuals');
      }
    } catch (e) {
      throw Exception('Error fetching manuals: $e');
    }
  }

  Future<List<Manual>> getManualsByZoneId(String zoneId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manual/zone/$zoneId'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Manual.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load manuals for zone');
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
    required File file,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/manual'));
      
      request.fields['orgId'] = orgId;
      request.fields['zoneId'] = zoneId;
      request.fields['zoneName'] = zoneName;
      request.fields['name'] = name;
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'png'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => Manual.fromJson(json)).toList();
      } else {
        throw Exception('Failed to upload manual');
      }
    } catch (e) {
      throw Exception('Error uploading manual: $e');
    }
  }

  Future<void> deleteManual(String manualId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/manual/$manualId'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete manual');
      }
    } catch (e) {
      throw Exception('Error deleting manual: $e');
    }
  }
} 