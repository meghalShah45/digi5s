import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/zone.dart';

class ZoneService {
  final String baseUrl = 'http://localhost:8081';
  final _storage = const FlutterSecureStorage();

  Future<List<Zone>> getZonesByOrgId(String orgId) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/zones?orgId=$orgId'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
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

  /// Get zones filtered by user role and zone assignment
  Future<List<Zone>> getZonesByUserRole(String orgId, String userRole, String? userZoneId) async {
    try {
      final allZones = await getZonesByOrgId(orgId);
      
      // If user is a zone member, only return their assigned zone
      if (userRole.toUpperCase() == 'ZONE-MEMBER' && userZoneId != null) {
        return allZones.where((zone) => zone.id == userZoneId).toList();
      }
      
      // For other roles, return all zones
      return allZones;
    } catch (e) {
      throw Exception('Error loading zones for user: $e');
    }
  }

  /// Get a single zone by ID (for zone members to get their zone details)
  Future<Zone?> getZoneById(String zoneId) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/zones/$zoneId'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['statusCode'] == 200) {
          final zoneData = responseData['data'];
          return Zone(
            id: zoneData['id'],
            zoneName: zoneData['zoneName'],
            orgId: zoneData['orgId'],
            approved: zoneData['approved'] ?? false,
            createdAt: DateTime.parse(zoneData['createdAt']),
            createdBy: zoneData['createdBy'] ?? 'system',
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error loading zone: $e');
    }
  }
} 