import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class FlashNews {
  final String id;
  final String title;
  final String description;
  final DateTime dateCreated;
  final String createdById;
  final bool isUrgent;

  FlashNews({
    required this.id,
    required this.title,
    required this.description,
    required this.dateCreated,
    required this.createdById,
    this.isUrgent = false,
  });

  FlashNews copyWith({
    String? title,
    String? description,
    bool? isUrgent,
  }) {
    return FlashNews(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateCreated: dateCreated,
      createdById: createdById,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

class FlashNewsScreen extends StatefulWidget {
  const FlashNewsScreen({Key? key}) : super(key: key);

  @override
  State<FlashNewsScreen> createState() => _FlashNewsScreenState();
}

class _FlashNewsScreenState extends State<FlashNewsScreen> {
  List<FlashNews> flashNews = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Flash News'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/'),
        ),
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
                  const Text(
                    'Flash News',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${flashNews.length} items',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildFlashNewsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFlashNewsSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }

  Widget _buildFlashNewsList() {
    if (flashNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flash_on_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No flash news available',
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
      itemCount: flashNews.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final news = flashNews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: news.isUrgent ? Colors.red[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.flash_on,
                color: news.isUrgent ? Colors.red : Colors.orange,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        news.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (news.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Urgent',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                const SizedBox(height: 8),
                Text(
                  'Posted on ${_formatDate(news.dateCreated)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditFlashNewsSheet(context, news);
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
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddFlashNewsSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddFlashNewsSheet(),
    );

    if (result != null) {
      setState(() {
        flashNews.add(FlashNews(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] as String,
          description: result['description'] as String,
          dateCreated: DateTime.now(),
          createdById: '1', // TODO: Replace with actual user ID
          isUrgent: result['isUrgent'] as bool,
        ));
      });
    }
  }

  Future<void> _showEditFlashNewsSheet(BuildContext context, FlashNews news) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFlashNewsSheet(
        initialTitle: news.title,
        initialDescription: news.description,
        initialIsUrgent: news.isUrgent,
        isEditing: true,
      ),
    );

    if (result != null) {
      setState(() {
        final index = flashNews.indexWhere((item) => item.id == news.id);
        if (index != -1) {
          flashNews[index] = news.copyWith(
            title: result['title'] as String,
            description: result['description'] as String,
            isUrgent: result['isUrgent'] as bool,
          );
        }
      });
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, FlashNews news) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flash News'),
        content: const Text('Are you sure you want to delete this flash news?'),
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
        flashNews.removeWhere((item) => item.id == news.id);
      });
    }
  }
}

class AddFlashNewsSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final bool? initialIsUrgent;
  final bool isEditing;

  const AddFlashNewsSheet({
    Key? key,
    this.initialTitle,
    this.initialDescription,
    this.initialIsUrgent,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AddFlashNewsSheet> createState() => _AddFlashNewsSheetState();
}

class _AddFlashNewsSheetState extends State<AddFlashNewsSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text = widget.initialTitle ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _isUrgent = widget.initialIsUrgent ?? false;
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
                  widget.isEditing ? 'Edit Flash News' : 'Add Flash News',
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
                      hintText: 'Enter title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Mark as Urgent'),
                    value: _isUrgent,
                    onChanged: (value) {
                      setState(() {
                        _isUrgent = value;
                      });
                    },
                    activeColor: Colors.red,
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
                          _descriptionController.text.isEmpty) {
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
                        'isUrgent': _isUrgent,
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