import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';
import '../models/training_material_model.dart';
import '../services/training_material_service.dart';

final trainingMaterialServiceProvider =
    Provider((ref) => TrainingMaterialService(ref.read(apiClientProvider)));

/// Training materials for the current user's organisation.
final trainingMaterialsProvider =
    StateNotifierProvider<TrainingMaterialsNotifier, List<TrainingMaterial>>((ref) {
  final orgId = ref.watch(currentUserProvider.select((u) => u?.orgId));
  return TrainingMaterialsNotifier(ref.watch(trainingMaterialServiceProvider), orgId);
});

class TrainingMaterialsNotifier extends StateNotifier<List<TrainingMaterial>> {
  final TrainingMaterialService _service;
  final String? _orgId;
  bool _isLoading = false;
  String? _error;

  TrainingMaterialsNotifier(this._service, this._orgId) : super([]) {
    loadTrainingMaterials();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrainingMaterials() async {
    final orgId = _orgId;
    if (orgId == null || orgId.isEmpty) {
      _error = 'Your account is not linked to an organisation.';
      state = [];
      return;
    }
    try {
      _isLoading = true;
      _error = null;
      state = await _service.getTrainingMaterialsForOrg(orgId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not load training materials.';
    } finally {
      _isLoading = false;
      // Force a rebuild for listeners even when the list did not change.
      state = [...state];
    }
  }

  Future<Map<String, dynamic>> uploadTrainingMaterial({
    required String orgId,
    required String materialType,
    required File file,
    required String zoneId,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      final result = await _service.uploadTrainingMaterial(
        orgId: orgId,
        materialType: materialType,
        file: file,
        zoneId: zoneId,
        name: name,
      );
      await loadTrainingMaterials();
      return {'success': true, 'message': result['message'], 'materials': state};
    } on ApiException catch (e) {
      _error = e.message;
      return {'success': false, 'message': e.message, 'materials': null};
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'message': 'Upload failed. Please try again.', 'materials': null};
    } finally {
      _isLoading = false;
    }
  }

  Future<Map<String, dynamic>> updateTrainingMaterial({
    required String id,
    required String materialType,
    File? path,
    required bool approved,
    String? name,
    String? zoneId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      final result = await _service.updateTrainingMaterial(
        id: id,
        materialType: materialType,
        file: path,
        approved: approved,
        name: name ?? '',
        zoneId: zoneId ?? '',
      );
      await loadTrainingMaterials();
      return {'success': true, 'message': result['message'], 'materials': state};
    } on ApiException catch (e) {
      _error = e.message;
      return {'success': false, 'message': e.message, 'materials': null};
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'message': 'Update failed. Please try again.', 'materials': null};
    } finally {
      _isLoading = false;
    }
  }

  Future<void> deleteTrainingMaterial(String id) async {
    try {
      _isLoading = true;
      _error = null;
      await _service.deleteTrainingMaterial(id);
      state = state.where((m) => m.id != id).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Delete failed. Please try again.';
    } finally {
      _isLoading = false;
    }
  }
}
