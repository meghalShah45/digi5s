import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/audit/models/audit_sheet.dart';
import '../../../providers/audit_sheet_provider.dart';
import '../../../providers/zone_provider.dart';
import '../../../theme/colors.dart';
import 'add_questions_page.dart';

class AuditEditorScreen extends ConsumerStatefulWidget {
  final AuditSheet? auditSheet;

  const AuditEditorScreen({
    Key? key,
    this.auditSheet,
  }) : super(key: key);

  @override
  ConsumerState<AuditEditorScreen> createState() => _AuditEditorScreenState();
}

class _AuditEditorScreenState extends ConsumerState<AuditEditorScreen> {
  final List<AuditQuestion> savedQuestions = [];
  String? selectedZone;
  DateTime? selectedDate;
  String? selectedMonth;
  int? selectedYear;
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
    if (widget.auditSheet != null) {
      // Initialize with existing audit sheet data
      nameController.text = widget.auditSheet!.name;
      selectedZone = widget.auditSheet!.zoneId;
      selectedDate = widget.auditSheet!.createdAt;
      selectedMonth = widget.auditSheet!.month;
      selectedYear = widget.auditSheet!.createdAt.year;
      savedQuestions.addAll(widget.auditSheet!.questions);
      maxScoreController.text = widget.auditSheet!.maxScore.toString();
    } else {
      selectedYear = DateTime.now().year;
      selectedMonth = months[DateTime.now().month - 1];
      maxScoreController.text = '0'; // Default max score
    }
    Future.microtask(() => ref.read(zoneListProvider.notifier).fetchZones());
  }

  @override
  void dispose() {
    nameController.dispose();
    maxScoreController.dispose();
    super.dispose();
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

    if (savedQuestions.isEmpty) {
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

    int maxScore;
    try {
      maxScore = int.parse(maxScoreController.text);
      if (maxScore <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max score must be greater than 0')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid max score')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      
      print('Saving audit sheet with name: ${nameController.text}'); // Debug log
      
      final monthIndex = months.indexOf(selectedMonth!);
      final auditSheet = AuditSheet(
        id: widget.auditSheet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        zoneId: selectedZone!,
        orgId: orgId,
        createdAt: DateTime(selectedYear!, monthIndex + 1, 1),
        questions: savedQuestions,
        month: selectedMonth!,
        maxScore: maxScore,
        totalQuestions: savedQuestions.length
      );

      if (widget.auditSheet == null) {
        // Create new audit sheet
        await ref.read(createAuditSheetProvider(
          CreateAuditSheetParams(
            auditSheet: auditSheet,
            zoneId: selectedZone!,
          ),
        ).future);
      } else {
        // Update existing audit sheet
        await ref.read(updateAuditSheetProvider(auditSheet).future);
      }

      if (mounted) {
        Navigator.pop(context, auditSheet);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving audit sheet: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.auditSheet == null ? 'Create Audit Sheet' : 'Edit Audit Sheet',
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                        data: (zones) => zones?.map((zone) => DropdownMenuItem<String>(
                          value: zone.id,
                          child: Text(zone.name),
                        )).toList() ?? [],
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
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: selectedDate != null 
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Select Date',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Audit Month',
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
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                        ),
                      ),
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
                            items: months.map((month) => DropdownMenuItem<String>(
                              value: month,
                              child: Text(month),
                            )).toList(),
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
                            items: years.map((year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                              });
                            },
                          ),
                        ),
                      ],
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddQuestionsPage(
                        savedQuestions: savedQuestions,
                        onAddQuestion: (AuditQuestion question) {
                          setState(() {
                            savedQuestions.add(question);
                          });
                        },
                        month: selectedMonth!,
                        sheetName: nameController.text.trim(),
                        zoneName: ref.watch(zoneListProvider).when(
                          data: (zones) => zones?.firstWhere(
                            (zone) => zone.id == selectedZone,
                          )?.name,
                          loading: () => null,
                          error: (_, __) => null,
                        ),
                        zoneId: selectedZone,
                        isEditing: widget.auditSheet != null,
                      ),
                    ),
                  );
                  if (result != null && result is List<AuditQuestion>) {
                    setState(() {
                      savedQuestions.clear();
                      savedQuestions.addAll(result);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  savedQuestions.isEmpty ? 'Add Questions' : 'Edit Questions (${savedQuestions.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                      : Text(
                          widget.auditSheet == null ? 'Create Audit Sheet' : 'Save Changes',
                          style: const TextStyle(
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
} 