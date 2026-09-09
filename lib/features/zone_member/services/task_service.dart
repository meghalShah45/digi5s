import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';
import '../models/task.dart';

class TaskService {
  TaskService([ApiClient? api, SessionStore? store])
      : _store = store ?? SessionStore(),
        _api = api ?? ApiClient(sessionStore: store ?? SessionStore());

  final ApiClient _api;
  final SessionStore _store;

  Future<UserSession> _requireSession() async {
    final s = await _store.read();
    if (s == null) throw const ApiException(401, 'Please log in again.');
    return s;
  }

  /// Tasks assigned to the logged-in user (`POST /tasks/detailsByUserId`).
  Future<List<Task>> getTasksByUserId() async {
    final s = await _requireSession();
    final orgId = s.orgId ?? '';
    if (orgId.isEmpty) throw const ApiException(400, 'Your account is not linked to an organisation.');
    final res = await _api.post('/tasks/detailsByUserId', body: {'orgId': orgId, 'userId': s.id});
    return _sorted(res.list.map(Task.fromJson).toList());
  }

  /// All approved tasks for an organisation (`GET /tasks/org/{orgId}`).
  Future<List<Task>> getTasksForOrg(String orgId, {String? zoneId}) async {
    final res = await _api.get('/tasks/org/$orgId');
    var tasks = res.list.map(Task.fromJson).toList();
    if (zoneId != null && zoneId.isNotEmpty) tasks = tasks.where((t) => t.zoneId == zoneId).toList();
    return _sorted(tasks);
  }

  Future<Task?> getTask(String id) async {
    final res = await _api.get('/tasks/$id');
    final m = res.map;
    return m.isEmpty ? null : Task.fromJson(m);
  }

  /// `POST /tasks` (multipart) — assign a task to a zone member.
  Future<Task?> createTask({
    required String taskName,
    String? description,
    required String zoneMemberId,
    required String orgId,
    required String zoneId,
    DateTime? targetDate,
    required String createdBy,
    File? file,
  }) async {
    final res = await _api.multipart(
      'POST',
      '/tasks',
      fields: {
        'taskName': taskName.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        'zoneMemberId': zoneMemberId,
        'orgId': orgId,
        'zoneId': zoneId,
        if (targetDate != null) 'targetDate': targetDate.toIso8601String().split('T').first,
        'createdBy': createdBy,
      },
      files: [if (file != null) ApiFile(field: 'file', path: file.path)],
    );
    final m = res.map;
    return m.isEmpty ? null : Task.fromJson(m);
  }

  /// `PUT /tasks/status/{id}` — WORK-IN-PROGRESS / VERIFY / REJECTED.
  Future<void> updateStatus(String taskId, {required String status, required String activity}) async {
    await _api.put('/tasks/status/$taskId', body: {'status': status, 'activity': activity});
  }

  /// Member marks work done and asks the zone leader to approve
  /// (`POST /tasks/request-approval/{id}`). Photos optional.
  Future<void> requestApproval(String taskId, {String? remarks, List<File> photos = const []}) async {
    await _api.multipart(
      'POST',
      '/tasks/request-approval/$taskId',
      fields: {
        'activity': remarks == null || remarks.trim().isEmpty ? 'Task completed, approval requested' : remarks.trim(),
        if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      },
      files: [for (final f in photos) ApiFile(field: 'photos', path: f.path)],
    );
  }

  /// Kept for older screens; same as [requestApproval] without photos.
  Future<void> markTaskAsCompleted(String taskId) => requestApproval(taskId, remarks: 'Task Approve Request');

  /// Zone leader decision (`POST /tasks/approve/{id}`).
  Future<void> approve(String taskId, {required bool approve, required String remarks}) async {
    await _api.post('/tasks/approve/$taskId', body: {
      'action': approve ? 'APPROVE' : 'REJECT',
      'remarks': remarks.trim().isEmpty ? (approve ? 'Approved' : 'Rejected') : remarks.trim(),
    });
  }

  Future<void> deleteTask(String taskId) => _api.delete('/tasks/$taskId');

  List<Task> _sorted(List<Task> tasks) {
    tasks.sort((a, b) => (b.createdDateTime ?? DateTime(0)).compareTo(a.createdDateTime ?? DateTime(0)));
    return tasks;
  }
}

final taskServiceProvider =
    Provider((ref) => TaskService(ref.read(apiClientProvider), ref.read(sessionStoreProvider)));

/// The logged-in user's own tasks.
final myTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) {
  ref.watch(currentUserProvider); // refetch on login change
  return ref.read(taskServiceProvider).getTasksByUserId();
});

/// Tasks for the user's org; zone leaders see only their zone.
final orgTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final orgId = user?.orgId;
  if (user == null || orgId == null || orgId.isEmpty) return const [];
  return ref.read(taskServiceProvider).getTasksForOrg(orgId, zoneId: user.isZoneLeader ? user.zoneId : null);
});
