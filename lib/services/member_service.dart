import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class MemberService {
  static const String baseUrl = 'http://localhost:8081';

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
    required File file,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/organisation-members'),
      );

      // Add text fields
      request.fields.addAll({
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
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'png'),
        ),
      );

      // Add headers
      request.headers.addAll({
        'accept': 'application/json',
      });

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to create member: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating member: $e');
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
} 