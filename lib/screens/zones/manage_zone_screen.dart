import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../providers/zone_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/zone_response.dart';
import '../../services/zone_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManageZoneScreen extends ConsumerStatefulWidget {
  const ManageZoneScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageZoneScreen> createState() => _ManageZoneScreenState();
}

class _ManageZoneScreenState extends ConsumerState<ManageZoneScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<ZoneData> _filteredZones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZonesForUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadZonesForUser() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userInfo = ref.read(userProvider);
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId');

      if (orgId == null) {
        throw Exception('Organization ID not found');
      }

      if (userInfo == null) {
        throw Exception('User information not found');
      }

      final zoneService = ZoneService();
      final zones = await zoneService.getZonesByUserRole(
        orgId,
        userInfo.role,
        userInfo.zoneId,
      );

      // Convert Zone objects to ZoneData objects
      final zoneDataList = zones.map((zone) => ZoneData(
        id: zone.id,
        name: zone.zoneName,
        description: null, // Add description if available
        orgId: zone.orgId,
        createdBy: zone.createdBy,
        createdAt: zone.createdAt,
        updatedAt: null,
      )).toList();

      setState(() {
        _filteredZones = _filterZones(zoneDataList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ZoneData> _filterZones(List<ZoneData> zones) {
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
    final userInfo = ref.watch(userProvider);
    final isZoneMember = userInfo?.isZoneMember ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isZoneMember ? 'View Zone' : 'Manage Zones',
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
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: isZoneMember ? null : FloatingActionButton(
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
              if (!isZoneMember) ...[
                _buildSearchBar(),
                const SizedBox(height: 20),
              ],
              Expanded(
                child: _buildZonesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZonesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadZonesForUser,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredZones.isEmpty) {
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
      itemCount: _filteredZones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildZoneCard(context, _filteredZones[index]);
      },
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
            _filteredZones = _filterZones(_filteredZones);
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
    final userInfo = ref.watch(userProvider);
    final isZoneMember = userInfo?.isZoneMember ?? false;

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
              if (!isZoneMember)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showEditDialog(context, zone),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => _showDeleteConfirmation(context, zone),
                    ),
                  ],
                ),
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
                child: Text(isZoneMember ? 'View Members' : 'Manage Members'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, ZoneData zone) async {
    final TextEditingController nameController = TextEditingController(text: zone.name);
    final TextEditingController descriptionController = TextEditingController(text: zone.description);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
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
                await ref.read(zoneListProvider.notifier).updateZone(
                  zone.id,
                  nameController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zone updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadZonesForUser(); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, ZoneData zone) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Are you sure you want to delete "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(zoneListProvider.notifier).deleteZone(zone.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zone deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadZonesForUser(); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 