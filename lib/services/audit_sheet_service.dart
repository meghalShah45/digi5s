import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/audit/models/audit_sheet.dart';

class AuditSheetService {
  static const String baseUrl = 'http://localhost:8081';

  Future<AuditSheet> createAuditSheet(AuditSheet auditSheet, String zoneId) async {
    try {
      print('Creating audit sheet with data: ${jsonEncode({
        'name': auditSheet.name,
        'zoneId': zoneId,
        'orgId': auditSheet.orgId,
        'month': auditSheet.month,
        'questions': auditSheet.questions.map((q) => {
          'question': q.question,
          'section': q.section,
          'grade': q.grade,
        }).toList(),
      })}');

      final response = await http.post(
        Uri.parse('$baseUrl/audit-sheets'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'name': auditSheet.name,
          'zoneId': zoneId,
          'orgId': auditSheet.orgId,
          'month': auditSheet.month,
          'questions': auditSheet.questions.map((q) => {
            'question': q.question,
            'section': q.section,
            'grade': q.grade,
          }).toList(),
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        
        // Check if response has data array
        if (json['data'] == null || (json['data'] as List).isEmpty) {
          throw Exception('Invalid response: No data received');
        }

        // Get the first item from data array
        final data = (json['data'] as List).first;
        
        // Validate required fields
        if (data['name'] == null || data['zoneId'] == null || data['orgId'] == null || data['createdAt'] == null) {
          throw Exception('Invalid response: Missing required fields');
        }

        // Parse questions with null checks
        List<AuditQuestion> questions = [];
        if (data['questions'] != null) {
          questions = (data['questions'] as List).map((q) {
            if (q['question'] == null || q['section'] == null) {
              throw Exception('Invalid question data: Missing required fields');
            }
            return AuditQuestion(
              id: q['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: q['question'],
              section: q['section'],
              grade: (q['grade'] as num?)?.toDouble() ?? 0.0,
              answer: q['answer'],
            );
          }).toList();
        }

        return AuditSheet(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name'],
          zoneId: data['zoneId'],
          orgId: data['orgId'],
          createdAt: DateTime.parse(data['createdAt']),
          questions: questions,
            month: data['month']
        );
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to create audit sheet: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Error creating audit sheet: $e');
    }
  }

  Future<List<AuditSheet>> getAuditSheets(String orgId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-sheets?orgId=$orgId'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Check if response has data array
        if (json['data'] == null) {
          throw Exception('Invalid response: No data received');
        }

        // Parse the list of audit sheets
        final List<dynamic> data = json['data'];
        return data.map((item) {
          // Validate required fields
          if (item['name'] == null || item['zoneId'] == null || item['orgId'] == null || item['createdAt'] == null) {
            throw Exception('Invalid response: Missing required fields');
          }

          // Parse questions with null checks
          List<AuditQuestion> questions = [];
          if (item['questions'] != null) {
            questions = (item['questions'] as List).map((q) {
              if (q['question'] == null || q['section'] == null) {
                throw Exception('Invalid question data: Missing required fields');
              }
              return AuditQuestion(
                id: q['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                question: q['question'],
                section: q['section'],
                grade: (q['grade'] as num?)?.toDouble() ?? 0.0,
                answer: q['answer'],
              );
            }).toList();
          }

          return AuditSheet(
            id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: item['name'],
            zoneId: item['zoneId'],
            orgId: item['orgId'],
            createdAt: DateTime.parse(item['createdAt']),
            questions: questions,
            month: item['month']
          );
        }).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to fetch audit sheets: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Error fetching audit sheets: $e');
    }
  }

  Future<void> deleteAuditSheet(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/audit-sheets/$id'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to delete audit sheet: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Error deleting audit sheet: $e');
    }
  }

  Future<AuditSheet> updateAuditSheet(AuditSheet auditSheet) async {
    try {
      print('Updating audit sheet with data: ${jsonEncode({
        'name': auditSheet.name,
        'month': auditSheet.month,
        'questions': auditSheet.questions.map((q) => {
          'question': q.question,
          'section': q.section,
          'grade': q.grade,
        }).toList(),
      })}');

      final response = await http.put(
        Uri.parse('$baseUrl/audit-sheets/${auditSheet.id}'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'name': auditSheet.name,
          'month': auditSheet.month,
          'questions': auditSheet.questions.map((q) => {
            'question': q.question,
            'section': q.section,
            'grade': q.grade,
          }).toList(),
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Check if response has data array
        if (json['data'] == null || (json['data'] as List).isEmpty) {
          throw Exception('Invalid response: No data received');
        }

        // Get the first item from data array
        final data = (json['data'] as List).first;
        
        // Validate required fields
        if (data['name'] == null || data['zoneId'] == null || data['orgId'] == null || data['createdAt'] == null) {
          throw Exception('Invalid response: Missing required fields');
        }

        // Parse questions with null checks
        List<AuditQuestion> questions = [];
        if (data['questions'] != null) {
          questions = (data['questions'] as List).map((q) {
            if (q['question'] == null || q['section'] == null) {
              throw Exception('Invalid question data: Missing required fields');
            }
            return AuditQuestion(
              id: q['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: q['question'],
              section: q['section'],
              grade: (q['grade'] as num?)?.toDouble() ?? 0.0,
              answer: q['answer'],
            );
          }).toList();
        }

        return AuditSheet(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name'],
          zoneId: data['zoneId'],
          orgId: data['orgId'],
          createdAt: DateTime.parse(data['createdAt']),
          questions: questions,
            month: data['month']
        );
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to update audit sheet: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Error updating audit sheet: $e');
    }
  }
} 