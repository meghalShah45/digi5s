import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/audit/models/audit_sheet.dart';
import '../../../providers/audit_sheet_provider.dart';
import '../../../providers/zone_provider.dart';
import '../../../theme/colors.dart';
import 'add_questions_page.dart';

class CreateAuditSheetPage extends ConsumerStatefulWidget {
  const CreateAuditSheetPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateAuditSheetPage> createState() => _CreateAuditSheetPageState();
}

class _CreateAuditSheetPageState extends ConsumerState<CreateAuditSheetPage> {
  String? selectedZone;
  DateTime? selectedDate;
  String? selectedMonth;
  int? selectedYear;
  final List<AuditQuestion> questions = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController maxScoreController = TextEditingController();
  bool isLoading = false;

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - 2 + index);
  }

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
    selectedMonth = months[DateTime.now().month - 1];
    maxScoreController.text = '0';
    Future.microtask(() => ref.read(zoneListProvider.notifier).fetchZones());
  }

  @override
  void dispose() {
    nameController.dispose();
    maxScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Create Audit Sheet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Audit Sheet Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Score per Question',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Zone Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                value: selectedZone,
                items: ref.watch(zoneListProvider).when(
                  data: (zones) => zones?.map((zone) {
                    return DropdownMenuItem(
                      value: zone.id,
                      child: Text(zone.name),
                    );
                  }).toList() ?? [],
                  loading: () => [],
                  error: (_, __) => [],
                ),
                onChanged: (value) {
                  setState(() {
                    selectedZone = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Month',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      value: selectedMonth,
                      items: months.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Year',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      value: selectedYear,
                      items: years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an audit sheet name')),
                    );
                    return;
                  }
                  if (selectedZone == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a zone')),
                    );
                    return;
                  }
                  if (selectedMonth == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a month')),
                    );
                    return;
                  }
                  if (selectedYear == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a year')),
                    );
                    return;
                  }

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddQuestionsPage(
                        savedQuestions: questions,
                        onAddQuestion: (AuditQuestion question) {
                          setState(() {
                            questions.add(question);
                          });
                        },
                        month: selectedMonth!,
                        sheetName: nameController.text.trim(),
                        zoneId: selectedZone,
                        zoneName: ref.watch(zoneListProvider).when(
                          data: (zones) {
                            if (zones == null) return null;
                            final zone = zones.firstWhere(
                              (zone) => zone.id == selectedZone,

                            );
                            return zone?.name;
                          },
                          loading: () => null,
                          error: (_, __) => null,
                        ),
                      ),
                    ),
                  );

                  if (result != null) {
                    if (result is AuditSheet) {
                      // If we got back an AuditSheet, save it and return
                      try {
                        setState(() => isLoading = true);
                        await ref.read(createAuditSheetProvider(
                          CreateAuditSheetParams(
                            auditSheet: result,
                            zoneId: selectedZone!,
                          ),
                        ).future);
                        if (mounted) {
                          Navigator.pop(context, result);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating audit sheet: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    } else if (result is List<AuditQuestion>) {
                      // If we got back a list of questions, update our questions
                      setState(() {
                        questions.clear();
                        questions.addAll(result);
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      questions.isEmpty ? 'Add Questions' : 'Edit Questions (${questions.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveAuditSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: AppColors.secondaryLight)
                      : const Text(
                          'Create Audit Sheet',
                          style: TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAuditSheet() async {
    if (selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a zone')),
      );
      return;
    }

    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the audit sheet')),
      );
      return;
    }

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    if (selectedMonth == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both month and year')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      
      final maxScore = int.tryParse(maxScoreController.text) ?? 3;
      
      final auditSheet = AuditSheet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        zoneId: selectedZone!,
        orgId: orgId,
        createdAt: DateTime.now(),
        questions: questions.map((q) => AuditQuestion(
          questionId: q.questionId,
          question: q.question,
        )).toList(),
        month: selectedMonth!,
        totalQuestions: questions.length,
        maxScore: maxScore,
      );

      final result = await ref.read(createAuditSheetProvider(
        CreateAuditSheetParams(
          auditSheet: auditSheet,
          zoneId: selectedZone!,
        ),
      ).future);

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating audit sheet: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
} 