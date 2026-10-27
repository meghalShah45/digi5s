import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../core/auth/session.dart';
import '../features/dashboard/dashboard_repository.dart';
import '../features/zone_member/models/task.dart';
import '../features/zone_member/services/task_service.dart';
import '../services/member_service.dart';
import '../services/zone_service.dart';
import '../theme/colors.dart';
import '../widgets/read_only_notice.dart';

/// Tasks waiting for a decision (status PENDING_APPROVAL). Zone leaders see
/// only their own zone; org admins see the whole organisation.
class Approve5STaskScreen extends ConsumerStatefulWidget {
  const Approve5STaskScreen({super.key});

  @override
  ConsumerState<Approve5STaskScreen> createState() => _Approve5STaskScreenState();
}

class _Approve5STaskScreenState extends ConsumerState<Approve5STaskScreen> {
  List<Task> _tasks = [];
  Map<String, Map<String, dynamic>> _members = {};
  Map<String, String> _zoneNames = {};
  bool _isLoading = true;
  bool _isProcessingAction = false;
  String? _error;
  final MemberService _memberService = MemberService();
  final ZoneService _zoneService = ZoneService();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final user = ref.read(currentUserProvider);
    final orgId = user?.orgId ?? '';
    if (orgId.isEmpty) {
      setState(() {
        _error = 'Your account is not linked to an organisation.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final zoneId = user!.isZoneLeader ? user.zoneId : null;
      final all = await ref.read(taskServiceProvider).getTasksForOrg(orgId, zoneId: zoneId);
      final tasks = all.where((t) => t.isPendingApproval).toList();

      // One zone lookup and one member lookup per zone, not per task.
      final zoneNames = <String, String>{};
      try {
        for (final z in await _zoneService.getZonesByOrgId(orgId)) {
          zoneNames[z.id] = z.zoneName;
        }
      } catch (_) {
        // Zone names are optional on this screen.
      }
      final members = <String, Map<String, dynamic>>{};
      for (final z in tasks.map((t) => t.zoneId).toSet()) {
        try {
          final res = await _memberService.getZoneMembers(orgId: orgId, zoneId: z);
          for (final m in (res['data'] as List? ?? const [])) {
            if (m is Map && m['id'] != null) members[m['id'].toString()] = Map<String, dynamic>.from(m);
          }
        } catch (_) {
          // Names are a nicety; the decision still works without them.
        }
      }

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _zoneNames = zoneNames;
        _members = members;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load tasks. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// The member's "approval requested" activity, if any (latest one).
  Activity? _submission(Task task) {
    for (final a in task.activity.reversed) {
      if (a.status == 'PENDING_APPROVAL') return a;
    }
    return null;
  }

  Future<void> _handleTaskAction(Task task, bool approve) async {
    final remarksController = TextEditingController();
    final remarks = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final missing = !approve && remarksController.text.trim().isEmpty;
          return AlertDialog(
            title: Text(approve ? 'Approve Task' : 'Reject Task'),
            content: TextField(
              controller: remarksController,
              autofocus: true,
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                labelText: approve ? 'Remarks (optional)' : 'Reason for rejection',
                hintText: approve ? 'Add a note for the member' : 'Tell the member what to fix',
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: missing ? null : () => Navigator.of(dialogContext).pop(remarksController.text.trim()),
                child: Text(approve ? 'Approve' : 'Reject'),
              ),
            ],
          );
        },
      ),
    );
    if (remarks == null || !mounted) return;

    setState(() => _isProcessingAction = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(taskServiceProvider).approve(task.id, approve: approve, remarks: remarks);
      ref.invalidate(dashboardCountsProvider);
      ref.invalidate(orgTasksProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(approve ? 'Task approved' : 'Task rejected'),
        backgroundColor: approve ? Colors.green : Colors.red,
      ));
      await _fetchTasks();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not update the task. Please try again.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Approve 5S Tasks'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton(onPressed: _fetchTasks, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTasks,
                      child: _tasks.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 200),
                                Center(child: Text('No tasks pending for approval')),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              itemCount: _tasks.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, i) => i == 0 ? const ReadOnlyNotice() : _buildTaskCard(_tasks[i - 1]),
                            ),
                    ),
          if (_isProcessingAction)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final member = _members[task.zoneMemberId];
    final submission = _submission(task);
    final submittedOn = submission?.actionDateTime ?? DateTime.tryParse(task.modifiedAt ?? '') ?? task.createdDateTime;
    final evidence = submission?.photoUrls ?? const <String>[];
    final memberNote = (submission?.remarks?.trim().isNotEmpty ?? false) ? submission!.remarks!.trim() : null;
    final date = DateFormat('d MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.taskName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFF9800), borderRadius: BorderRadius.circular(12)),
                child: const Text('Pending Approval',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(task.description, style: const TextStyle(fontSize: 15, color: Color(0xFF424242))),
          ],
          const SizedBox(height: 16),
          _buildInfoRow('Submitted by', member?['fullName']?.toString() ?? 'Unknown member'),
          if ((member?['email'] ?? '').toString().isNotEmpty) _buildInfoRow('Email', member!['email'].toString()),
          if ((member?['designation'] ?? '').toString().isNotEmpty)
            _buildInfoRow('Designation', member!['designation'].toString()),
          const SizedBox(height: 8),
          if (_zoneNames[task.zoneId] != null) _buildInfoRow('Zone', _zoneNames[task.zoneId]!),
          if (task.targetDateTime != null) _buildInfoRow('Target Date', date.format(task.targetDateTime!.toLocal())),
          if (submittedOn != null) _buildInfoRow('Submitted on', date.format(submittedOn.toLocal())),
          if (memberNote != null) _buildInfoRow('Member note', memberNote),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Completion Photos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _photoStrip(evidence),
          ],
          if (task.taskPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Task Photos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _photoStrip(task.taskPhotos.map((p) => p.path).toList()),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ReadOnlyGate(
                  builder: (context, readOnly) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: readOnly || _isProcessingAction ? null : () => _handleTaskAction(task, true),
                    child: const Text('Approve', style: TextStyle(color: AppColors.secondaryLight)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ReadOnlyGate(
                  builder: (context, readOnly) => OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC2185B),
                      side: const BorderSide(color: Color(0xFFC2185B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: readOnly || _isProcessingAction ? null : () => _handleTaskAction(task, false),
                    child: const Text('Disapprove'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoStrip(List<String> urls) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(urls[index]))),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                urls[index],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF757575), fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF424242), fontSize: 13))),
        ],
      ),
    );
  }
}
