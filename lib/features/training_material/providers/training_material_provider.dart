import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_material_model.dart';
import '../services/training_material_service.dart';

final trainingMaterialServiceProvider = Provider((ref) => TrainingMaterialService());

final trainingMaterialsProvider = StateNotifierProvider<TrainingMaterialsNotifier, AsyncValue<List<TrainingMaterial>>>((ref) {
  return TrainingMaterialsNotifier(ref.watch(trainingMaterialServiceProvider));
});

class TrainingMaterialsNotifier extends StateNotifier<AsyncValue<List<TrainingMaterial>>> {
  final TrainingMaterialService _service;

  TrainingMaterialsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTrainingMaterials();
  }

  Future<void> loadTrainingMaterials() async {
    try {
      state = const AsyncValue.loading();
      final materials = await _service.getTrainingMaterials();
      state = AsyncValue.data(materials);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> uploadTrainingMaterial({
    required String orgId,
    required String materialType,
    required File file,
  }) async {
    try {
      state = const AsyncValue.loading();
      final materials = await _service.uploadTrainingMaterial(
        orgId: orgId,
        materialType: materialType,
        file: file,
      );
      state = AsyncValue.data(materials);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
} 