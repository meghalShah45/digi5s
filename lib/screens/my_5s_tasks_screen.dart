import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Task {
  final String id;
  final String taskName;
  final String description;
  final List<TaskPhoto> taskPhotos;
  final String status;
  final List<Activity> activity;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.taskName,
    required this.description,
    required this.taskPhotos,
    required this.status,
    required this.activity,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskName: json['taskName'],
      description: json['description'],
      taskPhotos: (json['taskPhotos'] as List)
          .map((photo) => TaskPhoto.fromJson(photo))
          .toList(),
      status: json['status'],
      activity: (json['activity'] as List)
          .map((activity) => Activity.fromJson(activity))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class TaskPhoto {
  final String path;

  TaskPhoto({required this.path});

  factory TaskPhoto.fromJson(Map<String, dynamic> json) {
    return TaskPhoto(path: json['path']);
  }
}

class Activity {
  final String status;
  final DateTime actionOn;
  final String description;
  final String actionBy;
  final String? path;

  Activity({
    required this.status,
    required this.actionOn,
    required this.description,
    required this.actionBy,
    this.path,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      status: json['status'],
      actionOn: DateTime.parse(json['actionOn']),
      description: json['description'],
      actionBy: json['actionBy'],
      path: json['path'],
    );
  }
}

class My5STasksScreen extends StatefulWidget {
  const My5STasksScreen({super.key});

  @override
  State<My5STasksScreen> createState() => _My5STasksScreenState();
}

class _My5STasksScreenState extends State<My5STasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/tasks'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tasks = (data['data'] as List)
              .map((task) => Task.fromJson(task))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load tasks';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My 5S Tasks'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: const Color(0xFF1565C0),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(_getTasksByStatus('PENDING')),
                    _buildTaskList(_getTasksByStatus('COMPLETED')),
                    _buildTaskList(_getTasksByStatus('REJECTED')),
                  ],
                ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final Color statusColor = task.status == 'PENDING'
            ? const Color(0xFFFFF9C4)
            : task.status == 'COMPLETED'
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE);

        return Container(
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.task_alt, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    task.createdAt.toString().split('T')[0],
                    style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.taskName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task.description,
                style: const TextStyle(fontSize: 14),
              ),
              if (task.taskPhotos.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: task.taskPhotos.length,
                    itemBuilder: (context, photoIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            task.taskPhotos[photoIndex].path,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (task.status == 'PENDING') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Implement mark as completed functionality
                    },
                    child: const Text('Mark as Completed'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
} 