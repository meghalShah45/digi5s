import 'package:flutter/material.dart';
import '../models/red_tag.dart';
import '../services/red_tag_service.dart';

class RedTagListScreen extends StatefulWidget {
  final String orgId;

  const RedTagListScreen({Key? key, required this.orgId}) : super(key: key);

  @override
  State<RedTagListScreen> createState() => _RedTagListScreenState();
}

class _RedTagListScreenState extends State<RedTagListScreen> {
  final RedTagService _redTagService = RedTagService();
  List<RedTag> _redTags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRedTags();
  }

  Future<void> _loadRedTags() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final redTags = await _redTagService.getRedTags(widget.orgId);
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
    final TextEditingController remarksController = TextEditingController();
    String selectedStatus = 'APPROVED';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: ['APPROVED', 'REJECTED'].map((status) {
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
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
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
              try {
                await _redTagService.updateRedTagStatus(
                  redTag.id,
                  selectedStatus,
                  remarksController.text,
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
                onPressed: _loadRedTags,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Tags'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRedTags,
        child: ListView.builder(
          itemCount: _redTags.length,
          itemBuilder: (context, index) {
            final redTag = _redTags[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('Zone: ${redTag.zoneName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${redTag.status}'),
                    Text('Description: ${redTag.description}'),
                    if (redTag.remarks != null)
                      Text('Remarks: ${redTag.remarks}'),
                    Text('Created by: ${redTag.email}'),
                    Text('Created at: ${redTag.createdAt.toString()}'),
                  ],
                ),
                trailing: redTag.status == 'PENDING'
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _updateStatus(redTag),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
} 