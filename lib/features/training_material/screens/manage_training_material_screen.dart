import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/zone.dart';
import '../../../services/zone_service.dart';
import '../../../theme/colors.dart';
import '../providers/training_material_provider.dart';
import '../models/training_material_model.dart';

class ManageTrainingMaterialScreen extends ConsumerStatefulWidget {
  const ManageTrainingMaterialScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageTrainingMaterialScreen> createState() => _ManageTrainingMaterialScreenState();
}

class _ManageTrainingMaterialScreenState extends ConsumerState<ManageTrainingMaterialScreen> {
  final ZoneService _zoneService = ZoneService();
  String? selectedZoneId;
  List<Zone> zones = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadZones();
    Future.microtask(() => ref.read(trainingMaterialsProvider.notifier).loadTrainingMaterials());
  }

  Future<void> _loadZones() async {
    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      zones = await _zoneService.getZonesByOrgId(orgId);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsState = ref.watch(trainingMaterialsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Training Materials'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildZoneDropdown(),
                  const SizedBox(height: 16),
                  _buildHeader(),
                ],
              ),
            ),
            Expanded(
              child: materialsState.when(
                data: (materials) => _buildMaterialList(materials),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadBottomSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }

  Widget _buildZoneDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedZoneId,
          hint: const Text('Select Zone'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Zones'),
            ),
            ...zones.map((zone) => DropdownMenuItem<String>(
              value: zone.id,
              child: Text(zone.zoneName),
            )),
          ],
          onChanged: (value) {
            setState(() {
              selectedZoneId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Training Materials',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'items',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialList(List<TrainingMaterial> materials) {
    return ListView.builder(
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Image.network(
              material.path,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported);
              },
            ),
            title: Text(material.materialType),
            subtitle: Text('Created by: ${material.createdBy}'),
            trailing: Text(
              material.approved ? 'Approved' : 'Pending',
              style: TextStyle(
                color: material.approved ? Colors.green : Colors.orange,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const UploadMaterialSheet(),
    );
  }
}

class UploadMaterialSheet extends ConsumerStatefulWidget {
  const UploadMaterialSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadMaterialSheet> createState() => _UploadMaterialSheetState();
}

class _UploadMaterialSheetState extends ConsumerState<UploadMaterialSheet> {
  File? _selectedFile;
  final _materialTypeController = TextEditingController();
  final String _orgId = '8473993c-1716-4991-9f33-a3ebb4310fbc'; // Replace with actual org ID

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _uploadMaterial() async {
    if (_selectedFile == null || _materialTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and enter material type')),
      );
      return;
    }

    try {
      await ref.read(trainingMaterialsProvider.notifier).uploadTrainingMaterial(
        orgId: _orgId,
        materialType: _materialTypeController.text,
        file: _selectedFile!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training material uploaded successfully')),
        );
        Navigator.pop(context);
        ref.read(trainingMaterialsProvider.notifier).loadTrainingMaterials();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading material: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsState = ref.watch(trainingMaterialsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload Training Material',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _materialTypeController,
            decoration: const InputDecoration(
              labelText: 'Material Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select File'),
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 16),
            Image.file(
              _selectedFile!,
              height: 200,
              fit: BoxFit.cover,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: materialsState.isLoading ? null : _uploadMaterial,
            child: materialsState.isLoading
                ? const CircularProgressIndicator()
                : const Text('Upload Material'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _materialTypeController.dispose();
    super.dispose();
  }
} 