import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../models/audit.dart';

class PerformAuditDetailScreen extends StatefulWidget {
  final AuditSheet sheet;
  const PerformAuditDetailScreen({super.key, required this.sheet});

  @override
  State<PerformAuditDetailScreen> createState() => _PerformAuditDetailScreenState();
}

class _PerformAuditDetailScreenState extends State<PerformAuditDetailScreen> {
  late List<AuditQuestion> questions;
  final Map<String, double> grades = {};
  final Map<String, String> remarks = {};
  final Map<String, String?> photos = {};

  @override
  void initState() {
    super.initState();
    // Initialize grades with existing values
    questions = widget.sheet.questions;
    for (var q in questions) {
      grades[q.id] = q.grade;
      remarks[q.id] = q.answer ?? '';
      photos[q.id] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.sheet.name),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final currentGrade = grades[q.id] ?? 0.0;
          final currentRemark = remarks[q.id]!;
          final photoPath = photos[q.id];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Score:', style: TextStyle(color: AppColors.textPrimary)),
                    const SizedBox(width: 12),
                    for (var score in [0, 1, 2]) ...[
                      Row(
                        children: [
                          Radio<int>(
                            value: score,
                            groupValue: currentGrade.toInt(),
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                grades[q.id] = value?.toDouble() ?? 0.0;
                              });
                            },
                          ),
                          Text('$score'),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: currentRemark),
                  decoration: InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  maxLines: 2,
                  onChanged: (value) => remarks[q.id] = value,
                ),
                const SizedBox(height: 12),
                const Text('Attach Photo', style: TextStyle(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    // TODO: implement photo picker and set photos[q.id]
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondaryDark),
                    ),
                    child: photoPath == null
                        ? Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: AppColors.secondaryDark,
                            ),
                          )
                        : Image.file(File(photoPath), fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              // TODO: submit audit grades, remarks, and photos
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Submit Audit',
              style: TextStyle(color: AppColors.secondaryLight, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
} 