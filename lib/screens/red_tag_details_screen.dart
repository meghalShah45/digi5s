import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/red_tags/models/red_tag.dart';
import '../features/red_tags/services/red_tag_service.dart';
import '../theme/colors.dart';

class RedTagDetailsScreen extends StatefulWidget {
  final String tagId;

  const RedTagDetailsScreen({
    Key? key,
    required this.tagId,
  }) : super(key: key);

  @override
  State<RedTagDetailsScreen> createState() => _RedTagDetailsScreenState();
}

class _RedTagDetailsScreenState extends State<RedTagDetailsScreen> {
  final RedTagService _redTagService = RedTagService();
  RedTag? _redTag;
  bool _isLoading = true;
  String? _error;
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRedTag();
  }

  Future<void> _loadRedTag() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // TODO: Add getRedTagById method to RedTagService
      // For now, we'll use the existing red tag from the list
      final redTags = await _redTagService.getRedTags('');
      final redTag = redTags.firstWhere((tag) => tag.id == widget.tagId);
      
      setState(() {
        _redTag = redTag;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_redTag == null) return;

    final storage = const FlutterSecureStorage();
    final userId = await storage.read(key: 'userId');

    try {
      await _redTagService.updateRedTagStatus(
        _redTag!.id,
        newStatus,
        _remarksController.text,
          userId ?? ''
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
        _loadRedTag(); // Reload the red tag data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _redTag == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${_error ?? "Red tag not found"}'),
              ElevatedButton(
                onPressed: _loadRedTag,
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
        title: const Text('Red Tag Details'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildZoneSection(),
            const SizedBox(height: 24),
            _buildActivitySection(),
            if (_redTag!.status == 'PENDING') ...[
              const SizedBox(height: 24),
              _buildUpdateSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _redTag!.description,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(_redTag!.status),
              ],
            ),
            const SizedBox(height: 16),
            if (_redTag!.remarks != null) ...[
              Text(
                'Remarks: ${_redTag!.remarks}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Created by: ${_redTag!.email}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created on: ${_formatDate(_redTag!.createdAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zone Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Zone: ${_redTag!.zoneName}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_redTag!.activity.isEmpty)
              const Text('No activity recorded')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _redTag!.activity.length,
                itemBuilder: (context, index) {
                  final activity = _redTag!.activity[index];
                  return ListTile(
                    title: Text(activity.description),
                    subtitle: Text(
                      '${activity.status} by ${activity.actionBy} on ${_formatDate(activity.actionOn)}',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                hintText: 'Enter remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('REJECTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
} 