import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/member_service.dart';
import '../widgets/member_form.dart';

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
      final memberService = ref.read(memberServiceProvider);
      await memberService.createOrganizationMember(
        orgId: widget.orgId,
        zoneId: widget.zoneId,
        roleId: '823e4567-e89b-12d3-a456-426614174204', // Default role ID
        fullName: memberData['fullName'],
        email: memberData['email'],
        password: memberData['password'],
        phoneNumber: memberData['phoneNumber'],
        designation: memberData['designation'],
        signupType: memberData['signupType'],
        role: memberData['role'],
        file: memberData['file'],
      );

      // Refresh the members list
      ref.refresh(_membersProvider);

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Manage Members - ${widget.zoneName}',
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
      floatingActionButton: FloatingActionButton(
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
            data: (response) {
              if (response['statusCode'] == 404) {
                return Center(
            child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
              children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        response['message'] ?? 'No members found',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (response['data'] == null) {
                return const Center(
                  child: Text(
                    'No members found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final members = response['data'] as List;
              if (members.isEmpty) {
                return const Center(
                  child: Text(
                    'No members found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = members[index];
                  return _buildMemberCard(member);
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
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(_membersProvider),
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

  Widget _buildMemberCard(Map<String, dynamic> member) {
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
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  member['phoneNumber'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                      ),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(12),
        ),
      child: Text(
        '$label: $value',
          style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          ),
        ),
    );
  }
} 