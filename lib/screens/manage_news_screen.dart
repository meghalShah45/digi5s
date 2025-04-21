import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../theme/colors.dart';

class News {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime dateCreated;
  final String createdById;
  final String zoneId;

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dateCreated,
    required this.createdById,
    required this.zoneId,
  });

  News copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? zoneId,
  }) {
    return News(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      dateCreated: dateCreated,
      createdById: createdById,
      zoneId: zoneId ?? this.zoneId,
    );
  }
}

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({Key? key}) : super(key: key);

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
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

  List<News> newsList = [
    News(
      id: '1',
      title: 'Company Achievement Award',
      description: 'Our company has received the Excellence in Manufacturing award',
      imageUrl: 'assets/images/award.jpeg',
      dateCreated: DateTime.now(),
      createdById: '1',
      zoneId: '1',
    ),
    News(
      id: '2',
      title: 'New Safety Protocol Implementation',
      description: 'Updated safety protocols to be implemented next month',
      imageUrl: 'assets/images/safety.jpeg',
      dateCreated: DateTime.now().subtract(const Duration(days: 1)),
      createdById: '1',
      zoneId: '2',
    ),
  ];

  List<News> get filteredNews {
    if (selectedZoneId == null) return newsList;
    return newsList.where((news) => news.zoneId == selectedZoneId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Manage News'),
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
              child: _buildNewsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNewsFlow(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }

  Widget _buildZoneDropdown() {
    return Container();
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'News',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${filteredNews.length} items',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsList() {
    if (filteredNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              selectedZoneId == null
                  ? 'No news items found'
                  : 'No news items found for selected zone',
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
      itemCount: filteredNews.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final news = filteredNews[index];
        final zone = zones.firstWhere((z) => z.id == news.zoneId);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.imageUrl.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    image: DecorationImage(
                      image: AssetImage(news.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditNewsFlow(context, news);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, news);
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Posted on ${_formatDate(news.dateCreated)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddNewsFlow(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddNewsSheet(),
    );

    if (result != null) {
      setState(() {
        newsList.add(News(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] ?? '',
          description: result['description'] ?? '',
          imageUrl: result['imageUrl'] ?? '',
          dateCreated: DateTime.now(),
          createdById: '1', // TODO: Replace with actual user ID
          zoneId: selectedZoneId!,
        ));
      });
    }
  }

  Future<void> _showEditNewsFlow(BuildContext context, News news) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddNewsSheet(
        selectedZoneId: news.zoneId,
        initialTitle: news.title,
        initialDescription: news.description,
        initialImagePath: news.imageUrl,
        isEditing: true,
      ),
    );

    if (result != null) {
      setState(() {
        final index = newsList.indexWhere((item) => item.id == news.id);
        if (index != -1) {
          newsList[index] = news.copyWith(
            title: result['title'],
            description: result['description'],
            imageUrl: result['imageUrl'],
            zoneId: result['zoneId'],
          );
        }
      });
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, News news) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news item?'),
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
        newsList.removeWhere((item) => item.id == news.id);
      });
    }
  }
}

class AddNewsSheet extends StatefulWidget {
  final String? selectedZoneId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialImagePath;
  final bool isEditing;

  const AddNewsSheet({
    Key? key,
    this.selectedZoneId,
    this.initialTitle,
    this.initialDescription,
    this.initialImagePath,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AddNewsSheet> createState() => _AddNewsSheetState();
}

class _AddNewsSheetState extends State<AddNewsSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedImagePath;

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
                const Text(
                  'Add News',
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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter news title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement photo upload
                      setState(() {
                        _selectedImagePath = 'assets/images/placeholder.png';
                      });
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: _selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                _selectedImagePath!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(8),
                              color: Colors.grey,
                              strokeWidth: 1,
                              dashPattern: const [8, 4],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload,
                                      size: 48,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload photo',
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter news description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
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
                      if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
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
                        'imageUrl': _selectedImagePath,
                        'zoneId': widget.selectedZoneId,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white)),
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