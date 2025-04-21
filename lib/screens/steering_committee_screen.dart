import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/steering_committee.dart';
import '../providers/steering_committee_provider.dart';
import '../widgets/member_edit_dialog.dart';
import 'manage_steering_committee_screen.dart';

class SteeringCommitteeScreen extends ConsumerStatefulWidget {
  const SteeringCommitteeScreen({super.key});

  @override
  ConsumerState<SteeringCommitteeScreen> createState() => _SteeringCommitteeScreenState();
}

class _SteeringCommitteeScreenState extends ConsumerState<SteeringCommitteeScreen> {
  @override
  void initState() {
    super.initState();
    // Load members when screen initializes
    Future.microtask(() => ref.read(steeringCommitteeProvider.notifier).loadMembers());
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(steeringCommitteeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Steering Committee'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildHeader(members.length),
          Expanded(
            child: members.isEmpty
                ? _buildEmptyState()
                : _buildMembersList(members),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int memberCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Committee Members',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddEditMemberDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No committee members yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add members',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<SteeringCommitteeMember> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildMemberAvatar(member),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.role,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined ${DateFormat.yMMMd().format(member.joinedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditMemberDialog(context, member),
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(context, member),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberAvatar(SteeringCommitteeMember member) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.green.shade100,
      backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
      child: member.photoUrl == null
          ? Text(
              member.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            )
          : null,
    );
  }

  Future<void> _showAddEditMemberDialog(BuildContext context, [SteeringCommitteeMember? member]) async {
    await showDialog(
      context: context,
      builder: (context) => MemberEditDialog(member: member),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, SteeringCommitteeMember member) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to remove ${member.name} from the committee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(steeringCommitteeProvider.notifier).deleteMember(member.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
} 