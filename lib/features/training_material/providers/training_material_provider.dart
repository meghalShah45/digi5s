import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_material_model.dart';
import '../services/training_material_service.dart';

final trainingMaterialServiceProvider = Provider((ref) => TrainingMaterialService());

final trainingMaterialsProvider = StateNotifierProvider<TrainingMaterialsNotifier, List<TrainingMaterial>>((ref) {
  return TrainingMaterialsNotifier(ref.watch(trainingMaterialServiceProvider));
});

class TrainingMaterialsNotifier extends StateNotifier<List<TrainingMaterial>> {
  final TrainingMaterialService _service;
  bool _isLoading = false;
  String? _error;

  TrainingMaterialsNotifier(this._service) : super([]) {
    loadTrainingMaterials();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrainingMaterials() async {
    try {
      _isLoading = true;
      _error = null;
      final materials = await _service.getTrainingMaterials();
      state = materials;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> uploadTrainingMaterial({
    required String orgId,
    required String materialType,
    required File file,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      final materials = await _service.uploadTrainingMaterial(
        orgId: orgId,
        materialType: materialType,
        file: file,
      );
      state = materials;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateTrainingMaterial({
    required String id,
    required String materialType,
    required String path,
    required bool approved,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      final materials = await _service.updateTrainingMaterial(
        id: id,
        materialType: materialType,
        path: path,
        approved: approved,
      );
      state = materials;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> deleteTrainingMaterial(String id) async {
    try {
      _isLoading = true;
      _error = null;
      final materials = await _service.deleteTrainingMaterial(id);
      state = materials;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }
} 