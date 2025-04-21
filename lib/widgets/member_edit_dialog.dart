import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/steering_committee.dart';
import '../providers/steering_committee_provider.dart';

class MemberEditDialog extends ConsumerStatefulWidget {
  final SteeringCommitteeMember? member;

  const MemberEditDialog({
    super.key,
    this.member,
  });

  @override
  ConsumerState<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends ConsumerState<MemberEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _roleController = TextEditingController(text: widget.member?.role ?? '');
    _photoUrl = widget.member?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Member' : 'Add New Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter member name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                hintText: 'Enter member role',
              ),
            ),
            const SizedBox(height: 16),
            if (_photoUrl != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_photoUrl!),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // TODO: Implement actual photo upload
                setState(() {
                  _photoUrl = 'https://picsum.photos/200';
                });
              },
              icon: const Icon(Icons.photo_camera),
              label: Text(isEditing ? 'Change Photo' : 'Add Photo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final role = _roleController.text.trim();

            if (name.isEmpty || role.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }

            final member = SteeringCommitteeMember(
              id: widget.member?.id ?? DateTime.now().toString(),
              name: name,
              role: role,
              joinedDate: widget.member?.joinedDate ?? DateTime.now(),
              photoUrl: _photoUrl,
            );

            if (isEditing) {
              ref.read(steeringCommitteeProvider.notifier).updateMember(member);
            } else {
              ref.read(steeringCommitteeProvider.notifier).addMember(member);
            }

            Navigator.pop(context);
          },
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
} 