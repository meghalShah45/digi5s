import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../models/audit_sheet.dart';

class AuditSheetsListScreen extends StatelessWidget {
  const AuditSheetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual audit sheets from API
    final sheets = [
      AuditSheet(
        id: '1',
        name: 'Zone A - Monthly Audit',
        zoneId: 'zone_a',
        orgId: 'org_1',
        month: 'March 2024',
        createdAt: DateTime.now(),
        questions: [],
      ),
      AuditSheet(
        id: '2',
        name: 'Zone B - Monthly Audit',
        zoneId: 'zone_b',
        orgId: 'org_1',
        month: 'March 2024',
        createdAt: DateTime.now(),
        questions: [],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Available Audit Sheets'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sheets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final sheet = sheets[index];
                return _buildSheetCard(context, sheet);
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

  Widget _buildSheetCard(BuildContext context, AuditSheet sheet) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/perform-audit/${sheet.id}', extra: sheet),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Month: ${sheet.month}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${sheet.createdAt.day}/${sheet.createdAt.month}/${sheet.createdAt.year}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 