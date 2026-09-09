import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/training_material_model.dart';
import 'dart:convert';
import '../../../core/config/app_config.dart';

class TrainingMaterialService {
  final String baseUrl = AppConfig.apiBaseUrl;

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

  Future<Map<String, dynamic>> uploadTrainingMaterial({
    required String orgId,
    required String materialType,
    required File file,
    required String zoneId,
    required String name,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/training-material'),
      );

      request.fields['orgId'] = orgId;
      request.fields['zoneId'] = zoneId;
      request.fields['materialType'] = materialType;
      request.fields['name'] = name;
      
      // Add file if provided
      if (file.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', 'png'),
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      // Debug: Log the response
      print('Upload Response Status: ${response.statusCode}');
      print('Upload Response Body: $responseData');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(responseData);
        if (jsonResponse['statusCode'] == 200) {
          List<TrainingMaterial> materials = [];
          if (jsonResponse['data'] != null) {
            final List<dynamic> data = jsonResponse['data'];
            materials = data.map((item) => TrainingMaterial.fromJson(item)).toList();
          }
          
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Training material uploaded successfully',
            'materials': materials,
          };
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to upload training material');
      }
      throw Exception('Failed to upload training material: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error uploading training material: $e');
    }
  }

  Future<Map<String, dynamic>> updateTrainingMaterial({
    required String id,
    required String materialType,
    required String name,
    required String zoneId,
    File? file,
    bool? approved,
  }) async {
    // try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/training-material/$id'),
      );
      request.fields['materialType'] = materialType;
      request.fields['name'] = name;
      request.fields['zoneId'] = zoneId;
      if (approved != null) {
        request.fields['approved'] = approved.toString();
      }
      if (file != null && file.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', 'png'),
          ),
        );
      }
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(responseData);
        if (jsonResponse['statusCode'] == 200) {
          List<TrainingMaterial> materials = [];
          if (jsonResponse['data'] != null) {
            final List<dynamic> data = jsonResponse['data'];
            materials = data.map((item) => TrainingMaterial.fromJson(item)).toList();
          }
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Training material updated successfully',
            'materials': materials,
          };
        }
        throw Exception(jsonResponse['message'] ?? 'Failed to update training material');
      }
      throw Exception('Failed to update training material: ${response.statusCode}');
    // } catch (e) {
    //   throw Exception('Error updating training material: $e');
    // }
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