import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../providers/zone_provider.dart';
import '../../models/zone_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManageZoneScreen extends ConsumerStatefulWidget {
  const ManageZoneScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageZoneScreen> createState() => _ManageZoneScreenState();
}

class _ManageZoneScreenState extends ConsumerState<ManageZoneScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(zoneListProvider.notifier).fetchZones());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ZoneData> _filterZones(List<ZoneData>? zones) {
    if (zones == null) return [];
    if (_searchQuery.isEmpty) return zones;
    
    return zones.where((zone) {
      final name = zone.name.toLowerCase();
      final description = zone.description?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zoneListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Manage Zones',
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
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
        onPressed: () async {
          final orgId = await const FlutterSecureStorage().read(key: 'orgId');
          if (orgId != null) {
            context.go('/add-zone', extra: orgId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Organization ID not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(
                child: zonesAsync.when(
                  data: (zones) {
                    final filteredZones = _filterZones(zones);
                    
                    if (filteredZones.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No zones found' : 'No zones match your search',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredZones.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildZoneCard(context, filteredZones[index]);
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
                          onPressed: () => ref.read(zoneListProvider.notifier).fetchZones(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search zones...',
          hintStyle: const TextStyle(color: AppColors.textLight),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _buildZoneCard(BuildContext context, ZoneData zone) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //   decoration: BoxDecoration(
              //     color: zone.active
              //         ? AppColors.success.withOpacity(0.3)
              //         : AppColors.error.withOpacity(0.3),
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: Text(
              //     zone.active ? 'Active' : 'Inactive',
              //     style: TextStyle(
              //       color: zone.active ? AppColors.success : AppColors.error,
              //       fontSize: 12,
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ),
            ],
          ),
          if (zone.description != null) ...[
            const SizedBox(height: 8),
            Text(
              zone.description!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Text(
          //   'Members: }',
          //   style: const TextStyle(
          //     color: AppColors.textSecondary,
          //     fontSize: 14,
          //   ),
          // ),
          // if (zone.leaderName != null) ...[
          //   const SizedBox(height: 4),
          //   Text(
          //     'Leader: ${zone.leaderName}',
          //     style: const TextStyle(
          //       color: AppColors.textSecondary,
          //       fontSize: 14,
          //     ),
          //   ),
          // ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.go(
                  '/manage-members/${Uri.encodeComponent(zone.name)}',
                  extra: {
                    'zoneId': zone.id,
                    'orgId': zone.orgId,
                  },
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                child: const Text('Manage Members'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 