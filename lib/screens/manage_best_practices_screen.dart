import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/zone.dart';
import '../services/zone_service.dart';
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
  final List<String> tags;

  BestPractice({
    required this.id,
    required this.title,
    required this.description,
    required this.zoneId,
    required this.dateCreated,
    required this.createdById,
    this.imageUrl,
    this.tags = const [],
  });

  BestPractice copyWith({
    String? id,
    String? title,
    String? description,
    String? zoneId,
    DateTime? dateCreated,
    String? createdById,
    String? imageUrl,
    List<String>? tags,
  }) {
    return BestPractice(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      zoneId: zoneId ?? this.zoneId,
      dateCreated: dateCreated ?? this.dateCreated,
      createdById: createdById ?? this.createdById,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
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
  String? selectedZoneId;
  List<Zone> zones = [];
  bool isLoading = true;
  String? error;

  final List<BestPractice> bestPractices = [
    BestPractice(
      id: '1',
      title: 'Efficient Machine Operation',
      description: 'Best practices for operating machinery in Zone A',
      zoneId: '1',
      dateCreated: DateTime.now().subtract(const Duration(days: 5)),
      createdById: 'user1',
      tags: ['Machinery', 'Safety'],
    ),
    BestPractice(
      id: '2',
      title: 'Safety Protocol Implementation',
      description: 'Updated safety protocols for Zone B operations',
      zoneId: '2',
      dateCreated: DateTime.now().subtract(const Duration(days: 3)),
      createdById: 'user2',
      tags: ['Safety', 'Protocol'],
    ),
  ];

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

  List<BestPractice> get filteredBestPractices {
    if (selectedZoneId == null) return bestPractices;
    return bestPractices.where((bp) => bp.zoneId == selectedZoneId).toList();
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
              : filteredBestPractices.isEmpty
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
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showAddBestPracticeSheet(
                                                context,
                                                existingPractice: practice,
                                              );
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
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: practice.tags.map((tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Future<void> _showAddBestPracticeSheet(
    BuildContext context, {
    BestPractice? existingPractice,
  }) async {
    final result = await showModalBottomSheet<BestPractice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddBestPracticeSheet(
        zones: zones,
        practice: existingPractice,
      ),
    );

    if (result != null) {
      setState(() {
        if (existingPractice != null) {
          final index = bestPractices.indexWhere((bp) => bp.id == existingPractice.id);
          if (index != -1) {
            bestPractices[index] = result;
          }
        } else {
          bestPractices.add(result);
        }
      });
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
      setState(() {
        bestPractices.removeWhere((bp) => bp.id == practice.id);
      });
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
  final BestPractice? practice;

  const AddBestPracticeSheet({
    super.key,
    required this.zones,
    this.practice,
  });

  @override
  State<AddBestPracticeSheet> createState() => _AddBestPracticeSheetState();
}

class _AddBestPracticeSheetState extends State<AddBestPracticeSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  String? _selectedZoneId;
  List<String> _tags = [];
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.practice?.title);
    _descriptionController = TextEditingController(text: widget.practice?.description);
    _tagController = TextEditingController();
    _selectedZoneId = widget.practice?.zoneId;
    _tags = widget.practice?.tags.toList() ?? [];
    _imageUrl = widget.practice?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickImage() async {
    // TODO: Implement image picker
    setState(() {
      _imageUrl = 'assets/images/placeholder.png';
    });
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
                  widget.practice == null ? 'Add Best Practice' : 'Edit Best Practice',
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
                        _imageUrl != null
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add Tags',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                )).toList(),
              ),
            ],
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
                        _selectedZoneId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final practice = BestPractice(
                      id: widget.practice?.id ?? DateTime.now().toString(),
                      title: _titleController.text,
                      description: _descriptionController.text,
                      zoneId: _selectedZoneId!,
                      dateCreated: widget.practice?.dateCreated ?? DateTime.now(),
                      createdById: widget.practice?.createdById ?? 'user1',
                      imageUrl: _imageUrl,
                      tags: _tags,
                    );

                    Navigator.pop(context, practice);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    widget.practice == null ? 'Add' : 'Save',
                    style: const TextStyle(color: AppColors.secondaryLight),
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