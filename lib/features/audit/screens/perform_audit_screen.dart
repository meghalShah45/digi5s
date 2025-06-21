import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/zone_service.dart';
import '../../../theme/colors.dart';
import '../models/audit_sheet.dart';
import '../models/audit_submission.dart';
import '../../../providers/audit_sheet_provider.dart';
import '../../../models/zone.dart';


class PerformAuditScreen extends ConsumerStatefulWidget {
  final AuditSheet sheet;
  final String? submissionId;  // Optional parameter to view specific submission
  
  PerformAuditScreen({
    super.key,
    required this.sheet,
    this.submissionId,
  });

  @override
  ConsumerState<PerformAuditScreen> createState() => _PerformAuditScreenState();
}

class _PerformAuditScreenState extends ConsumerState<PerformAuditScreen> {
  final List<AuditQuestion> _questions = [];
  final Map<String, String> _remarks = {};
  final Map<String, List<Photos>> _photos = {};
  final ZoneService _zoneService = ZoneService();
  bool _isAuditComplete = false;
  double _totalScore = 0;
  double _percentageScore = 0;
  bool _isLoading = true;
  bool _hasSubmissions = false;
  AuditSubmission? _latestSubmission;
  String? _currentUserId;
  bool _canPerformAudit = true;
  String? _userRole;
  List<AuditSubmission> _allSubmissions = [];
  DateTime _selectedDate = DateTime.now();
  Zone? _selectedZone;
  List<Zone> _zones = [];
  bool _isLoadingZones = true;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _loadZones();
  }

  Future<void> _initializeQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID and role
      const storage = FlutterSecureStorage();
      _currentUserId = await storage.read(key: 'userId');
      _userRole = await storage.read(key: 'userRole');

      // Load questions from the audit sheet and ensure unique IDs
      _questions.addAll(widget.sheet.questions.map((q) => AuditQuestion(
        questionId: '${q.questionId}_${DateTime.now().millisecondsSinceEpoch}_${_questions.length}',
        question: q.question,
        score: null,
      )));

      // Check for existing submissions
      final submissions = await ref.read(auditSheetSubmissionsProvider(widget.sheet.id).future);
      
      if (submissions.isNotEmpty) {
        setState(() {
          _hasSubmissions = true;
          _allSubmissions = submissions;

          // If submissionId is provided, find that specific submission
          if (widget.submissionId != null) {
            _latestSubmission = submissions.firstWhere(
              (submission) => submission.submissionId == widget.submissionId,
            );
            _canPerformAudit = false;
            _isAuditComplete = true;
          } else {
            _latestSubmission = submissions.first;

            // Set permissions based on user role
            if (_userRole == 'zone-admin' || _userRole == 'SUPER-ADMIN' || _userRole!.contains('ADMIN')) {
              _canPerformAudit = false;
              _isAuditComplete = true;
            } else if (_userRole.toString().toLowerCase() == 'zone-leader') {
              // Zone-leaders can perform multiple audits
              _canPerformAudit = true;
              _isAuditComplete = false;
              
              // If there are submissions, show the latest one for reference
              if (submissions.isNotEmpty) {
                _latestSubmission = submissions.first;
              }
            } else {
              _canPerformAudit = false;
              _isAuditComplete = true;
            }
          }
          
          // Pre-fill data from the submission only if user can't perform audit
          if (!_canPerformAudit && _latestSubmission != null) {
            for (var response in _latestSubmission!.responses!) {
              final question = _questions.firstWhere(
                (q) => q.questionId.split('_')[0] == response.questionId,
                orElse: () => _questions.first,
              );

              if(response.score != null)
                question.score = response.score;
              
              if (response.remarks != null && response.remarks!.isNotEmpty) {
                _remarks[question.questionId] = response.remarks!;
              }
              
              if (response.photos!.isNotEmpty) {
                _photos[question.questionId] = response.photos!;
              }
            }
            
            _calculateTotalScore();
          }
        });
      } else {
        // If no submissions and user is zone member, redirect back after 5 seconds
        if (_userRole?.toLowerCase() == 'zone-member') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No submissions available to view.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
            
            // Wait for 5 seconds then redirect back
            await Future.delayed(const Duration(seconds: 0));
            if (mounted) {
              context.pop();
            }
          }
        }
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

  Future<void> _loadZones() async {
    try {
      setState(() {
        _isLoadingZones = true;
      });

      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      
      if (orgId.isEmpty) {
        throw Exception('Organization ID not found');
      }

      final zones = await _zoneService.getZonesByOrgId(orgId);
      
      setState(() {
        _zones = zones;
        _isLoadingZones = false;
      });
    } catch (e) {
      print('Error loading zones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading zones: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingZones = false;
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
      
      if (image != null && mounted) {
        setState(() {
          if (!_photos.containsKey(questionId)) {
            _photos[questionId] = [];
          }
          _photos[questionId]!.add(Photos(url: image.path));
        });

        // Print debug information
        print('Photo added for question $questionId: ${image.path}');
        print('Current photos for question: ${_photos[questionId]}');
      }
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

  void _updateScore(String questionId, String? score) {
    setState(() {
      final questionIndex = _questions.indexWhere((q) => q.questionId == questionId);
      if (questionIndex != -1) {
        _questions[questionIndex].score = score;
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
    // Get only the questions that have actual scores (not null and not NA)
    final applicableQuestions = _questions.where((q) => q.score != null && q.score != 'NA').toList();
    
    // T = Total number of applicable questions (excluding NA and null)
    final totalApplicableQuestions = applicableQuestions.length;
    
    // Max Score per Question = 3
    final maxScorePerQuestion = widget.sheet.maxScore;
    
    // Total Possible Score = (Number of applicable questions) × maxScore
    final totalPossibleScore = totalApplicableQuestions * maxScorePerQuestion;
    
    // Actual Score = Sum of all applicable question scores
    _totalScore = applicableQuestions.fold(
      0.0,
      (sum, question) {
        return sum + int.parse(question.score.toString());
      },
    );
    
    // Audit Score % = (Actual Score / Total Possible Score) × 100
    _percentageScore = totalPossibleScore > 0 ? (_totalScore / totalPossibleScore) * 100 : 0;
    
    // Print debug information
    print('Total Questions: ${_questions.length}');
    print('NA Questions: ${_questions.where((q) => q.score == 'NA').length}');
    print('Unanswered Questions: ${_questions.where((q) => q.score == null).length}');
    print('Applicable Questions: $totalApplicableQuestions');
    print('Max Score per Question: $maxScorePerQuestion');
    print('Total Possible Score: $totalPossibleScore');
    print('Actual Score: $_totalScore');
    print('Audit Score %: $_percentageScore%');
  }

  String _getBase64Image(File imageFile) {
    List<int> imageBytes = imageFile.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);
    return 'data:image/jpeg;base64,$base64Image';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _completeAudit() async {
    try {
      if (_selectedZone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a zone'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isAuditComplete = true;
        _calculateTotalScore();
      });

      // Get user ID from secure storage
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: 'userId') ?? '';
      final userZone = await storage.read(key: 'zoneId') ?? '';

      if (userId.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      // Calculate NA and applicable questions
      final naQuestions = _questions.where((q) => q.score == 'NA').length;
      final applicableQuestions = _questions.where((q) => q.score != null && q.score != 'NA').length;

      // Prepare responses
      final responses = _questions.map((question) {
        return {
          'questionId': question.questionId.split('_')[0],
          'score': question.score == null ? 'NA' : question.score,
          'remarks': _remarks[question.questionId] ?? '',
          'photos': (_photos[question.questionId] ?? []).map((photoPath) {
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
        'userZone': userZone,
        'naQuestions': naQuestions,
        'applicableQuestions': applicableQuestions,
        'totalScore': _totalScore,
        'auditScorePercentage': _percentageScore,
        'auditDate': _selectedDate.toIso8601String(),
        'auditZone': _selectedZone!.id,
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
          context.push('/audit-statistics/${_selectedZone!.id}');
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
          _userRole == 'zone-admin' ? 'View All Submissions' : 
          _hasSubmissions && !_canPerformAudit ? 'View Audit Submission' : 'Perform Audit',
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
          if (!_isAuditComplete && _canPerformAudit)
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
              if (_userRole == 'zone-admin') ...[
                _buildAllSubmissionsList(),
              ] else if (_hasSubmissions && !_canPerformAudit) ...[
                _buildSubmissionInfo(),
                const SizedBox(height: 24),
              ],
              // if (!_canPerformAudit && _hasSubmissions && _userRole != 'zone-admin') ...[
              //   Container(
              //     padding: const EdgeInsets.all(16),
              //     decoration: BoxDecoration(
              //       color: Colors.red.withOpacity(0.1),
              //       borderRadius: BorderRadius.circular(12),
              //       border: Border.all(color: Colors.red),
              //     ),
              //     child: Row(
              //       children: [
              //         const Icon(Icons.warning, color: Colors.red),
              //         const SizedBox(width: 12),
              //         Expanded(
              //           child: Text(
              //             'You have already submitted an audit for this sheet. You cannot submit another one.',
              //             style: TextStyle(
              //               color: Colors.red[700],
              //               fontSize: 14,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              //   const SizedBox(height: 24),
              // ],
              if (_userRole != 'zone-admin') ...[
                if (_canPerformAudit) ...[
                  _buildAuditInfoCard(),
                  const SizedBox(height: 24),
                ],
                ..._questions.map((question) => _buildQuestionCard(question)).toList(),
                const SizedBox(height: 24),
                if (_canPerformAudit) ...[
                  _buildScoreCard(),
                  const SizedBox(height: 24),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllSubmissionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Submissions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._allSubmissions.map((submission) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              'Submitted by: ${submission.submittedBy}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Date: ${_formatDate(DateTime.parse(submission.submittedAt!))}\nScore: ${submission.totalScore}/${widget.sheet.maxScore} (${submission.percentage}%)',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...submission.responses!.map((response) {
                      // Find the original question from the audit sheet
                      final originalQuestion = widget.sheet.questions.firstWhere(
                        (q) => q.questionId == response.questionId,
                        orElse: () => widget.sheet.questions.first,
                      );
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originalQuestion.question,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Score: ${response.score}/${widget.sheet.maxScore}'),
                          if (response.remarks!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Remarks: ${response.remarks}'),
                          ],
                          if (response.photos!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Photos:'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: response.photos!.length,
                                itemBuilder: (context, index) {
                                  final photo = response.photos![index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photo.url.toString(),
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildErrorContainer();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
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
            'About this Submission',
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
                child: DropdownButtonFormField<String>(
                  value: (question.score == null || question.score == "") ? null : question.score,
                  decoration: const InputDecoration(
                    labelText: 'Score',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select Score'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'NA',
                      child: Text('NA'),
                    ),
                    ...List.generate(widget.sheet.maxScore + 1, (index) => index.toString()).map((score) {
                      return DropdownMenuItem<String>(
                        value: score,
                        child: Text(score),
                      );
                    }).toList(),
                  ],
                  onChanged: (!_canPerformAudit)
                      ? null
                      : (value) {
                          _updateScore(question.questionId, value);
                        },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: (!_canPerformAudit)
                    ? null
                    : () => _addPhoto(question.questionId),
                icon: const Icon(Icons.photo_library),
                tooltip: 'Add Photo from Gallery',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: _canPerformAudit,
            controller: TextEditingController(text: _remarks[question.questionId] ?? ''),
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
                          child: photo.url.toString().startsWith('http')
                              ? Image.network(
                                  photo.url.toString(),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading network image: $error');
                                    return _buildErrorContainer();
                                  },
                                )
                              : Image.file(
                                  File(photo.url.toString()),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading local image: $error');
                                    return _buildErrorContainer();
                                  },
                                ),
                        ),
                      ),
                      if (_canPerformAudit)
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error, color: Colors.red),
          SizedBox(height: 4),
          Text(
            'Failed to load image',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildScoreCard() {
    // Get only the questions that have actual scores (not null and not NA)
    final applicableQuestions = _questions.where((q) => q.score != null && q.score != 'NA').toList();
    final totalApplicableQuestions = applicableQuestions.length;
    final naQuestions = _questions.where((q) => q.score == 'NA').length;
    final unansweredQuestions = _questions.where((q) => q.score == null).length;
    final maxScorePerQuestion = widget.sheet.maxScore;
    final totalPossibleScore = totalApplicableQuestions * maxScorePerQuestion;
    
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Audit Score: ${_percentageScore.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actual Score: ${_totalScore.toStringAsFixed(1)}/$totalPossibleScore',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Applicable Questions: $totalApplicableQuestions/${_questions.length}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NA Questions: $naQuestions',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (unansweredQuestions > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Unanswered Questions: $unansweredQuestions',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.orange,
              ),
            ),
          ],
          // const SizedBox(height: 4),
          // Text(
          //   'Max Score per Question: $maxScorePerQuestion',
          //   style: const TextStyle(
          //         fontSize: 14,
          //         color: AppColors.textSecondary,
          //       ),
          // ),
        ],
      ),
    );
  }

  Widget _buildAuditInfoCard() {
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
          const Text(
            'Audit Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Audit Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoadingZones
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Zone>(
                        value: _selectedZone,
                        decoration: const InputDecoration(
                          labelText: 'Zone',
                          border: OutlineInputBorder(),
                        ),
                        items: _zones.map((Zone zone) {
                          return DropdownMenuItem<Zone>(
                            value: zone,
                            child: Text(zone.zoneName),
                          );
                        }).toList(),
                        onChanged: (Zone? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedZone = newValue;
                            });
                          }
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 