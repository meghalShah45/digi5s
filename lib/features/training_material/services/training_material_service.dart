import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/training_material_model.dart';
import 'dart:convert';

class TrainingMaterialService {
  final String baseUrl = 'http://localhost:8081';

  Future<List<TrainingMaterial>> getTrainingMaterials() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/training-material'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['statusCode'] == 200 && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => TrainingMaterial.fromJson(item)).toList();
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to fetch training materials');
      }
      throw Exception('Failed to fetch training materials: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching training materials: $e');
    }
  }

  Future<List<TrainingMaterial>> uploadTrainingMaterial({
    required String orgId,
    required String materialType,
    required File file,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/training-material'),
      );

      request.fields['orgId'] = orgId;
      request.fields['materialType'] = materialType;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'png'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(responseData);
        if (jsonResponse['statusCode'] == 200 && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => TrainingMaterial.fromJson(item)).toList();
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to upload training material');
      }
      throw Exception('Failed to upload training material: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error uploading training material: $e');
    }
  }

  Future<List<TrainingMaterial>> updateTrainingMaterial({
    required String id,
    required String materialType,
    required String path,
    required bool approved,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/training-material/$id'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'materialType': materialType,
          'path': path,
          'approved': approved,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['statusCode'] == 200 && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => TrainingMaterial.fromJson(item)).toList();
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to update training material');
      }
      throw Exception('Failed to update training material: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating training material: $e');
    }
  }

  Future<List<TrainingMaterial>> deleteTrainingMaterial(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/training-material/$id'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['statusCode'] == 200 && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => TrainingMaterial.fromJson(item)).toList();
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to delete training material');
      }
      throw Exception('Failed to delete training material: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error deleting training material: $e');
    }
  }
} 