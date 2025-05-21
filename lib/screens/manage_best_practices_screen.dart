import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/zone.dart';
import '../services/zone_service.dart';
import '../services/best_practice_service.dart';
import '../theme/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BestPractice {
  final String id;
  final String title;
  final String description;
  final String zoneId;
  final DateTime dateCreated;
  final String createdById;
  final String? imageUrl;
  final bool approved;

  BestPractice({
    required this.id,
    required this.title,
    required this.description,
    required this.zoneId,
    required this.dateCreated,
    required this.createdById,
    this.imageUrl,
    this.approved = false,
  });

  factory BestPractice.fromJson(Map<String, dynamic> json) {
    return BestPractice(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      zoneId: json['zone'],
      dateCreated: DateTime.parse(json['createdAt']),
      createdById: json['createdBy'],
      imageUrl: json['path'],
      approved: json['approved'] ?? false,
    );
  }
}

class ManageBestPracticesScreen extends StatefulWidget {
  const ManageBestPracticesScreen({Key? key}) : super(key: key);

  @override
  State<ManageBestPracticesScreen> createState() => _ManageBestPracticesScreenState();
}

class _ManageBestPracticesScreenState extends State<ManageBestPracticesScreen> {
  final ZoneService _zoneService = ZoneService();
  final BestPracticeService _bestPracticeService = BestPracticeService();
  String? selectedZoneId;
  List<Zone> zones = [];
  List<BestPractice> bestPractices = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      zones = await _zoneService.getZonesByOrgId(orgId);
      
      final response = await _bestPracticeService.getBestPractices();
      final List<dynamic> practices = response['data'];
      bestPractices = practices.map((p) => BestPractice.fromJson(p)).toList();
      
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

  List<BestPractice> get filteredBestPractices {
    if (selectedZoneId == null) return bestPractices;
    return bestPractices.where((bp) => bp.zoneId == selectedZoneId).toList();
  }

  Future<void> _showEditBestPracticeSheet(BuildContext context, BestPractice practice) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditBestPracticeSheet(
        practice: practice,
        zones: zones,
      ),
    );

    if (result != null) {
      try {
        setState(() {
          isLoading = true;
        });

        final response = await _bestPracticeService.updateBestPractice(
          id: practice.id,
          title: result['title'],
          zone: result['zone'],
          description: result['description'],
          file: result['file'],
        );

        final updatedPractice = BestPractice.fromJson(response['data'][0]);
        setState(() {
          final index = bestPractices.indexWhere((bp) => bp.id == practice.id);
          if (index != -1) {
            bestPractices[index] = updatedPractice;
          }
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Best practice updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update best practice: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(BestPractice practice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Best Practice'),
        content: Text('Are you sure you want to delete "${practice.title}"?'),
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

    if (confirmed == true) {
      try {
        setState(() {
          isLoading = true;
        });

        await _bestPracticeService.deleteBestPractice(practice.id);
        
        setState(() {
          bestPractices.removeWhere((bp) => bp.id == practice.id);
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Best practice deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete best practice: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Best Practices'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildZoneDropdown(),
                    ),
                    Expanded(
                      child: filteredBestPractices.isEmpty
                          ? const Center(
                              child: Text('No best practices available for this zone'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredBestPractices.length,
                              itemBuilder: (context, index) {
                                final practice = filteredBestPractices[index];
                                final zone = zones.firstWhere((z) => z.id == practice.zoneId);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (practice.imageUrl != null)
                                        Image.network(
                                          practice.imageUrl!,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    practice.title,
                                                    style: Theme.of(context).textTheme.titleLarge,
                                                  ),
                                                ),
                                                if (practice.approved)
                                                  const Icon(Icons.check_circle, color: Colors.green),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      _showEditBestPracticeSheet(context, practice);
                                                    } else if (value == 'delete') {
                                                      _showDeleteConfirmation(practice);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text('Edit'),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Zone: ${zone.zoneName}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(practice.description),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBestPracticeSheet(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }

  Future<void> _showAddBestPracticeSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddBestPracticeSheet(
        zones: zones,
      ),
    );

    if (result != null) {
      try {
        setState(() {
          isLoading = true;
        });

        final response = await _bestPracticeService.createBestPractice(
          title: result['title'],
          zone: result['zone'],
          description: result['description'],
          file: result['file'],
        );

        final newPractice = BestPractice.fromJson(response['data'][0]);
        setState(() {
          bestPractices.add(newPractice);
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Best practice created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create best practice: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
}

class AddBestPracticeSheet extends StatefulWidget {
  final List<Zone> zones;

  const AddBestPracticeSheet({
    super.key,
    required this.zones,
  });

  @override
  State<AddBestPracticeSheet> createState() => _AddBestPracticeSheetState();
}

class _AddBestPracticeSheetState extends State<AddBestPracticeSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedZoneId;
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Best Practice',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedZoneId,
              decoration: const InputDecoration(
                labelText: 'Zone',
                border: OutlineInputBorder(),
              ),
              items: widget.zones.map((zone) => DropdownMenuItem<String>(
                value: zone.id,
                child: Text(zone.zoneName),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZoneId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
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
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedImage != null
                            ? 'Image selected (tap to change)'
                            : 'Tap to add image',
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty ||
                        _descriptionController.text.isEmpty ||
                        _selectedZoneId == null ||
                        _selectedImage == null) {
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
                      'zone': _selectedZoneId!,
                      'description': _descriptionController.text,
                      'file': _selectedImage!,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: AppColors.secondaryLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditBestPracticeSheet extends StatefulWidget {
  final BestPractice practice;
  final List<Zone> zones;

  const EditBestPracticeSheet({
    super.key,
    required this.practice,
    required this.zones,
  });

  @override
  State<EditBestPracticeSheet> createState() => _EditBestPracticeSheetState();
}

class _EditBestPracticeSheetState extends State<EditBestPracticeSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedZoneId;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.practice.title);
    _descriptionController = TextEditingController(text: widget.practice.description);
    _selectedZoneId = widget.practice.zoneId;
    _currentImageUrl = widget.practice.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Best Practice',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedZoneId,
              decoration: const InputDecoration(
                labelText: 'Zone',
                border: OutlineInputBorder(),
              ),
              items: widget.zones.map((zone) => DropdownMenuItem<String>(
                value: zone.id,
                child: Text(zone.zoneName),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZoneId = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_currentImageUrl != null && _selectedImage == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Image:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _pickImage,
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
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedImage != null
                            ? 'New image selected (tap to change)'
                            : 'Tap to change image (optional)',
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
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Image Preview:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty ||
                        _descriptionController.text.isEmpty ||
                        _selectedZoneId.isEmpty) {
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
                      'zone': _selectedZoneId,
                      'description': _descriptionController.text,
                      'file': _selectedImage,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: AppColors.secondaryLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 