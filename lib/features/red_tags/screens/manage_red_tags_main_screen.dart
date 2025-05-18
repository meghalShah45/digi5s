import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../models/red_tag.dart';
import '../services/red_tag_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManageRedTagsMainScreen extends StatefulWidget {
  const ManageRedTagsMainScreen({super.key});

  @override
  State<ManageRedTagsMainScreen> createState() => _ManageRedTagsMainScreenState();
}

class _ManageRedTagsMainScreenState extends State<ManageRedTagsMainScreen> {
  final RedTagService _redTagService = RedTagService();
  final _storage = const FlutterSecureStorage();
  List<RedTag> _redTags = [];
  bool _isLoading = true;
  String? _error;
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _loadOrgId();
  }

  Future<void> _loadOrgId() async {
    try {
      final orgId = await _storage.read(key: 'orgId');
      if (orgId == null) {
        setState(() {
          _error = 'Organization ID not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _orgId = orgId;
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
      setState(() {
        _redTags = redTags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(RedTag redTag) async {
    final TextEditingController activityController = TextEditingController();
    String selectedStatus = 'COMPLETED';
    final userId = await _storage.read(key: 'userId');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: ['COMPLETED', 'REJECTED'].map((status) {
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
            const SizedBox(height: 16),
            TextField(
              controller: activityController,
              decoration: const InputDecoration(
                labelText: 'Activity Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (activityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter activity description')),
                );
                return;
              }
              try {
                await _redTagService.updateRedTagStatus(
                  redTag.id,
                  selectedStatus,
                  activityController.text,
                  userId ?? '',
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadRedTags();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating status: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Manage Red Tags'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,

        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRedTags,
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _redTags.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final tag = _redTags[index];
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
                      if (isPending)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _updateStatus(tag),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Update Status'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/create-red-tag'),
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }
} 