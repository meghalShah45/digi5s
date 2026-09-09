import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';
import '../models/red_tag.dart';

class RedTagService {
  RedTagService([ApiClient? api]) : _api = api ?? ApiClient(sessionStore: SessionStore());
  final ApiClient _api;

  /// `POST /redtags` (multipart). The file is optional on the backend.
  Future<Map<String, dynamic>> createRedTag({
    required String orgId,
    required String zoneId,
    required String redTagBy,
    required String description,
    String remarks = '',
    File? file,
    required String createdBy,
  }) async {
    try {
      final res = await _api.multipart(
        'POST',
        '/redtags',
        fields: {
          'orgId': orgId,
          'zoneId': zoneId,
          'redTagBy': redTagBy,
          'description': description.trim(),
          'createdBy': createdBy,
        },
        files: [if (file != null) ApiFile(field: 'file', path: file.path)],
      );
      return {'success': true, 'data': res.data, 'message': res.message};
    } on ApiException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': 'Could not create the red tag.'};
    }
  }

  /// `GET /redtags/org/{orgId}` newest first.
  Future<List<RedTag>> getRedTags(String orgId) async {
    if (orgId.isEmpty) return const [];
    final res = await _api.get('/redtags/org/$orgId');
    final items = res.list.map(RedTag.fromJson).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// `GET /redtags/{id}` — raw row without the joined email / zoneName.
  Future<RedTag?> getRedTagById(String id) async {
    final res = await _api.get('/redtags/$id');
    final m = res.map;
    return m.isEmpty ? null : RedTag.fromJson(m);
  }

  /// `GET /redtags/pending/{orgId}?adminUserId=` — org-admin gated on the server.
  Future<List<RedTag>> getPendingRedTags({required String orgId, required String adminUserId}) async {
    final res = await _api.get('/redtags/pending/$orgId', query: {'adminUserId': adminUserId});
    return res.list.map(RedTag.fromJson).toList();
  }

  /// `POST /redtags/approve/{id}` — APPROVE or REJECT a PENDING red tag.
  Future<RedTag?> approveRedTag({
    required String id,
    required bool approve,
    required String remarks,
    required String adminUserId,
  }) async {
    final res = await _api.post('/redtags/approve/$id', body: {
      'action': approve ? 'APPROVE' : 'REJECT',
      'approvalRemarks': remarks.trim().isEmpty ? (approve ? 'Approved' : 'Rejected') : remarks.trim(),
      'adminUserId': adminUserId,
    });
    final m = res.map;
    return m.isEmpty ? null : RedTag.fromJson(m);
  }

  /// Legacy status path: COMPLETED / VERIFY / REJECTED with an activity note.
  Future<void> updateRedTagStatus(String redTagId, String newStatus, String activity, String actionBy) async {
    await _api.put('/redtags/status/$redTagId', body: {
      'status': newStatus,
      'activity': activity,
      'actionBy': actionBy,
    });
  }

  /// Returns a human-readable message; never throws.
  Future<String?> deleteRedTag(String redTagId) async {
    try {
      await _api.delete('/redtags/$redTagId');
      return 'Red tag deleted successfully';
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to delete red tag';
    }
  }

  Future<void> updateRedTag(
    String redTagId, {
    required String description,
    String? path,
    String? status,
    String? remarks,
    required String modifiedBy,
  }) async {
    await _api.put('/redtags/$redTagId', body: {
      'description': description.trim(),
      if (path != null) 'path': path,
      if (status != null) 'status': status,
      'modifiedBy': modifiedBy,
    });
  }
}

final redTagServiceProvider = Provider((ref) => RedTagService(ref.read(apiClientProvider)));

/// Red tags for the current user's org; zone roles see only their zone.
final orgRedTagsProvider = FutureProvider.autoDispose<List<RedTag>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final orgId = user?.orgId;
  if (user == null || orgId == null || orgId.isEmpty) return const [];
  final all = await ref.read(redTagServiceProvider).getRedTags(orgId);
  if ((user.isZoneMember || user.isZoneLeader) && (user.zoneId ?? '').isNotEmpty) {
    return all.where((t) => t.zoneId == user.zoneId).toList();
  }
  return all;
});

final redTagByIdProvider = FutureProvider.autoDispose.family<RedTag?, String>((ref, id) async {
  // Prefer the joined org list (has email + zoneName); fall back to the raw row.
  final list = ref.watch(orgRedTagsProvider).valueOrNull;
  final fromList = list?.where((t) => t.id == id).firstOrNull;
  if (fromList != null) return fromList;
  return ref.read(redTagServiceProvider).getRedTagById(id);
});
