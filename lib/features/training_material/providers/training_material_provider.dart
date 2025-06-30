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
      
      // Check if the result contains the updated list
      if (result['materials'] != null) {
        state = result['materials'];
      }
      
      return {
        'success': true,
        'message': result['message'] ?? 'Training material uploaded successfully',
        'materials': result['materials'],
      };
    } catch (e) {
      _error = e.toString();
      return {
        'success': false,
        'message': e.toString(),
        'materials': null,
      };
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
    // try {
      _isLoading = true;
      _error = null;
      final result = await _service.updateTrainingMaterial(
        id: id,
        materialType: materialType,
        file: path!,
        approved: approved,
        name: name!,
        zoneId: zoneId!,
      );
      
      // Check if the result contains the updated list
      if (result['materials'] != null) {
        state = result['materials'];
      }
      
      return {
        'success': true,
        'message': result['message'] ?? 'Training material updated successfully',
        'materials': result['materials'],
      };
    // } catch (e) {
    //   _error = e.toString();
    //   return {
    //     'success': false,
    //     'message': e.toString(),
    //     'materials': null,
    //   };
    // } finally {
    //   _isLoading = false;
    // }
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