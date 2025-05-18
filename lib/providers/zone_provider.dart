import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/zone_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final zoneListProvider = StateNotifierProvider<ZoneListNotifier, AsyncValue<List<ZoneData>?>>((ref) {
  return ZoneListNotifier();
});

class ZoneListNotifier extends StateNotifier<AsyncValue<List<ZoneData>?>> {
  final _storage = const FlutterSecureStorage();
  
  ZoneListNotifier() : super(const AsyncValue.loading());

  Future<void> fetchZones() async {
    try {
      state = const AsyncValue.loading();
      
      final orgId = await _storage.read(key: 'orgId');
      final token = await _storage.read(key: 'token');
      
      if (orgId == null || token == null) {
        state = const AsyncValue.error('Organization ID or token not found', StackTrace.empty);
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8081/zones/organisation/$orgId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final zoneResponse = ZoneResponse.fromJson(json.decode(response.body));
        state = AsyncValue.data(zoneResponse.data);
      } else {
        final errorResponse = json.decode(response.body);
        state = AsyncValue.error(
          errorResponse['message'] ?? 'Failed to fetch zones',
          StackTrace.empty,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<String> createZone(String zoneName, String description) async {
    try {
      final orgId = await _storage.read(key: 'orgId');
      final token = await _storage.read(key: 'token');
      
      if (orgId == null || token == null) {
        throw Exception('Organization ID or token not found');
      }

      final response = await http.post(
        Uri.parse('http://localhost:8081/zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'zoneName': zoneName,
          'orgId': orgId,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to create zone');
      }

      return responseData['message'] as String;
    } catch (e) {
      rethrow;
    }
  }
} 