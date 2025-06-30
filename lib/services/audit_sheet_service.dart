import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../features/audit/models/audit_response.dart';
import '../features/audit/models/audit_sheet.dart';
import '../features/audit/models/audit_submission.dart';

class AuditSheetService {
  static const String baseUrl = 'http://localhost:8081';

  Future<AuditSheet> createAuditSheet(AuditSheet auditSheet) async {
    try {
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'userId') ?? '';
      print('Creating audit sheet with data: ${jsonEncode({
        'name': auditSheet.name,
        'orgId': auditSheet.orgId,
        'month': auditSheet.month,
        'maxScore': auditSheet.maxScore,
        'totalQuestions': auditSheet.questions.length,
        "userId": userId,
        'questions': auditSheet.questions.map((q) => {
          'questionId': q.questionId,
          'question': q.question,
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
          'orgId': auditSheet.orgId,
          'month': auditSheet.month,
          'maxScore': auditSheet.maxScore,
          'totalQuestions': auditSheet.questions.length,
          "userId": userId,
          'questions': auditSheet.questions.map((q) => {
            'questionId': q.questionId,
            'question': q.question,
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
        if (data['name'] == null || data['orgId'] == null || data['createdAt'] == null) {
          throw Exception('Invalid response: Missing required fields');
        }

        // Parse questions with null checks
        List<AuditQuestion> questions = [];
        if (data['questions'] != null) {
          questions = (data['questions'] as List).map((q) {
            if (q['question'] == null) {
              throw Exception('Invalid question data: Missing required fields');
            }
            return AuditQuestion(
              questionId: q['questionId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: q['question'],
            );
          }).toList();
        }

        return AuditSheet(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name'],
          orgId: data['orgId'],
          createdAt: DateTime.parse(data['createdAt']),
          questions: questions,
          month: data['month'],
          maxScore: data['maxScore'] as int? ?? 0, totalQuestions: questions.length,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        // Check for specific error case
        if (response.statusCode == 403 && 
            errorBody['error'] == 'Only zone leaders can create audit sheets') {
          throw Exception('Only zone leaders can create audit sheets');
        }
        throw Exception('Failed to create audit sheet: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      // Re-throw the specific error message if it's our custom error
      if (e.toString().contains('Only zone leaders can create audit sheets')) {
        rethrow;
      }
      throw Exception('Error creating audit sheet: $e');
    }
  }

  Future<List<AuditSheet>> getAuditSheets(String orgId) async {
    try {
      print('Fetching audit sheets for orgId: $orgId');
      final queryParams = {
        'orgId': orgId
      };
      final uri = Uri.parse('$baseUrl/audit-sheets').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Decoded JSON: $json');
        
        // Check if response has data array
        if (json['data'] == null) {
          print('No data array in response');
          throw Exception('Invalid response: No data received');
        }

        // Parse the list of audit sheets
        final List<dynamic> data = json['data'];
        print('Number of audit sheets: ${data.length}');
        
        return data.map((item) {
          print('Processing audit sheet: $item');

          if (item['name'] == null || item['orgId'] == null || item['createdAt'] == null) {
            print('Missing required fields in audit sheet: $item');
            throw Exception('Invalid response: Missing required fields');
          }

          List<AuditQuestion> questions = [];
          if (item['questions'] != null) {
            print('Questions array: ${item['questions']}');
            questions = (item['questions'] as List).map((q) {
              print('Processing question: $q');
              print('Question type: ${q.runtimeType}');
              print('Question keys: ${q.keys.toList()}');

              String questionText;
              String questionId;
              
              if (q is String) {
                questionText = q;
                questionId = DateTime.now().millisecondsSinceEpoch.toString();
              } else if (q is Map) {
                questionText = q['question'] as String? ?? '';
                questionId = q['questionId'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
              } else {
                print('Unexpected question format: $q');
                throw Exception('Invalid question format: Expected String or Map');
              }
              
              if (questionText.isEmpty) {
                print('Invalid question data: Empty question text');
                throw Exception('Invalid question data: Empty question text');
              }
              
              return AuditQuestion(
                questionId: questionId,
                question: questionText,
              );
            }).toList();
          } else {
            print('No questions array found in item: $item');
          }

          final auditSheet = AuditSheet(
            id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: item['name'],
            orgId: item['orgId'],
            createdAt: DateTime.parse(item['createdAt']),
            questions: questions,
            month: item['month'],
            maxScore: item['maxScore'] as int? ?? 0, totalQuestions: questions.length,
          );
          
          print('Created audit sheet: ${auditSheet.toJson()}');
          return auditSheet;
        }).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        print('Error response: $errorBody');
        throw Exception('Failed to fetch audit sheets: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in getAuditSheets: $e');
      print('Stack trace: $stackTrace');
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
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'userId') ?? '';
      print('Updating audit sheet with data: ${jsonEncode({
        'name': auditSheet.name,
        'orgId': auditSheet.orgId,
        'month': auditSheet.month,
        'maxScore': auditSheet.maxScore,
        'totalQuestions': auditSheet.questions.length,
        'userId': userId,
        'questions': auditSheet.questions.map((q) => {
          'questionId': q.questionId,
          'question': q.question,
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
          'orgId': auditSheet.orgId,
          'month': auditSheet.month,
          'maxScore': auditSheet.maxScore,
          'totalQuestions': auditSheet.questions.length,
          'userId': userId,
          'questions': auditSheet.questions.map((q) => {
            'questionId': q.questionId,
            'question': q.question,
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
        if (data['name'] == null || data['orgId'] == null || data['createdAt'] == null) {
          throw Exception('Invalid response: Missing required fields');
        }

        // Parse questions with null checks
        List<AuditQuestion> questions = [];
        if (data['questions'] != null) {
          questions = (data['questions'] as List).map((q) {
            if (q['question'] == null) {
              throw Exception('Invalid question data: Missing required fields');
            }
            return AuditQuestion(
              questionId: q['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: q['question'],
            );
          }).toList();
        }

        return AuditSheet(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name'],
          orgId: data['orgId'],
          createdAt: DateTime.parse(data['createdAt']),
          questions: questions,
          month: data['month'],
          maxScore: data['maxScore'] as int? ?? 0, totalQuestions: questions.length,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        // Check for specific error case
        if (response.statusCode == 400 && 
            errorBody['error'] == 'This audit sheet has existing submissions and cannot be modified') {
          throw Exception('Cannot update this audit sheet because it has existing submissions. Please create a new audit sheet instead.');
        }
        throw Exception('Failed to update audit sheet: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      // Re-throw the specific error message if it's our custom error
      if (e.toString().contains('Cannot update this audit sheet because it has existing submissions')) {
        rethrow;
      }
      throw Exception('Error updating audit sheet: $e');
    }
  }

  Future<List<AuditSubmission>> getAuditSheetSubmissions(String auditSheetId) async {
    try {
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'userId') ?? '';
      print('Fetching submissions for audit sheet: $auditSheetId');
      final response = await http.get(
        Uri.parse('$baseUrl/audit-sheets/$auditSheetId/submissions'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Decoded response data: $responseData');

        // Check if response has data and submissions
        if (responseData['data'] == null || responseData['data']['submissions'] == null) {
          print('No submissions found in response');
          return [];
        }

        // Get the submissions list
        final List<dynamic> submissions = responseData['data']['submissions'];
        print('Number of submissions: ${submissions.length}');

        // Map each submission to AuditSubmission object
        return submissions.map((submission) {
          print('Processing submission: $submission');
          return AuditSubmission.fromJson(submission);
        }).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        print('Error response: $errorBody');
        throw Exception('Failed to fetch audit submissions: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in getAuditSheetSubmissions: $e');
      print('Stack trace: $stackTrace');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Error fetching audit submissions: $e');
    }
  }

  Future<void> submitAudit(String auditSheetId, List<AuditResponse> responses) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/audit-sheets/$auditSheetId/submit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'responses': responses.map((r) => r.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit audit: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting audit: $e');
    }
  }
}