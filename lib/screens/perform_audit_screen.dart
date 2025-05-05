import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../models/audit.dart';
import '../data/default_audit_questions.dart';

class PerformAuditScreen extends StatelessWidget {
  const PerformAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate dummy audit sheets from default questions
    final sheets = [
      AuditSheet(
        id: 'sheet1',
        name: 'Zone A Audit',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        questions: defaultAuditQuestions,
      ),
      AuditSheet(
        id: 'sheet2',
        name: 'Zone B Audit',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        questions: defaultAuditQuestions,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perform Audit'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildSheetList(context, sheets)),
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
        children: const [
          Text(
            'Audit Sheets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a sheet to perform audit',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetList(BuildContext context, List<AuditSheet> sheets) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sheets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final sheet = sheets[index];
        return InkWell(
          onTap: () => context.push('/perform-audit/${sheet.id}', extra: sheet),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                sheet.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Created: ${sheet.createdAt.day}/${sheet.createdAt.month}/${sheet.createdAt.year}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            ),
          ),
        );
      },
    );
  }
} 