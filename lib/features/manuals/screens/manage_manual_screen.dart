import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/zone.dart';
import '../../../theme/colors.dart';
import '../../../services/zone_service.dart';
import '../models/manual.dart';
import '../services/manual_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManageManualScreen extends StatefulWidget {
  const ManageManualScreen({Key? key}) : super(key: key);

  @override
  State<ManageManualScreen> createState() => _ManageManualScreenState();
}

class _ManageManualScreenState extends State<ManageManualScreen> {
  final ZoneService _zoneService = ZoneService();
  final ManualService _manualService = ManualService();
  String? selectedZoneId;
  List<Zone> zones = [];
  List<Manual> manuals = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadZones();
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

  Future<void> _loadManuals() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      if (selectedZoneId != null) {
        manuals = await _manualService.getManualsByZoneId(selectedZoneId!);
      } else {
        manuals = await _manualService.getManuals();
      }

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Manage Manuals',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Column(
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
              child: _buildManualList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadManualSheet(context),
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
            _loadManuals();
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
          'Manuals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${manuals.length} items',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildManualList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadManuals,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (manuals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              selectedZoneId == null
                  ? 'No manuals found'
                  : 'No manuals found for selected zone',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadManuals,
      child: ListView.builder(
        itemCount: manuals.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final manual = manuals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manual.name!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   'Zone: ${manual.zoneName}',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Created by: ${manual.createdBy}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //   decoration: BoxDecoration(
                      //     color: manual.approved ?? true ? AppColors.success : AppColors.warning,
                      //     borderRadius: BorderRadius.circular(4),
                      //   ),
                      //   child: Text(
                      //     manual.approved ?? true ? 'Approved' : 'Pending',
                      //     style: TextStyle(
                      //       color: manual.approved ?? true ? Colors.white : Colors.black,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w500,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created at: ${_formatDate(DateTime.parse(manual.createdAt!))}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.download),
                  //   onPressed: () => _downloadManual(manual),
                  // ),
                  // IconButton(
                  //   icon: const Icon(Icons.edit),
                  //   onPressed: () => _showEditManualSheet(context, manual),
                  // ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteManualSheet(context, manual),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showUploadManualSheet(BuildContext context) async {
    final nameController = TextEditingController();
    String? selectedZoneIdInModal = selectedZoneId; // Initialize with current selection
    File? selectedFile;
    final ImagePicker picker = ImagePicker();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upload Manual',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Manual Name',
                          hintText: 'Enter manual name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedZoneIdInModal,
                            hint: const Text('Select Zone'),
                            isExpanded: true,
                            items: zones.map((zone) => DropdownMenuItem<String>(
                                  value: zone.id,
                                  child: Text(zone.zoneName),
                                )).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                selectedZoneIdInModal = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Supported file types: PNG, JPG, JPEG, PDF',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              requestFullMetadata: false,
                            );
                            
                            if (image != null) {
                              final fileName = image.path.split('/').last.toLowerCase();
                              if (fileName.endsWith('.png') || 
                                  fileName.endsWith('.jpg') || 
                                  fileName.endsWith('.jpeg')) {
                                setModalState(() {
                                  selectedFile = File(image.path);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select PNG, JPG, or JPEG files. For PDF files, please use the file manager.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error selecting file: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: Text(selectedFile != null ? 'File Selected' : 'Select Image (PNG/JPG)'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Text(
                      //   'Note: For PDF files, please use your device\'s file manager to copy the file to a supported location, then select it here.',
                      //   style: TextStyle(
                      //     color: Colors.orange[700],
                      //     fontSize: 11,
                      //     fontStyle: FontStyle.italic,
                      //   ),
                      // ),
                      if (selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected file: ${selectedFile!.path.split('/').last}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a manual name'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (selectedZoneIdInModal == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a zone'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            final storage = const FlutterSecureStorage();
                            final orgId = await storage.read(key: 'orgId') ?? '';
                            
                            final selectedZone = zones.firstWhere((zone) => zone.id == selectedZoneIdInModal);
                            
                            final uploadedManuals = await _manualService.uploadManual(
                              orgId: orgId,
                              zoneId: selectedZone.id,
                              zoneName: selectedZone.zoneName,
                              name: nameController.text,
                              file: selectedFile,
                            );

                            setState(() {
                              manuals.addAll(uploadedManuals);
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Manual uploaded successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error uploading manual: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Upload', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditManualSheet(BuildContext context, Manual manual) async {
    final nameController = TextEditingController(text: manual.name);
    final descriptionController = TextEditingController(text: manual.id);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Manual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Manual Name',
                        hintText: 'Enter manual name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter manual description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          final index = manuals.indexWhere((m) => m.id == manual.id);
                          // if (index != -1) {
                          //   manuals[index] = manual.copyWith(
                          //     name: nameController.text,
                          //     description: descriptionController.text.isEmpty ? null : descriptionController.text,
                          //     lastUpdated: DateTime.now(),
                          //     version: manual.version + 1,
                          //   );
                          // }
                        });

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteManualSheet(BuildContext context, Manual manual) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Manual',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${manual.name}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _manualService.deleteManual(manual.id!);
                        
                        setState(() {
                          manuals.removeWhere((m) => m.id == manual.id);
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Manual deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting manual: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadManual(Manual manual) async {
    // TODO: Implement download logic
  }
} 