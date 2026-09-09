import 'dart:io';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';
import '../models/manual.dart';

class ManualService {
  ManualService([ApiClient? api, SessionStore? store])
      : _store = store ?? SessionStore(),
        _api = api ?? ApiClient(sessionStore: store ?? SessionStore());

  final ApiClient _api;
  final SessionStore _store;

  /// Manuals for the logged-in user's organisation (`GET /manual/org/{orgId}`).
  Future<List<Manual>> getManuals() async {
    final orgId = (await _store.read())?.orgId ?? '';
    final res = await _api.get(orgId.isEmpty ? '/manual' : '/manual/org/$orgId');
    final items = res.list.map(Manual.fromJson).toList();
    items.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    return items;
  }

  /// The backend has no per-zone route; filter the org list client-side.
  Future<List<Manual>> getManualsByZoneId(String zoneId) async {
    final all = await getManuals();
    return all.where((m) => m.zoneId == zoneId).toList();
  }

  /// `POST /manual` (multipart: orgId, name, createdBy?, file?).
  Future<List<Manual>> uploadManual({
    required String orgId,
    required String zoneId,
    required String zoneName,
    required String name,
    File? file,
  }) async {
    if (file != null) {
      final n = file.path.toLowerCase();
      if (!(n.endsWith('.png') || n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.pdf'))) {
        throw const ApiException(415, 'Unsupported file type. Use PNG, JPG, JPEG or PDF.');
      }
    }
    final createdBy = (await _store.read())?.id;
    final res = await _api.multipart(
      'POST',
      '/manual',
      fields: {
        'orgId': orgId,
        'zoneId': zoneId,
        'name': name.trim(),
        if (createdBy != null) 'createdBy': createdBy,
      },
      files: [if (file != null) ApiFile(field: 'file', path: file.path)],
    );
    return res.list.map(Manual.fromJson).toList();
  }

  Future<void> deleteManual(String manualId) => _api.delete('/manual/$manualId');
}
