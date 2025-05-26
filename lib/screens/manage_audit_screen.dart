import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/audit_sheet.dart';
import '../providers/audit_sheet_provider.dart';
import '../providers/zone_provider.dart';
import '../theme/colors.dart';
import '../data/default_audit_questions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageAuditScreen extends ConsumerStatefulWidget {
  const ManageAuditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageAuditScreen> createState() => _ManageAuditScreenState();
}

class _ManageAuditScreenState extends ConsumerState<ManageAuditScreen> {
  String? selectedZone;
  String? orgId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeData());
  }

  Future<void> _initializeData() async {
    try {
      final storage = const FlutterSecureStorage();
      print('Attempting to read orgId from secure storage...'); // Debug log
      orgId = await storage.read(key: 'orgId');
      print('Retrieved orgId from storage: $orgId'); // Debug log
      
      // Check all stored values
      final allValues = await storage.readAll();
      print('All stored values: $allValues'); // Debug log
      
      if (orgId != null) {
        print('Organization ID found, fetching zones...'); // Debug log
        await ref.read(zoneListProvider.notifier).fetchZones();
      } else {
        print('Organization ID not found in secure storage'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in again to access this feature'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _initializeData: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
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
        title: const Text(
          'Manage Audit',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
          //   onPressed: () {
          //     // TODO: Implement filter functionality
          //   },
          // ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildAuditList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newAuditSheet = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _CreateAuditSheetPage(),
            ),
          );
          if (newAuditSheet != null) {
            ref.refresh(auditSheetsProvider(orgId!));
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.secondaryLight),
        label: const Text(
          'Create Audit',
          style: TextStyle(color: AppColors.secondaryLight),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Audit Sheets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final auditSheetsAsync = ref.watch(auditSheetsProvider(orgId ?? ''));
                  return auditSheetsAsync.when(
                    data: (sheets) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                        '${sheets.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                    ),
                    loading: () => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => const Text('0'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage and create audit sheets for different zones',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditList() {
    if (orgId == null) {
      return const Center(
        child: Text('Organization ID not found'),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final auditSheetsAsync = ref.watch(auditSheetsProvider(orgId!));
        
        return auditSheetsAsync.when(
          data: (auditSheets) {
    if (auditSheets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No audit sheets created yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first audit sheet to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: auditSheets.length,
      itemBuilder: (context, index) {
        final sheet = auditSheets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(sheet.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.question_answer,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sheet.questions.length} questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'edit') {
                  _editAuditSheet(sheet);
                } else if (value == 'delete') {
                  _deleteAuditSheet(sheet);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editAuditSheet(AuditSheet sheet) {
    _showAuditEditor(sheet);
  }

  void _showAuditEditor(AuditSheet? sheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AuditEditorScreen(auditSheet: sheet),
      ),
    ).then((_) {
      if (orgId != null) {
        ref.refresh(auditSheetsProvider(orgId!));
      }
    });
  }

  Future<void> _deleteAuditSheet(AuditSheet sheet) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audit Sheet'),
        content: Text('Are you sure you want to delete "${sheet.name}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(deleteAuditSheetProvider(sheet.id).future);
                if (orgId != null) {
                  ref.refresh(auditSheetsProvider(orgId!));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting audit sheet: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Define a reusable widget for question entry
class QuestionEntry extends StatelessWidget {
  final TextEditingController questionController;
  final VoidCallback onAttachPhoto;

  const QuestionEntry({
    Key? key,
    required this.questionController,
    required this.onAttachPhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: questionController,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onAttachPhoto,
          child: const Text('Attach Photo'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Modify the main widget to use the QuestionEntry widget
class _AuditEditorScreen extends ConsumerStatefulWidget {
  final AuditSheet? auditSheet;

  const _AuditEditorScreen({
    Key? key,
    this.auditSheet,
  }) : super(key: key);

  @override
  ConsumerState<_AuditEditorScreen> createState() => _AuditEditorScreenState();
}

class _AuditEditorScreenState extends ConsumerState<_AuditEditorScreen> {
  final List<AuditQuestion> savedQuestions = [];
  String? selectedZone;
  DateTime? selectedDate;
  String? selectedMonth;
  int? selectedYear;
  final TextEditingController nameController = TextEditingController();
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
    } else {
      selectedYear = DateTime.now().year;
      selectedMonth = months[DateTime.now().month - 1];
    }
    Future.microtask(() => ref.read(zoneListProvider.notifier).fetchZones());
  }

  @override
  void dispose() {
    nameController.dispose();
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _AddQuestionsPage(
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

class _CreateAuditSheetPage extends ConsumerStatefulWidget {
  const _CreateAuditSheetPage({Key? key}) : super(key: key);

  @override
  ConsumerState<_CreateAuditSheetPage> createState() => _CreateAuditSheetPageState();
}

class _CreateAuditSheetPageState extends ConsumerState<_CreateAuditSheetPage> {
  String? selectedZone;
  DateTime? selectedDate;
  String? selectedMonth;
  int? selectedYear;
  final List<AuditQuestion> questions = [];
  final TextEditingController nameController = TextEditingController();
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
    Future.microtask(() => ref.read(zoneListProvider.notifier).fetchZones());
  }

  @override
  void dispose() {
    nameController.dispose();
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
                    DropdownButtonFormField<String>(
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _navigateToAddQuestions,
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
                          'Add Questions',
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

  Future<void> _navigateToAddQuestions() async {
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

    if (selectedMonth == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both month and year')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddQuestionsPage(
          savedQuestions: questions,
          onAddQuestion: (AuditQuestion question) {
            setState(() {
              questions.add(question);
            });
          },
          month: selectedMonth!,
          sheetName: nameController.text.trim(),
          zoneName: selectedZone,
          zoneId: selectedZone,
          isEditing: false,
        ),
      ),
    );

    if (result != null && result is AuditSheet) {
      final monthIndex = months.indexOf(selectedMonth!);
      final auditSheet = AuditSheet(
        id: result.id,
        name: result.name,
        zoneId: result.zoneId,
        orgId: result.orgId,
        createdAt: DateTime(selectedYear!, monthIndex + 1, 1),
        questions: result.questions,
        month: selectedMonth!,
      );
      await _generateAuditSheet(auditSheet);
    }
  }

  Future<void> _generateAuditSheet(AuditSheet auditSheet) async {
    setState(() {
      isLoading = true;
    });

    try {
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

class _AddQuestionsPage extends StatefulWidget {
  final List<AuditQuestion> savedQuestions;
  final Function(AuditQuestion) onAddQuestion;
  final String? zoneName;
  final String sheetName;
  final String month;
  final String? zoneId;
  final bool isEditing;

  const _AddQuestionsPage({
    Key? key,
    required this.savedQuestions,
    required this.onAddQuestion,
     this.zoneName,
    required this.month,
    required this.sheetName,
    this.zoneId,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddQuestionsPageState createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<_AddQuestionsPage> {
  final TextEditingController questionController = TextEditingController();
  final List<AuditQuestion> questions = [];
  bool showDefaultQuestions = true;

  @override
  void initState() {
    super.initState();
    questions.addAll(widget.savedQuestions);
  }

  void _loadDefaultQuestions() {
    setState(() {
      questions.clear();
      questions.addAll(defaultAuditQuestions);
    });
  }

  void _removeAllQuestions() {
    setState(() {
      questions.clear();
    });
  }

  void _addQuestion() {
    if (questionController.text.isNotEmpty) {
      final newQuestion = AuditQuestion(
        id: DateTime.now().toString(),
        question: questionController.text,
        section: 15,
        grade: 0,
      );
      setState(() {
        questions.add(newQuestion);
        questionController.clear();
      });
    }
  }

  Future<void> _generateAuditSheet() async {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    final storage = const FlutterSecureStorage();
    final orgId = await storage.read(key: 'orgId') ?? '';
    
    final auditSheet = AuditSheet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.sheetName!,
      zoneId: widget.zoneId ?? '',
      orgId: orgId,
      createdAt: DateTime.now(),
      questions: questions,
      month: widget.month
    );

    Navigator.pop(context, auditSheet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Edit Questions' : 'Add Questions',
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: questions.isEmpty ? null : 
              widget.isEditing ? 
                () => Navigator.pop(context, questions) : 
                _generateAuditSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.isEditing ? 
                    'Save Questions ${questions.isNotEmpty ? "(${questions.length})" : ""}' :
                    'Generate Audit Sheet ${questions.isNotEmpty ? "(${questions.length})" : ""}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Action Buttons
            Container(
              padding: const EdgeInsets.all(24.0),
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
                  const Text(
                    'Question Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add, load default, or manage your audit questions',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadDefaultQuestions,
                          icon: const Icon(Icons.playlist_add, color: Colors.white),
                          label: const Text(
                            'Load Default Questions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      if (questions.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _removeAllQuestions,
                          icon: const Icon(Icons.clear_all, color: Colors.red),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.red),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add New Question Container
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
                          'Add New Question',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: questionController,
                          decoration: InputDecoration(
                            labelText: 'Question',
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
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _addQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Question',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (questions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Added Questions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${questions.length}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              question.question,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.primary),
                                  onPressed: () {
                                    questionController.text = question.question;
                                    setState(() {
                                      questions.removeAt(index);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      questions.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Add padding at the bottom to prevent content from being hidden behind the fixed button
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 