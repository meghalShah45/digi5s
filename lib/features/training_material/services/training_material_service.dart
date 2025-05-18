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
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch training materials');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTrainingMaterials: $e'); // Add logging
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
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => TrainingMaterial.fromJson(item)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to upload training material');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in uploadTrainingMaterial: $e'); // Add logging
      throw Exception('Error uploading training material: $e');
    }
  }
} 