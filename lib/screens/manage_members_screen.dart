import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/member_service.dart';
import '../widgets/member_form.dart';
import '../core/auth/session.dart';

final memberServiceProvider = Provider((ref) => MemberService());

final membersProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final memberService = ref.watch(memberServiceProvider);
  return memberService.getZoneMembers(
    orgId: params['orgId']!,
    zoneId: params['zoneId']!,
  );
});

class ManageMembersScreen extends ConsumerStatefulWidget {
  final String zoneName;
  final String zoneId;
  final String orgId;
  
  const ManageMembersScreen({
    Key? key,
    required this.zoneName,
    required this.zoneId,
    required this.orgId,
  }) : super(key: key);

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  late final FutureProvider<Map<String, dynamic>> _membersProvider;

  @override
  void initState() {
    super.initState();
    _membersProvider = FutureProvider((ref) async {
      final memberService = ref.watch(memberServiceProvider);
      return memberService.getZoneMembers(
        orgId: widget.orgId,
        zoneId: widget.zoneId,
      );
    });
  }

  Future<void> _handleMemberSubmit(Map<String, dynamic> memberData) async {
    try {
      print('Submitting member data: $memberData');
      final memberService = ref.read(memberServiceProvider);
      final response = await memberService.createOrganizationMember(
        orgId: widget.orgId,
        zoneId: widget.zoneId,
        roleId: memberData['roleId'],
        fullName: memberData['fullName'],
        email: memberData['email'],
        password: memberData['password'],
        phoneNumber: memberData['phoneNumber'],
        designation: memberData['designation'],
        signupType: memberData['signupType'],
        role: memberData['role'],
        file: memberData['file'],
      );

      print('Member creation response: $response');

      // Refresh the members list
      ref.invalidate(_membersProvider);
      await ref.refresh(_membersProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the bottom sheet
      }
    } catch (e) {
      print('Error in _handleMemberSubmit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_membersProvider);
    final userInfo = ref.watch(currentUserProvider);
    final isZoneMember = userInfo?.isReadOnly ?? true;
    final canAccessZone = !isZoneMember || (userInfo?.zoneId == widget.zoneId);

    // If zone member is trying to access a different zone, show access denied
    if (isZoneMember && !canAccessZone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            'Access Denied',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => context.go('/manage-zone'),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You can only view members from your assigned zone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isZoneMember ? 'View Members - ${widget.zoneName}' : 'Manage Members - ${widget.zoneName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.go('/manage-zone'),
        ),
      ),
      floatingActionButton: isZoneMember ? null : FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => MemberForm(
              zoneId: widget.zoneId,
              orgId: widget.orgId,
              onSubmit: _handleMemberSubmit,
            ),
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: membersAsync.when(
            data: (membersData) {
              final members = membersData['data'] as List<dynamic>? ?? [];
              
              if (members.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No members found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isZoneMember 
                          ? 'No members are currently assigned to this zone.'
                          : 'Start by adding members to this zone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: members.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildMemberCard(members[index]);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(_membersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _toggleMember(Map<String, dynamic> member) async {
    final deactivate = member['approved'] != false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deactivate ? 'Deactivate member?' : 'Reactivate member?'),
        content: Text(deactivate
            ? '${member['fullName'] ?? 'This member'} will no longer be able to log in.'
            : '${member['fullName'] ?? 'This member'} will be able to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: deactivate ? Colors.red.shade700 : Colors.green.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(deactivate ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(memberServiceProvider).setMemberApproved(member['id'].toString(), !deactivate);
      ref.invalidate(_membersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(deactivate ? 'Member deactivated' : 'Member reactivated'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password?'),
        content: Text('A new password will be generated and emailed to ${member['email'] ?? 'the member'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final newPassword = await ref.read(memberServiceProvider).resetMemberPassword(member['id'].toString());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Password reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The new password has been emailed to the member.'),
              if (newPassword != null) ...[
                const SizedBox(height: 12),
                SelectableText(newPassword, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Share it securely if the email does not arrive.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final userInfo = ref.watch(currentUserProvider);
    final isZoneMember = userInfo?.isReadOnly ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member['photo'] != null)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(member['photo']),
                )
              else
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: AppColors.secondaryLight),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['fullName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member['email'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isZoneMember)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                  onSelected: (value) {
                    if (value == 'toggle') _toggleMember(member);
                    if (value == 'reset') _resetPassword(member);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(member['approved'] == false ? Icons.person_add_alt_1 : Icons.person_off_outlined, size: 20,
                              color: member['approved'] == false ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Text(member['approved'] == false ? 'Reactivate' : 'Deactivate',
                              style: TextStyle(color: member['approved'] == false ? Colors.green : Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, size: 20),
                          SizedBox(width: 8),
                          Text('Reset password'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Role', member['role'] ?? 'Unknown'),
              const SizedBox(width: 8),
              _buildInfoChip('Designation', member['designation'] ?? 'Unknown'),
            ],
          ),
          if (member['phoneNumber'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoChip('Phone', member['phoneNumber']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 