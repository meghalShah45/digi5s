import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/zone.dart';
import '../../../services/zone_service.dart';
import '../../../theme/colors.dart';
import '../../../providers/user_provider.dart';
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
    Future.microtask(() {
      if (mounted) {
        ref.read(trainingMaterialsProvider.notifier).loadTrainingMaterials();
      }
    });
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
    final materials = ref.watch(trainingMaterialsProvider);
    final notifier = ref.watch(trainingMaterialsProvider.notifier);
    final userInfo = ref.watch(userProvider);
    final isZoneMember = userInfo?.isZoneMember ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(isZoneMember ? 'View Training Materials' : 'Training Materials'),
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
                  if (!isZoneMember) ...[
                    _buildZoneDropdown(),
                    const SizedBox(height: 16),
                  ],
                  _buildHeader(),
                ],
              ),
            ),
            Expanded(
              child: notifier.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notifier.error != null
                      ? Center(child: Text('Error: ${notifier.error}'))
                      : _buildMaterialList(materials, isZoneMember),
            ),
          ],
        ),
      ),
      floatingActionButton: isZoneMember ? null : FloatingActionButton(
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
    final materials = ref.watch(trainingMaterialsProvider);
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
          '${materials.length} items',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialList(List<TrainingMaterial> materials, bool isZoneMember) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70.0),
      child: ListView.builder(
        itemCount: materials.length,
        itemBuilder: (context, index) {
          final material = materials[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: material.path != null && material.path!.isNotEmpty
                  ? Image.network(
                      material.path!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported);
                      },
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
              title: Text(material.name ?? 'No Name'),
              subtitle: Text('Type: ${material.materialType ?? 'N/A'} • Created by: ${material.createdBy ?? 'N/A'}'),
              trailing: isZoneMember ? null : PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditBottomSheet(context, material);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Material'),
                        content: const Text('Are you sure you want to delete this material?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        // Perform the deletion
                        await ref.read(trainingMaterialsProvider.notifier).deleteTrainingMaterial(material.id);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Material deleted successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting material: $e')),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UploadMaterialSheet(selectedZoneId: selectedZoneId),
    );
  }

  void _showEditBottomSheet(BuildContext context, TrainingMaterial material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditMaterialSheet(material: material),
    );
  }
}

class UploadMaterialSheet extends ConsumerStatefulWidget {
  final String? selectedZoneId;
  
  const UploadMaterialSheet({
    Key? key,
    this.selectedZoneId,
  }) : super(key: key);

  @override
  ConsumerState<UploadMaterialSheet> createState() => _UploadMaterialSheetState();
}

class _UploadMaterialSheetState extends ConsumerState<UploadMaterialSheet> {
  File? _selectedFile;
  final _materialTypeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedZoneId;
  List<Zone> _zones = [];
  bool _isLoadingZones = true;
  final storage = const FlutterSecureStorage();
  late String _orgId = '';

  @override
  void initState() {
    super.initState();
    _selectedZoneId = widget.selectedZoneId;
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      _orgId = await storage.read(key: 'orgId') ?? '';
      final zoneService = ZoneService();
      final zones = await zoneService.getZonesByOrgId(_orgId);
      if (mounted) {
        setState(() {
          _zones = zones;
          _isLoadingZones = false;
          // Set default selected zone if not set and zones are available
          if (_selectedZoneId == null && _zones.isNotEmpty) {
            _selectedZoneId = _zones.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingZones = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading zones: $e')),
        );
      }
    }
  }

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
    if (_selectedFile == null || 
        _materialTypeController.text.isEmpty || 
        _selectedZoneId == null ||
        _nameController.text.isEmpty) {
      // Show error in a more visible way since SnackBar gets covered by bottom sheet
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please fill in all required fields: file, material type, zone, and name'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final result = await ref.read(trainingMaterialsProvider.notifier).uploadTrainingMaterial(
        orgId: _orgId,
        materialType: _materialTypeController.text,
        file: _selectedFile!,
        zoneId: _selectedZoneId!,
        name: _nameController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Show success message from server
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(result['message'] ?? 'Training material uploaded successfully'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close bottom sheet
                    ref.read(trainingMaterialsProvider.notifier).loadTrainingMaterials();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show error message from server in Scaffold
          Navigator.pop(context); // Close bottom sheet first
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to upload training material'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(trainingMaterialsProvider.notifier);

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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingZones)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedZoneId,
                  hint: const Text('Select Zone'),
                  isExpanded: true,
                  items: _zones.map((zone) => DropdownMenuItem<String>(
                    value: zone.id,
                    child: Text(zone.zoneName),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedZoneId = value;
                    });
                  },
                ),
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
            onPressed: (notifier.isLoading || _isLoadingZones) ? null : _uploadMaterial,
            child: notifier.isLoading
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
    _nameController.dispose();
    super.dispose();
  }
}

class EditMaterialSheet extends ConsumerStatefulWidget {
  final TrainingMaterial material;

  const EditMaterialSheet({
    Key? key,
    required this.material,
  }) : super(key: key);

  @override
  ConsumerState<EditMaterialSheet> createState() => _EditMaterialSheetState();
}

class _EditMaterialSheetState extends ConsumerState<EditMaterialSheet> {
  File? _selectedFile;
  late final TextEditingController _materialTypeController;
  late final TextEditingController _nameController;
  String? _selectedZoneId;
  List<Zone> _zones = [];
  bool _isLoadingZones = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _materialTypeController = TextEditingController(text: widget.material.materialType);
    _nameController = TextEditingController(text: widget.material.name);
    _selectedZoneId = widget.material.zoneId;
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      final zoneService = ZoneService();
      final zones = await zoneService.getZonesByOrgId(orgId);
      if (mounted) {
        setState(() {
          _zones = zones;
          _isLoadingZones = false;
          // Set default selected zone if not set and zones are available
          if (_selectedZoneId == null && _zones.isNotEmpty) {
            _selectedZoneId = _zones.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingZones = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading zones: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _updateMaterial() async {
    if (_materialTypeController.text.isEmpty || _nameController.text.isEmpty || _selectedZoneId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please fill in all required fields: name, material type, and zone'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_selectedZoneId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a zone.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final result = await ref.read(trainingMaterialsProvider.notifier).updateTrainingMaterial(
        id: widget.material.id,
        materialType: _materialTypeController.text,
        name: _nameController.text,
        zoneId: _selectedZoneId!,
        path: _selectedFile,
        approved: true
      );
      if (mounted) {
        if (result['success'] == true) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(result['message'] ?? 'Training material updated successfully'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close bottom sheet
                    ref.read(trainingMaterialsProvider.notifier).loadTrainingMaterials();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          Navigator.pop(context); // Close bottom sheet first
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update training material'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Training Material',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Read-only info fields
            Text('Org ID: \\${widget.material.orgId}'),
            Text('Created By: \\${widget.material.createdBy}'),
            Text('Created At: \\${widget.material.createdAt}'),
            Text('Modified By: \\${widget.material.modifiedBy ?? "-"}'),
            Text('Modified At: \\${widget.material.modifiedAt}'),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isLoadingZones
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedZoneId,
                        hint: const Text('Select Zone'),
                        isExpanded: true,
                        items: _zones.map((zone) => DropdownMenuItem<String>(
                          value: zone.id,
                          child: Text(zone.zoneName),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedZoneId = value;
                          });
                        },
                      ),
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
            const Text('Current Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.material.path != null
                  ? Image.network(
                      widget.material.path!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No image available', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Change Image'),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              const Text('New Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _updateMaterial,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Update Material'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _materialTypeController.dispose();
    _nameController.dispose();
    super.dispose();
  }
} 