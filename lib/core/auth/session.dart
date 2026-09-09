import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Canonical role names used throughout the app.
///
/// The backend stores two spellings for organisation admins
/// (`ORGANISATION-ADMIN` from the admin console, `ORG-ADMIN` from
/// free-trial / paid signups). They are the same role here.
class Roles {
  Roles._();
  static const superAdmin = 'SUPER-ADMIN';
  static const orgAdmin = 'ORGANISATION-ADMIN';
  static const zoneLeader = 'ZONE-LEADER';
  static const zoneMember = 'ZONE-MEMBER';
  static const viewer = 'VIEWER';

  static String normalize(String? raw) {
    final r = (raw ?? '').trim().toUpperCase();
    if (r == 'ORG-ADMIN' || r == 'ORGANISATION-ADMIN' || r == 'ORGANIZATION-ADMIN') {
      return orgAdmin;
    }
    return r;
  }
}

/// The logged-in user. Built from the `data` object of `POST /users/login`.
class UserSession {
  final String id;
  final String? orgId;
  final String? zoneId;
  final String? roleId;
  final String email;
  final String fullName;
  final String role; // normalised
  final String roleRaw; // exactly as the backend sent it
  final String? photo;
  final String? phoneNumber;
  final String? designation;
  final String token;

  const UserSession({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.roleRaw,
    required this.token,
    this.orgId,
    this.zoneId,
    this.roleId,
    this.photo,
    this.phoneNumber,
    this.designation,
  });

  factory UserSession.fromLoginData(Map<String, dynamic> d) {
    final rawRole = (d['role'] as String?) ??
        ((d['scope'] is List && (d['scope'] as List).isNotEmpty)
            ? (d['scope'] as List).first.toString()
            : '');
    return UserSession(
      id: d['id'].toString(),
      orgId: d['orgId']?.toString(),
      zoneId: d['zoneId']?.toString(),
      roleId: d['roleId']?.toString(),
      email: (d['email'] ?? '').toString(),
      fullName: (d['fullName'] ?? '').toString(),
      role: Roles.normalize(rawRole),
      roleRaw: rawRole,
      photo: d['photo']?.toString(),
      phoneNumber: d['phoneNumber']?.toString(),
      designation: d['designation']?.toString(),
      token: (d['authToken'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orgId': orgId,
        'zoneId': zoneId,
        'roleId': roleId,
        'email': email,
        'fullName': fullName,
        'role': role,
        'roleRaw': roleRaw,
        'photo': photo,
        'phoneNumber': phoneNumber,
        'designation': designation,
        'token': token,
      };

  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
        id: j['id'] as String,
        orgId: j['orgId'] as String?,
        zoneId: j['zoneId'] as String?,
        roleId: j['roleId'] as String?,
        email: j['email'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        role: Roles.normalize(j['role'] as String?),
        roleRaw: j['roleRaw'] as String? ?? j['role'] as String? ?? '',
        photo: j['photo'] as String?,
        phoneNumber: j['phoneNumber'] as String?,
        designation: j['designation'] as String?,
        token: j['token'] as String? ?? '',
      );

  UserSession copyWith({String? fullName, String? photo, String? phoneNumber, String? designation}) =>
      UserSession(
        id: id,
        orgId: orgId,
        zoneId: zoneId,
        roleId: roleId,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role,
        roleRaw: roleRaw,
        photo: photo ?? this.photo,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        designation: designation ?? this.designation,
        token: token,
      );

  bool get isSuperAdmin => role == Roles.superAdmin;
  bool get isOrgAdmin => role == Roles.orgAdmin;
  bool get isZoneLeader => role == Roles.zoneLeader;
  bool get isZoneMember => role == Roles.zoneMember;
  bool get isViewer => role == Roles.viewer;

  /// Super admin or organisation admin.
  bool get isAdmin => isSuperAdmin || isOrgAdmin;

  /// Anyone allowed to create / edit / delete org content.
  bool get canManage => isAdmin || isZoneLeader;

  /// Read-only users.
  bool get isReadOnly => isZoneMember || isViewer;

  String get homeRoute {
    switch (role) {
      case Roles.superAdmin:
        return '/super-admin-dashboard';
      case Roles.orgAdmin:
        return '/org-admin-dashboard';
      case Roles.zoneLeader:
        return '/zone-leader-dashboard';
      case Roles.zoneMember:
        return '/zone-member-dashboard';
      case Roles.viewer:
        return '/viewer-dashboard';
      default:
        return '/login';
    }
  }
}

/// Persists the session in secure storage.
///
/// Besides the single JSON blob it also writes the legacy keys
/// (`token`, `userId`, `userRole`, `userName`, `orgId`, `zoneId`) that the
/// June-2025 screens still read directly, so those keep working until they
/// are migrated to [sessionProvider].
class SessionStore {
  SessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _sessionKey = 'session_v1';
  static const legacyKeys = ['token', 'userId', 'userRole', 'userName', 'orgId', 'zoneId', 'userEmail'];

  Future<UserSession?> read() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null || raw.isEmpty) return null;
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: 'token');
    } catch (_) {
      return null;
    }
  }

  Future<void> write(UserSession s) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(s.toJson()));
    await _storage.write(key: 'token', value: s.token);
    await _storage.write(key: 'userId', value: s.id);
    await _storage.write(key: 'userRole', value: s.role);
    await _storage.write(key: 'userName', value: s.fullName);
    await _storage.write(key: 'userEmail', value: s.email);
    await _storage.write(key: 'orgId', value: s.orgId ?? '');
    await _storage.write(key: 'zoneId', value: s.zoneId ?? '');
  }

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    for (final k in legacyKeys) {
      await _storage.delete(key: k);
    }
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

/// The current session, `null` when logged out. Loaded once at startup.
class SessionNotifier extends AsyncNotifier<UserSession?> {
  @override
  Future<UserSession?> build() => ref.read(sessionStoreProvider).read();

  Future<void> setSession(UserSession s) async {
    await ref.read(sessionStoreProvider).write(s);
    state = AsyncData(s);
  }

  Future<void> updateSession(UserSession Function(UserSession) fn) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await setSession(fn(current));
  }

  Future<void> clear() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, UserSession?>(SessionNotifier.new);

/// Convenience: the session value or null while loading / logged out.
final currentUserProvider = Provider<UserSession?>((ref) => ref.watch(sessionProvider).valueOrNull);
