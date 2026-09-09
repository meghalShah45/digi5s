import 'dart:io';

import '../core/api/api_client.dart';
import '../core/auth/session.dart';

/// Organisation members (users) and roles.
class MemberService {
  MemberService([ApiClient? api]) : _api = api ?? ApiClient(sessionStore: SessionStore());
  final ApiClient _api;

  /// `POST /users/organisation-members` (multipart). Returns the raw envelope.
  Future<Map<String, dynamic>> createOrganizationMember({
    required String orgId,
    required String zoneId,
    required String roleId,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String designation,
    required String signupType,
    required String role,
    File? file,
  }) async {
    try {
      final res = await _api.multipart(
        'POST',
        '/users/organisation-members',
        fields: {
          'orgId': orgId,
          'zoneId': zoneId,
          'roleId': roleId,
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'phoneNumber': phoneNumber.trim(),
          'designation': designation.trim(),
          'signupType': signupType,
          'role': role,
        },
        files: [if (file != null) ApiFile(field: 'file', path: file.path)],
      );
      return res.raw;
    } on ApiException catch (e) {
      // Callers show the thrown string directly.
      throw e.message;
    }
  }

  /// `POST /users/org/zone` — members of one zone. Returns the raw envelope
  /// (`data` is a list of user rows).
  Future<Map<String, dynamic>> getZoneMembers({required String orgId, required String zoneId}) async {
    try {
      final res = await _api.post('/users/org/zone', body: {'orgId': orgId, 'zoneId': zoneId});
      return res.raw;
    } on ApiException catch (e) {
      if (e.isNotFound) return {'statusCode': 404, 'message': e.message, 'data': []};
      rethrow;
    }
  }

  /// `GET /users/org/{orgId}` — approved members with a zone:
  /// `{ id, fullName, photo, role, zoneName }`.
  Future<List<Map<String, dynamic>>> getOrgMembers(String orgId) async {
    final res = await _api.get('/users/org/$orgId');
    return res.list;
  }

  /// `GET /organisations/members/{orgId}` — every user row of the org.
  Future<List<Map<String, dynamic>>> getAllOrgUsers(String orgId) async {
    final res = await _api.get('/organisations/members/$orgId');
    return res.list;
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final res = await _api.get('/users/$userId');
    final m = res.map;
    return m.isEmpty ? null : m;
  }

  /// `PUT /users/organisation-members/inactive/{id}` — enable / disable login.
  Future<void> setMemberApproved(String userId, bool approved) async {
    await _api.put('/users/organisation-members/inactive/$userId', body: {'approved': approved});
  }

  /// `POST /users/{id}/reset-password` — server generates and emails a new
  /// password and returns it in `data.newPassword`.
  Future<String?> resetMemberPassword(String userId) async {
    final res = await _api.post('/users/$userId/reset-password');
    return res.map['newPassword']?.toString();
  }

  Future<void> deleteUser(String userId) => _api.delete('/users/$userId');

  /// `GET /roles`.
  Future<List<Map<String, dynamic>>> getRoles() async {
    final res = await _api.get('/roles');
    return res.list;
  }
}
