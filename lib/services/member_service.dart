import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../core/config/app_config.dart';

class MemberService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> createOrganizationMember({
    required String orgId,
    required String zoneId,
    required String roleId,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String designation,
    required String signupType,
    required String role,
    File? file,
  }) async {
    try {
      print('=== Member Creation Request ===');
      print('orgId: $orgId');
      print('zoneId: $zoneId');
      print('roleId: $roleId');
      print('fullName: $fullName');
      print('email: $email');
      print('phoneNumber: $phoneNumber');
      print('designation: $designation');
      print('signupType: $signupType');
      print('role: $role');
      print('hasFile: ${file != null}');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/organisation-members'),
      );

      // Add text fields in the exact order as the curl request
      final fields = {
        'orgId': orgId,
        'zoneId': zoneId,
        'roleId': roleId,
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'designation': designation,
        'signupType': signupType,
        'role': role,
      };

      print('\n=== Request Fields ===');
      fields.forEach((key, value) {
        print('$key: $value');
      });

      request.fields.addAll(fields);

      // Add file if provided
      if (file != null) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        
        request.files.add(
          http.MultipartFile(
            'file',
            fileStream,
            fileLength,
            filename: file.path.split('/').last,
            contentType: MediaType('image', 'png'),
          ),
        );
        print('\n=== File Info ===');
        print('filename: ${file.path.split('/').last}');
        print('size: $fileLength bytes');
      }

      // Add headers
      request.headers.addAll({
        'accept': 'application/json',
      });

      print('\n=== Request Headers ===');
      request.headers.forEach((key, value) {
        print('$key: $value');
      });

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('\n=== Response ===');
      print('Status Code: ${response.statusCode}');
      print('Body: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(responseData);
        return decodedResponse;
      } else {
        final errorData = json.decode(responseData);
        final errorMessage = errorData['message'] ?? 'Unknown error';
        throw errorMessage;
      }
    } catch (e) {
      print('\n=== Error ===');
      print(e.toString());
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> getZoneMembers({
    required String orgId,
    required String zoneId,
  }) async {
    try {
      print('Fetching members for orgId: $orgId, zoneId: $zoneId');
      final response = await http.post(
        Uri.parse('$baseUrl/users/org/zone'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orgId': orgId,
          'zoneId': zoneId,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch members: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getZoneMembers: $e');
      throw Exception('Error fetching members: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['statusCode'] == 200) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to fetch roles: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching roles: $e');
    }
  }
} 