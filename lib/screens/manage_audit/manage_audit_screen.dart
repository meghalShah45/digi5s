import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/audit/models/audit_sheet.dart';
import '../../../theme/colors.dart';
import '../../features/audit/models/audit_submission.dart';
import '../../providers/audit_sheet_provider.dart';
import '../../providers/zone_provider.dart';
import 'widgets/create_audit_sheet.dart';
import 'widgets/audit_editor_screen.dart';
import '../../../features/audit/screens/perform_audit_screen.dart';
import 'audit_statistics_by_zone_screen.dart';

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
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildAuditList(),
          ),
          SizedBox(height: 80,)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newAuditSheet = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAuditSheetPage(),
            ),
          );
          if (newAuditSheet != null) {
            ref.refresh(auditSheetsProvider((orgId: orgId!)));
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
              Row(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final auditSheetsAsync = ref.watch(auditSheetsProvider((orgId: orgId ?? '')));
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuditStatisticsByZoneScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics, size: 18),
                    label: const Text('Statistics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
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
        final auditSheetsAsync = ref.watch(auditSheetsProvider((orgId: orgId!)));
        
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
              padding: const EdgeInsets.only(top: 10),
              itemCount: auditSheets.length,
              itemBuilder: (context, index) {
                final sheet = auditSheets[index];
                return _buildAuditSheetCard(sheet);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) {
            print('Error in _buildAuditList: $error');
            print('Stack trace: $stackTrace');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading audit sheets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.refresh(auditSheetsProvider((orgId: orgId!)));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool> _checkForSubmissions(String auditSheetId) async {
    try {
      final submissions = await ref.read(auditSheetSubmissionsProvider(auditSheetId).future);
      return submissions.isNotEmpty;
    } catch (e) {
      print('Error checking submissions: $e');
      return false;
    }
  }

  void _editAuditSheet(AuditSheet sheet) async {
    try {
      // Check for submissions first
      final hasSubmissions = await _checkForSubmissions(sheet.id);
      if (hasSubmissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot edit this audit sheet because it has existing submissions. Please create a new audit sheet instead.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      _showAuditEditor(sheet);
      if (orgId != null) {
        ref.refresh(auditSheetsProvider((orgId: orgId!)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAuditEditor(AuditSheet? sheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuditEditorScreen(auditSheet: sheet),
      ),
    ).then((_) {
      if (orgId != null) {
        ref.refresh(auditSheetsProvider((orgId: orgId!)));
      }
    });
  }

  void _deleteAuditSheet(AuditSheet sheet) async {
    try {
      // Check for submissions first
      final hasSubmissions = await _checkForSubmissions(sheet.id);
      if (hasSubmissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot delete this audit sheet because it has existing submissions.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Audit Sheet'),
          content: const Text('Are you sure you want to delete this audit sheet? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        await ref.read(deleteAuditSheetProvider(sheet.id).future);
        if (orgId != null) {
          ref.refresh(auditSheetsProvider((orgId: orgId!)));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit sheet deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting audit sheet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewSubmissions(AuditSheet sheet) async {
    try {
      List<AuditSubmission> submissions = await ref.read(auditSheetSubmissionsProvider(sheet.id).future);
      if (!mounted) return;

      if (submissions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No submissions found for this audit sheet.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Submissions for ${sheet.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      AuditSubmission submission = submissions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            'Submitted by: ${submission.submittedBy}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${_formatDate(DateTime.parse(submission.submittedAt!))}'),
                              Text('Score: ${submission.totalScore}/${submission.totalScore}'),

                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PerformAuditScreen(
                                    sheet: sheet,
                                    submissionId: submission.submissionId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading submissions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAuditSheetCard(AuditSheet sheet) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheet.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatDate(sheet.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editAuditSheet(sheet);
                        break;
                      case 'delete':
                        _deleteAuditSheet(sheet);
                        break;
                      case 'view':
                        _viewSubmissions(sheet);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Submissions'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Questions: ${sheet.questions.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 