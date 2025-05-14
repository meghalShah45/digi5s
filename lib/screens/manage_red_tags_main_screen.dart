import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
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
            final statusColor = isPending ? AppColors.warning.withOpacity(0.2) : AppColors.success.withOpacity(0.2);
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPending ? AppColors.warning : AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: isPending ? AppColors.textPrimary : AppColors.secondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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