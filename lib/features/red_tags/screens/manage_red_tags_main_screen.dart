import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../providers/user_provider.dart';
import '../models/red_tag.dart';
import '../services/red_tag_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class ManageRedTagsMainScreen extends ConsumerStatefulWidget {
  const ManageRedTagsMainScreen({super.key});

  @override
  ConsumerState<ManageRedTagsMainScreen> createState() => _ManageRedTagsMainScreenState();
}

class _ManageRedTagsMainScreenState extends ConsumerState<ManageRedTagsMainScreen> {
  final RedTagService _redTagService = RedTagService();
  final _storage = const FlutterSecureStorage();
  List<RedTag> _redTags = [];
  List<RedTag> _filteredRedTags = [];
  bool _isLoading = true;
  String? _error;
  String? _orgId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadOrgId();
  }

  Future<void> _loadOrgId() async {
    try {
      final orgId = await _storage.read(key: 'orgId');
      final userId = await _storage.read(key: 'userId');
      if (orgId == null) {
        setState(() {
          _error = 'Organization ID not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _orgId = orgId;
        _userId = userId;
      });
      _loadRedTags();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRedTags() async {
    if (_orgId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final redTags = await _redTagService.getRedTags(_orgId!);
      
      // Filter red tags based on user role
      final userInfo = ref.read(userProvider);
      List<RedTag> filteredTags = redTags;
      
      if (userInfo?.isZoneMember == true && userInfo?.zoneId != null) {
        // Zone members can only see red tags from their assigned zone
        filteredTags = redTags.where((tag) => tag.zoneId == userInfo!.zoneId).toList();
      }

      setState(() {
        _redTags = redTags;
        _filteredRedTags = filteredTags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRedTag(RedTag redTag) async {
    try {
      final response = await _redTagService.deleteRedTag(redTag.id);
      await _loadRedTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response ?? 'Red tag deleted successfully'),
            backgroundColor: response?.contains('Error') == true ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting red tag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(RedTag redTag) async {
    final descriptionController = TextEditingController(text: redTag.description);
    final remarksController = TextEditingController(text: redTag.remarks ?? '');
    String selectedStatus = redTag.status;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Red Tag'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['PENDING', 'APPROVED', 'REJECTED'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _redTagService.updateRedTag(
                  redTag.id,
                  description: descriptionController.text,
                  path: redTag.path,
                  status: selectedStatus,
                  remarks: remarksController.text,
                  modifiedBy: _userId ?? '',
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _loadRedTags();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Red tag updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating red tag: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(RedTag redTag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Red Tag'),
        content: const Text('Are you sure you want to delete this red tag?'),
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

    if (confirmed == true) {
      await _deleteRedTag(redTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _loadOrgId,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manage Red Tags',
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRedTags,
              child: _filteredRedTags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_off_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No red tags found',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredRedTags.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final tag = _filteredRedTags[index];
                        final isPending = tag.status == 'PENDING';
                        final isRejected = tag.status == 'REJECTED';
                        Color statusColor;
                        if (isPending) {
                          statusColor = AppColors.warning.withOpacity(0.2);
                        } else if (isRejected) {
                          statusColor = AppColors.error.withOpacity(0.2);
                        } else {
                          statusColor = AppColors.success.withOpacity(0.2);
                        }
                        final statusText = isPending ? 'Decision Pending' : tag.status;

                        return Container(
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.label_important, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tag.description,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Zone: ${tag.zoneName}',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (tag.remarks != null) ...[
                                Text('Remarks: ${tag.remarks}'),
                                const SizedBox(height: 10),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPending 
                                          ? AppColors.warning 
                                          : isRejected 
                                              ? AppColors.error 
                                              : AppColors.success,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: isPending 
                                            ? AppColors.textPrimary 
                                            : isRejected 
                                                ? AppColors.secondaryLight 
                                                : AppColors.secondaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _showEditDialog(tag);
                                            break;
                                          case 'delete':
                                            _showDeleteConfirmation(tag);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
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
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-red-tag'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }
} 