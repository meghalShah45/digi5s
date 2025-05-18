import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/member_edit_dialog.dart';
import '../providers/steering_committee_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildMainGrid(context),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // _buildSpeedDial(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hey, Admin',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
            height: 1.2,
          ),
        ),
        _buildSpeedDial(context),
        /*Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: NetworkImage('https://picsum.photos/200'),
              fit: BoxFit.cover,
            ),
          ),
        ),*/
      ],
    );
  }

  Widget _buildMainGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.05,
      children: [
        buildGridItem(
          context,
          'Manage Zone &\nmembers',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.groups_outlined,
          onTap: () => context.push('/manage-zone'),
        ),
        buildGridItem(
          context,
          'Manage Red\nTags',
          const Color(0xFFFCE4EC),
          const Color(0xFFC2185B),
          Icons.label_outlined,
          onTap: () => context.push('/manage-red-tags'),
        ),
        buildGridItem(
          context,
          'Manage\nManual',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.menu_book_outlined,
          onTap: () => context.push('/manage-manual'),
        ),
        buildGridItem(
          context,
          'Manage\nAudit',
          const Color(0xFFF3E5F5),
          const Color(0xFF7B1FA2),
          Icons.assignment_outlined,
          onTap: () => context.push('/manage-audit'),
        ),
        buildGridItem(
          context,
          'Manage\nNews',
          const Color(0xFFFFF3E0),  // Light Orange
          const Color(0xFFEF6C00),  // Dark Orange
          Icons.newspaper_outlined,
          onTap: () => context.push('/manage-news'),
        ),
        buildGridItem(
          context,
          'Manage Training\nMaterial',
          const Color(0xFFE8EAF6),  // Light Indigo
          const Color(0xFF283593),  // Dark Indigo
          Icons.school_outlined,
          onTap: () => context.push('/manage-training-material'),
        ),
        buildGridItem(
          context,
          'Upload Best\nPractices',
          const Color(0xFFE0F2F1),  // Light Teal
          const Color(0xFF00695C),  // Dark Teal
          Icons.upload_file_outlined,
          onTap: () => context.push('/manage-best-practices'),
        ),
        buildGridItem(
          context,
          'Flash\nNews',
          const Color(0xFFFFEBEE),  // Light Red
          const Color(0xFFC62828),  // Dark Red
          Icons.flash_on_outlined,
          onTap: () => context.push('/flash-news'),
        ),
      ],
    );
  }

  Widget buildGridItem(
    BuildContext context,
    String title,
    Color bgColor,
    Color iconColor,
    IconData icon, {
      VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context) {
    return ElevatedButton(
      child: const Text('Add Committee Member', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),),
      onPressed: () => context.push('/manage-steering-committee'),
      // backgroundColor: Colors.green,
      // icon: const Icon(Icons.add),
      // label: ,
    );
  }

  Future<void> _showQuickAddMemberDialog(BuildContext context, WidgetRef ref) async {
    // Load members first to ensure the provider is initialized
    await ref.read(steeringCommitteeProvider.notifier).loadMembers();
    
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => const MemberEditDialog(),
      );
    }
  }
}

extension ColorExtension on Color {
  Color get darker {
    return Color.fromARGB(
      alpha,
      (red * 0.7).round(),
      (green * 0.7).round(),
      (blue * 0.7).round(),
    );
  }
} 