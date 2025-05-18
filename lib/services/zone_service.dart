import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/zone.dart';

class ZoneService {
  final String baseUrl = 'http://localhost:8081';

  Future<List<Zone>> getZonesByOrgId(String orgId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/zones?orgId=$orgId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['statusCode'] == 200) {
          final List<dynamic> zonesData = responseData['data'];
          return zonesData.map((zoneData) => Zone(
            id: zoneData['id'],
            zoneName: zoneData['zoneName'],
            orgId: zoneData['orgId'],
            approved: zoneData['approved'] ?? false,
            createdAt: DateTime.parse(zoneData['createdAt']),
            createdBy: zoneData['createdBy'] ?? 'system',
          )).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load zones');
        }
      } else {
        throw Exception('Failed to load zones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading zones: $e');
    }
  }
} 