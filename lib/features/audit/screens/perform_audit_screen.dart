import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../models/audit_sheet.dart';
import '../models/audit_response.dart';
import '../models/audit_submission.dart';
import '../../../providers/audit_sheet_provider.dart';
import '../../../services/audit_sheet_service.dart';


class PerformAuditScreen extends ConsumerStatefulWidget {
  final AuditSheet sheet;
  
  const PerformAuditScreen({
    super.key,
    required this.sheet,
  });

  @override
  ConsumerState<PerformAuditScreen> createState() => _PerformAuditScreenState();
}

class _PerformAuditScreenState extends ConsumerState<PerformAuditScreen> {
  final List<AuditQuestion> _questions = [];
  final Map<String, String> _remarks = {};
  final Map<String, List<Photos>> _photos = {};
  bool _isAuditComplete = false;
  double _totalScore = 0;
  double _percentageScore = 0;
  bool _isLoading = true;
  bool _hasSubmissions = false;
  AuditSubmission? _latestSubmission;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
  }

  Future<void> _initializeQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load questions from the audit sheet and ensure unique IDs
      _questions.addAll(widget.sheet.questions.map((q) => AuditQuestion(
        questionId: '${q.questionId}_${DateTime.now().millisecondsSinceEpoch}_${_questions.length}',
        question: q.question,
      )));

      // Check for existing submissions
      final submissions = await ref.read(auditSheetSubmissionsProvider(widget.sheet.id).future);
      
      if (submissions.isNotEmpty) {
        setState(() {
          _hasSubmissions = true;
          _latestSubmission = submissions.first;  // Set the latest submission
          
          // Pre-fill data from the latest submission
          for (var response in _latestSubmission!.responses!) {
            final question = _questions.firstWhere(
              (q) => q.questionId.split('_')[0] == response.questionId,
              orElse: () => _questions.first,
            );
            
            // Set the score
            question.score = response.score!.toDouble();
            
            // Set the remarks
            if (response.remarks!.isNotEmpty) {
              _remarks[question.questionId] = response.remarks!;
            }
            
            // Set the photos
            if (response.photos!.isNotEmpty) {
              _photos[question.questionId] = response.photos!;
            }
          }
          
          // Calculate total score and percentage
          _calculateTotalScore();
          
          // Set audit as complete since we're viewing a submission
          _isAuditComplete = true;
        });
      }
    } catch (e) {
      print('Error initializing questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading submission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPhoto(String questionId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );
      
      // if (image != null && mounted) {
      //   setState(() {
      //     if (!_photos.containsKey(questionId)) {
      //       _photos[questionId] = [];
      //     }
      //     _photos[questionId]!.add(image.path!.toString());
      //   });
      //
      //   // Print debug information
      //   print('Photo added for question $questionId: ${image.path}');
      //   print('Current photos for question: ${_photos[questionId]}');
      // }
    } catch (e) {
      print('Error adding photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateScore(String questionId, double score) {
    setState(() {
      final questionIndex = _questions.indexWhere((q) => q.questionId == questionId);
      if (questionIndex != -1) {
        // Update the score for the question
        _questions[questionIndex].score = score;
        
        // Recalculate total score
        _calculateTotalScore();
        
        // Print debug information
        print('Updated score for question ${questionId}: $score');
        print('All question scores:');
        for (var q in _questions) {
          print('Question ${q.questionId}: ${q.score}');
        }
        print('Current total score: $_totalScore');
        print('Number of questions: ${_questions.length}');
      }
    });
  }

  void _updateRemarks(String questionId, String remark) {
    setState(() {
      _remarks[questionId] = remark;
    });
  }

  void _calculateTotalScore() {
    // Calculate total score by summing up all question scores
    _totalScore = _questions.fold(0.0, (sum, question) => sum + question.score);
    
    // Calculate maximum possible score
    final maxPossibleScore = _questions.length * widget.sheet.maxScore;
    
    // Calculate percentage based on actual maximum score
    _percentageScore = (_totalScore / maxPossibleScore) * 100;
    
    // Print debug information
    print('Final total score: $_totalScore');
    print('Maximum possible score: $maxPossibleScore');
    print('Percentage: $_percentageScore%');
  }

  String _getBase64Image(File imageFile) {
    List<int> imageBytes = imageFile.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);
    return 'data:image/jpeg;base64,$base64Image';
  }

  Future<void> _completeAudit() async {
    try {
      setState(() {
        _isAuditComplete = true;
        _calculateTotalScore();
      });

      // Get user ID from secure storage
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: 'userId') ?? '';
      
      if (userId.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      // Prepare responses
      final responses = _questions.map((question) {
        final questionPhotos = _photos[question.questionId] ?? [];
        return {
          'questionId': question.questionId.split('_')[0],
          'score': question.score.toInt(),
          'remarks': _remarks[question.questionId] ?? '',
          'photos': questionPhotos.map((photoPath) {
            final file = File(photoPath.url.toString());
            return {
              'file': _getBase64Image(file),
              'description': 'Photo for ${question.question}',
            };
          }).toList(),
        };
      }).toList();

      // Prepare request body
      final requestBody = {
        'submittedBy': userId,
        'responses': responses,
      };

      // Print request body for debugging
      print('Submitting audit with request body:');
      print(jsonEncode(requestBody));

      const String baseUrl = 'http://localhost:8081';
      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/audit-sheets/${widget.sheet.id}/submit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Print response for debugging
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseBody = json.decode(response.body);
      
      // Check both status code and response message
      if ((response.statusCode == 200 || response.statusCode == 201) && (responseBody['statusCode'] == 200 || responseBody['statusCode'] == 201)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit submitted successfully!')),
          );
          // Navigate to statistics screen
          context.push('/audit-statistics/${widget.sheet.zoneId}/${DateTime.now().year}');
        }
      } else {
        // Show error message from the server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseBody['error'] ?? 'Failed to submit audit'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isAuditComplete = false;
          });
        }
      }
    } catch (e) {
      print('Error submitting audit: $e');
      setState(() {
        _isAuditComplete = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting audit: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _hasSubmissions ? 'View Audit Submission' : 'Perform Audit',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isAuditComplete && !_hasSubmissions)
            TextButton.icon(
              onPressed: _completeAudit,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Complete Audit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasSubmissions) ...[
                _buildSubmissionInfo(),
                const SizedBox(height: 24),
              ],
              ..._questions.map((question) => _buildQuestionCard(question)).toList(),
              const SizedBox(height: 24),
              if (!_hasSubmissions) ...[
                _buildScoreCard(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isAuditComplete ? _completeAudit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Audit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionInfo() {
    if (_latestSubmission == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Submission',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Submitted on: ${_formatDate(DateTime.parse(_latestSubmission!.submittedAt ?? DateTime.now().toIso8601String()))}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.score, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Score: ${_latestSubmission!.totalScore ?? 0}/${widget.sheet.maxScore} (${_latestSubmission!.percentage ?? "0"}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // if (_latestSubmission!.submittedBy != null) ...[
          //   const SizedBox(height: 4),
          //   Row(
          //     children: [
          //       Icon(Icons.person, size: 16, color: AppColors.textSecondary),
          //       const SizedBox(width: 8),
          //       Text(
          //         'Submitted by: ${_latestSubmission!.submittedBy}',
          //         style: TextStyle(
          //           fontSize: 14,
          //           color: AppColors.textSecondary,
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AuditQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: question.score,  // Set the pre-filled score
                  decoration: const InputDecoration(
                    labelText: 'Score',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(widget.sheet.maxScore + 1, (index) => index.toDouble()).map((score) {
                    return DropdownMenuItem(
                      value: score,
                      child: Text(score.toString()),
                    );
                  }).toList(),
                  onChanged: (_isAuditComplete || _hasSubmissions)
                      ? null
                      : (value) {
                          if (value != null) {
                            _updateScore(question.questionId, value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: (_isAuditComplete || _hasSubmissions)
                    ? null
                    : () => _addPhoto(question.questionId),
                icon: const Icon(Icons.photo_library),
                tooltip: 'Add Photo from Gallery',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: !_isAuditComplete && !_hasSubmissions,
            controller: TextEditingController(text: _remarks[question.questionId] ?? ''),  // Set pre-filled remarks
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => _updateRemarks(question.questionId, value),
          ),
          if (_photos.containsKey(question.questionId) && _photos[question.questionId]!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Attached Photos:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos[question.questionId]!.length,
                itemBuilder: (context, index) {
                  final photo = _photos[question.questionId]![index];
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photo.url.toString(),
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return _buildErrorContainer();
                            },
                          ),
                        ),
                      ),
                      if (!_isAuditComplete && !_hasSubmissions)
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photos[question.questionId]!.removeAt(index);
                                if (_photos[question.questionId]!.isEmpty) {
                                  _photos.remove(question.questionId);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      height: 100,
      width: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.error),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Score: ${_totalScore.toStringAsFixed(1)}/${_questions.length * 2} (${_percentageScore.toStringAsFixed(1)}%)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Answer each question and provide evidence',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 