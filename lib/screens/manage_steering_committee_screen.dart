import 'package:flutter/material.dart';
import '../models/steering_committee.dart';
import 'package:image_picker/image_picker.dart';

class ManageSteeringCommitteeScreen extends StatefulWidget {
  const ManageSteeringCommitteeScreen({Key? key}) : super(key: key);

  @override
  State<ManageSteeringCommitteeScreen> createState() => _ManageSteeringCommitteeScreenState();
}

class _ManageSteeringCommitteeScreenState extends State<ManageSteeringCommitteeScreen> {
  final List<SteeringCommitteeMember> members = []; // TODO: Replace with actual data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Steering Committee'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Committee Members',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${members.length} members',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (members.isEmpty) {
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
              'No committee members added yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: members.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(member.photoUrl!),
              radius: 25,
            ),
            title: Text(member.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.role),
                Text('Joined: ${_formatDate(member.joinedDate)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditMemberDialog(member),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteMember(member),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddMemberDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController roleController = TextEditingController();
    String? photoUrl;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Committee Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  hintText: 'Enter member name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'Enter member role',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  // TODO: Implement photo upload
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    // TODO: Upload image and get URL
                    photoUrl = 'https://picsum.photos/200'; // Placeholder
                  }
                },
                icon: const Icon(Icons.photo_camera),
                label: const Text('Upload Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
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
              // TODO: Implement add member logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditMemberDialog(SteeringCommitteeMember member) async {
    final TextEditingController nameController = TextEditingController(text: member.name);
    final TextEditingController roleController = TextEditingController(text: member.role);
    String photoUrl = member.photoUrl!;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Committee Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  hintText: 'Enter member name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'Enter member role',
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                backgroundImage: NetworkImage(photoUrl),
                radius: 40,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  // TODO: Implement photo upload
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    // TODO: Upload image and get URL
                    photoUrl = 'https://picsum.photos/200'; // Placeholder
                  }
                },
                icon: const Icon(Icons.photo_camera),
                label: const Text('Change Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
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
              // TODO: Implement edit member logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember(SteeringCommitteeMember member) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Committee Member'),
        content: Text('Are you sure you want to remove ${member.name} from the committee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 