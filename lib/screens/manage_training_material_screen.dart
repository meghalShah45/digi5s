import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../theme/colors.dart';

class TrainingMaterial {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final DateTime dateCreated;
  final DateTime? lastUpdated;
  final String createdById;
  final String zoneId;

  TrainingMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.dateCreated,
    this.lastUpdated,
    required this.createdById,
    required this.zoneId,
  });

  TrainingMaterial copyWith({
    String? title,
    String? description,
    String? fileUrl,
    String? fileType,
    String? zoneId,
  }) {
    return TrainingMaterial(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      dateCreated: dateCreated,
      lastUpdated: DateTime.now(),
      createdById: createdById,
      zoneId: zoneId ?? this.zoneId,
    );
  }
}

class ManageTrainingMaterialScreen extends StatefulWidget {
  const ManageTrainingMaterialScreen({Key? key}) : super(key: key);

  @override
  State<ManageTrainingMaterialScreen> createState() => _ManageTrainingMaterialScreenState();
}

class _ManageTrainingMaterialScreenState extends State<ManageTrainingMaterialScreen> {
  String? selectedZoneId;
  
  // Temporary list for demonstration
  List<Zone> zones = [
    Zone(
      id: '1',
      name: 'Zone A',
      description: 'Production Area',
      memberIds: ['1', '2', '3'],
      leaderId: '1',
    ),
    Zone(
      id: '2',
      name: 'Zone B',
      description: 'Warehouse',
      memberIds: ['4', '5', '6'],
      leaderId: '4',
    ),
  ];

  List<TrainingMaterial> materials = [
    TrainingMaterial(
      id: '1',
      title: 'Safety Guidelines 2024',
      description: 'Comprehensive safety guidelines for production area',
      fileUrl: 'assets/docs/safety_guidelines.pdf',
      fileType: 'PDF',
      dateCreated: DateTime.now(),
      createdById: '1',
      zoneId: '1',
    ),
    TrainingMaterial(
      id: '2',
      title: 'Equipment Manual',
      description: 'Detailed manual for warehouse equipment',
      fileUrl: 'assets/docs/equipment_manual.pdf',
      fileType: 'PDF',
      dateCreated: DateTime.now().subtract(const Duration(days: 1)),
      createdById: '1',
      zoneId: '2',
    ),
  ];

  List<TrainingMaterial> get filteredMaterials {
    if (selectedZoneId == null) return materials;
    return materials.where((material) => material.zoneId == selectedZoneId).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              child: _buildMaterialsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedZoneId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a zone first'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _showAddMaterialFlow(context);
        },
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
                  child: Text(zone.name),
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
          '${filteredMaterials.length} items',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsList() {
    if (filteredMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              selectedZoneId == null
                  ? 'No training materials found'
                  : 'No training materials found for selected zone',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMaterials.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final material = filteredMaterials[index];
        final zone = zones.firstWhere((z) => z.id == material.zoneId);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              material.fileType == 'PDF' ? Icons.picture_as_pdf : Icons.insert_drive_file,
              size: 40,
              color: AppColors.primary,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  zone.name,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(material.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Updated: ${_formatDate(material.lastUpdated ?? material.dateCreated)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditMaterialFlow(context, material);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, material);
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddMaterialFlow(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMaterialSheet(selectedZoneId: selectedZoneId!),
    );

    if (result != null) {
      setState(() {
        materials.add(TrainingMaterial(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] ?? '',
          description: result['description'] ?? '',
          fileUrl: result['fileUrl'] ?? '',
          fileType: result['fileType'] ?? 'PDF',
          dateCreated: DateTime.now(),
          createdById: '1', // TODO: Replace with actual user ID
          zoneId: selectedZoneId!,
        ));
      });
    }
  }

  Future<void> _showEditMaterialFlow(BuildContext context, TrainingMaterial material) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMaterialSheet(
        selectedZoneId: material.zoneId,
        initialTitle: material.title,
        initialDescription: material.description,
        initialFileUrl: material.fileUrl,
        initialFileType: material.fileType,
        isEditing: true,
      ),
    );

    if (result != null) {
      setState(() {
        final index = materials.indexWhere((item) => item.id == material.id);
        if (index != -1) {
          materials[index] = material.copyWith(
            title: result['title'],
            description: result['description'],
            fileUrl: result['fileUrl'],
            fileType: result['fileType'],
            zoneId: result['zoneId'],
          );
        }
      });
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, TrainingMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training Material'),
        content: const Text('Are you sure you want to delete this training material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        materials.removeWhere((item) => item.id == material.id);
      });
    }
  }
}

class AddMaterialSheet extends StatefulWidget {
  final String selectedZoneId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialFileUrl;
  final String? initialFileType;
  final bool isEditing;

  const AddMaterialSheet({
    Key? key,
    required this.selectedZoneId,
    this.initialTitle,
    this.initialDescription,
    this.initialFileUrl,
    this.initialFileType,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<AddMaterialSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedFileUrl;
  String _selectedFileType = 'PDF';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text = widget.initialTitle ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _selectedFileUrl = widget.initialFileUrl;
      _selectedFileType = widget.initialFileType ?? 'PDF';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                Text(
                  widget.isEditing ? 'Edit Training Material' : 'Add Training Material',
                  style: const TextStyle(
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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter material title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter material description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement file upload
                      setState(() {
                        _selectedFileUrl = 'assets/docs/placeholder.pdf';
                      });
                    },
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(8),
                      color: Colors.grey,
                      strokeWidth: 1,
                      dashPattern: const [8, 4],
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFileUrl != null
                                  ? 'File selected (tap to change)'
                                  : 'Tap to upload file',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedFileType,
                          decoration: const InputDecoration(
                            labelText: 'File Type',
                            border: OutlineInputBorder(),
                          ),
                          items: ['PDF', 'DOC', 'PPT', 'XLS'].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedFileType = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
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
                      if (_titleController.text.isEmpty ||
                          _descriptionController.text.isEmpty ||
                          _selectedFileUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'title': _titleController.text,
                        'description': _descriptionController.text,
                        'fileUrl': _selectedFileUrl,
                        'fileType': _selectedFileType,
                        'zoneId': widget.selectedZoneId,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.isEditing ? 'Update' : 'Submit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 