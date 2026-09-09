import 'dart:io';

import '../../../core/api/api_client.dart';
import '../models/training_material_model.dart';

class TrainingMaterialService {
  TrainingMaterialService(this._api);
  final ApiClient _api;

  /// Materials for one organisation (`GET /training-material/org/{orgId}`).
  Future<List<TrainingMaterial>> getTrainingMaterialsForOrg(String orgId) async {
    final res = await _api.get('/training-material/org/$orgId');
    final items = res.list.map(TrainingMaterial.fromJson).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Every material system-wide. Only meaningful for the super admin.
  Future<List<TrainingMaterial>> getTrainingMaterials() async {
    final res = await _api.get('/training-material');
    return res.list.map(TrainingMaterial.fromJson).toList();
  }

  Future<Map<String, dynamic>> uploadTrainingMaterial({
    required String orgId,
    required String materialType,
    required File file,
    required String zoneId,
    required String name,
    String? createdBy,
  }) async {
    final res = await _api.multipart(
      'POST',
      '/training-material',
      fields: {
        'orgId': orgId,
        'zoneId': zoneId,
        'materialType': materialType,
        'name': name.trim(),
        if (createdBy != null) 'createdBy': createdBy,
      },
      files: [ApiFile(field: 'file', path: file.path)],
    );
    return {
      'success': true,
      'message': res.message,
      'materials': res.list.map(TrainingMaterial.fromJson).toList(),
    };
  }

  Future<Map<String, dynamic>> updateTrainingMaterial({
    required String id,
    required String materialType,
    required String name,
    required String zoneId,
    File? file,
    bool? approved,
  }) async {
    final res = await _api.multipart(
      'PUT',
      '/training-material/$id',
      fields: {
        'materialType': materialType,
        'name': name.trim(),
        'zoneId': zoneId,
        if (approved != null) 'approved': approved.toString(),
      },
      files: [if (file != null) ApiFile(field: 'file', path: file.path)],
    );
    return {
      'success': true,
      'message': res.message,
      'materials': res.list.map(TrainingMaterial.fromJson).toList(),
    };
  }

  Future<void> deleteTrainingMaterial(String id) => _api.delete('/training-material/$id');
}
