import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/colors.dart';

class Task {
  final String id;
  final String taskName;
  final String description;
  final List<TaskPhoto> taskPhotos;
  final String zoneMemberId;
  final String orgId;
  final String zoneId;
  final String? targetDate;
  final String status;
  final List<Activity> activity;
  final bool approved;
  final String createdAt;
  final String? modifiedAt;
  final String createdBy;
  final String? modifiedBy;

  Task({
    required this.id,
    required this.taskName,
    required this.description,
    required this.taskPhotos,
    required this.zoneMemberId,
    required this.orgId,
    required this.zoneId,
    this.targetDate,
    required this.status,
    required this.activity,
    required this.approved,
    required this.createdAt,
    this.modifiedAt,
    required this.createdBy,
    this.modifiedBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskName: json['taskName'],
      description: json['description'],
      taskPhotos: (json['taskPhotos'] as List)
          .map((photo) => TaskPhoto.fromJson(photo))
          .toList(),
      zoneMemberId: json['zoneMemberId'],
      orgId: json['orgId'],
      zoneId: json['zoneId'],
      targetDate: json['targetDate'],
      status: json['status'],
      activity: (json['activity'] as List)
          .map((act) => Activity.fromJson(act))
          .toList(),
      approved: json['approved'],
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
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
  final String actionOn;
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
      actionOn: json['actionOn'],
      description: json['description'],
      actionBy: json['actionBy'],
      path: json['path'],
    );
  }
}

class Approve5STaskScreen extends StatefulWidget {
  const Approve5STaskScreen({super.key});

  @override
  State<Approve5STaskScreen> createState() => _Approve5STaskScreenState();
}

class _Approve5STaskScreenState extends State<Approve5STaskScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/tasks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> tasksData = jsonResponse['data'];
        setState(() {
          _tasks = tasksData
              .map((task) => Task.fromJson(task))
              .where((task) => task.status == 'PENDING_APPROVAL')
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

  Future<void> _handleTaskAction(String taskId, bool approve) async {
    // Show dialog to get remarks
    final remarksController = TextEditingController();
    final remarks = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Task' : 'Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Enter your remarks here',
              ),
              maxLines: 3,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(remarksController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (remarks == null || remarks.isEmpty) return; // User cancelled the dialog or didn't enter remarks

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/tasks/approve/$taskId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': approve ? 'APPROVE' : 'REJECT',
          'remarks': remarks,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Task approved successfully' : 'Task rejected successfully'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        _fetchTasks(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Approve 5S Tasks'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _tasks.isEmpty
                  ? const Center(child: Text('No tasks pending for approval'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final task = _tasks[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
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
                                  const Icon(Icons.task, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.taskName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    task.createdAt.split('T')[0],
                                    style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(task.description, style: const TextStyle(fontSize: 15)),
                              if (task.taskPhotos.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: task.taskPhotos.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            task.taskPhotos[index].path,
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
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _handleTaskAction(task.id, true),
                                      child: const Text(
                                        'Approve',
                                        style: TextStyle(color: AppColors.secondaryLight),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFC2185B),
                                        side: const BorderSide(color: Color(0xFFC2185B)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _handleTaskAction(task.id, false),
                                      child: const Text('Disapprove'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
} 