import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserInfo {
  final String id;
  final String role;
  final String name;
  final String orgId;
  final String zoneId;

  UserInfo({
    required this.id,
    required this.role,
    required this.name,
    required this.orgId,
    required this.zoneId,
  });

  // Role checking methods
  bool get isZoneMember => role.toUpperCase() == 'ZONE-MEMBER';
  bool get isZoneLeader => role.toUpperCase() == 'ZONE-LEADER';
  bool get isOrgAdmin => role.toUpperCase() == 'ORGANISATION-ADMIN';
  bool get isSuperAdmin => role.toUpperCase() == 'SUPER-ADMIN';
  bool get isViewer => role.toUpperCase() == 'VIEWER';

  // Permission methods
  bool get canEdit => !isZoneMember && !isViewer;
  bool get canCreate => !isZoneMember && !isViewer;
  bool get canDelete => !isZoneMember && !isViewer;
}

class UserProvider extends StateNotifier<UserInfo?> {
  UserProvider() : super(null) {
    _loadUserInfo();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _loadUserInfo() async {
    try {
      final userId = await _storage.read(key: 'userId');
      final userRole = await _storage.read(key: 'userRole');
      final userName = await _storage.read(key: 'userName');
      final orgId = await _storage.read(key: 'orgId');
      final zoneId = await _storage.read(key: 'zoneId');

      if (userId != null && userRole != null) {
        state = UserInfo(
          id: userId,
          role: userRole,
          name: userName ?? '',
          orgId: orgId ?? '',
          zoneId: zoneId ?? '',
        );
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  // Convenience getters that delegate to the current state
  bool get isZoneMember => state?.isZoneMember ?? false;
  bool get isZoneLeader => state?.isZoneLeader ?? false;
  bool get isOrgAdmin => state?.isOrgAdmin ?? false;
  bool get isSuperAdmin => state?.isSuperAdmin ?? false;
  bool get isViewer => state?.isViewer ?? false;

  bool get canEdit => state?.canEdit ?? false;
  bool get canCreate => state?.canCreate ?? false;
  bool get canDelete => state?.canDelete ?? false;

  String? get currentZoneId => state?.zoneId;
  String? get currentOrgId => state?.orgId;
  String? get currentUserId => state?.id;
}

final userProvider = StateNotifierProvider<UserProvider, UserInfo?>((ref) {
  return UserProvider();
}); 