import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/colors.dart';
import '../data/default_audit_questions.dart';
import '../models/audit_sheet.dart';

class PerformAuditScreen extends StatefulWidget {
  final AuditSheet sheet;
  
  const PerformAuditScreen({
    super.key,
    required this.sheet,
  });

  @override
  State<PerformAuditScreen> createState() => _PerformAuditScreenState();
}

class _PerformAuditScreenState extends State<PerformAuditScreen> {
  final List<AuditQuestion> _questions = [];
  final Map<String, String> _remarks = {};
  final Map<String, List<String>> _photos = {};
  bool _isAuditComplete = false;
  double _totalScore = 0;

  @override
  void initState() {
    super.initState();
    // Load questions from default audit questions
    _questions.addAll(defaultAuditQuestions);
  }

  Future<void> _addPhoto(String questionId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _photos[questionId] = [...(_photos[questionId] ?? []), image.path];
      });
    }
  }

  void _updateScore(String questionId, double score) {
    setState(() {
      final questionIndex = _questions.indexWhere((q) => q.id == questionId);
      if (questionIndex != -1) {
        _questions[questionIndex] = AuditQuestion(
          id: _questions[questionIndex].id,
          question: _questions[questionIndex].question,
          section: _questions[questionIndex].section,
          grade: score,
          answer: _questions[questionIndex].answer,
        );
        _calculateTotalScore();
      }
    });
  }

  void _updateRemarks(String questionId, String remark) {
    setState(() {
      _remarks[questionId] = remark;
    });
  }

  void _calculateTotalScore() {
    _totalScore = _questions.fold(0, (sum, question) => sum + question.grade);
  }

  void _completeAudit() {
    setState(() {
      _isAuditComplete = true;
      _calculateTotalScore();
    });
    // TODO: Implement API call to save audit results
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit completed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.sheet.name),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (!_isAuditComplete)
            TextButton.icon(
              onPressed: _completeAudit,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Complete Audit'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _buildQuestionCard(question);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
            widget.sheet.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAuditComplete
                ? 'Total Score: ${_totalScore.toStringAsFixed(1)}'
                : 'Answer each question and provide evidence',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AuditQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    value: question.grade,
                    decoration: const InputDecoration(
                      labelText: 'Score',
                      border: OutlineInputBorder(),
                    ),
                    items: [0.0, 1.0, 2.0].map((score) {
                      return DropdownMenuItem(
                        value: score,
                        child: Text(score.toString()),
                      );
                    }).toList(),
                    onChanged: _isAuditComplete
                        ? null
                        : (value) {
                            if (value != null) {
                              _updateScore(question.id, value);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _isAuditComplete
                      ? null
                      : () => _addPhoto(question.id),
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Add Photo',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: !_isAuditComplete,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _updateRemarks(question.id, value),
            ),
            if (_photos[question.id]?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos[question.id]?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.network(
                        _photos[question.id]![index],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 