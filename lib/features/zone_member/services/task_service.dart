import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../../../core/config/app_config.dart';

class TaskService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  Future<List<Task>> getTasksByUserId() async {
    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId');
      final userId = await storage.read(key: 'userId');

      if (orgId == null || userId == null) {
        throw Exception('User data not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tasks/detailsByUserId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orgId': orgId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((task) => Task.fromJson(task))
            .toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<void> markTaskAsCompleted(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/request-approval/$taskId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'activity': 'Task Approve Request',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark task as completed');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }
} 