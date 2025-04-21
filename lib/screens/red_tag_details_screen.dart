import 'package:flutter/material.dart';
import '../models/red_tag.dart';
import '../models/zone.dart';

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
  late RedTag redTag;
  final _remarksController = TextEditingController();
  final _decisionController = TextEditingController();
  late Zone zone;

  @override
  void initState() {
    super.initState();
    // TODO: Fetch actual red tag data
    redTag = RedTag(
      id: widget.tagId,
      title: 'Machine Maintenance Issue',
      description: 'Critical maintenance required for Machine A in Zone 1',
      dateCreated: DateTime.now(),
      status: 'pending',
      zoneId: '1',
      createdById: '1',
    );

    // TODO: Fetch actual zone data
    zone = Zone(
      id: '1',
      name: 'Zone A',
      description: 'Production Area',
      memberIds: ['1', '2', '3'],
      leaderId: '1',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Red Tag Details'),
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
            _buildDecisionSection(),
            const SizedBox(height: 24),
            _buildRemarksSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
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
                    redTag.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(redTag.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              redTag.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Created on: ${_formatDate(redTag.dateCreated)}',
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
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              zone.description,
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

  Widget _buildDecisionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Steering Committee Decision',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _decisionController,
              decoration: const InputDecoration(
                hintText: 'Enter committee decision',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                hintText: 'Enter any additional remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitDecision,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Submit Decision',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
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

  void _submitDecision() {
    if (_decisionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a decision'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement actual submission logic
    // This would typically involve:
    // 1. Updating the red tag status
    // 2. Saving the decision and remarks
    // 3. Notifying zone members
    // 4. Updating the UI

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _decisionController.dispose();
    super.dispose();
  }
} 