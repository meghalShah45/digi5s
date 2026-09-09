import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/colors.dart';
import '../services/member_service.dart';
import '../services/zone_service.dart';
import '../core/config/app_config.dart';

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
  // Additional fields for enhanced display
  final String? zoneName;
  final String? submittedByUserName;
  final String? submittedByEmail;
  final String? submittedByDesignation;

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
    this.zoneName,
    this.submittedByUserName,
    this.submittedByEmail,
    this.submittedByDesignation,
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
      zoneName: json['zoneName'],
      submittedByUserName: json['submittedByUserName'] ?? json['createdByUserName'],
      submittedByEmail: json['submittedByEmail'] ?? json['createdByEmail'],
      submittedByDesignation: json['submittedByDesignation'] ?? json['createdByDesignation'],
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
  bool _isProcessingAction = false; // Add loading state for API calls
  String? _error;
  final MemberService _memberService = MemberService();
  final ZoneService _zoneService = ZoneService();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/tasks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> tasksData = jsonResponse['data'];
        List<Task> tasks = tasksData
            .map((task) => Task.fromJson(task))
            .where((task) => task.status == 'PENDING_APPROVAL')
            .toList();
        
        // Enhance tasks with user details if not already provided
        tasks = await _enhanceTasksWithUserDetails(tasks);
        
        setState(() {
          _tasks = tasks;
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

  Future<List<Task>> _enhanceTasksWithUserDetails(List<Task> tasks) async {
    List<Task> enhancedTasks = [];
    
    // Get all zones for this organization to avoid multiple API calls
    Map<String, String> zoneNames = {};
    try {
      final zones = await _zoneService.getZonesByOrgId(tasks.first.orgId);
      zoneNames = {for (var zone in zones) zone.id: zone.zoneName};
    } catch (e) {
      print('Error fetching zones: $e');
    }
    
    for (Task task in tasks) {
      Task enhancedTask = task;
      
      // The user who submitted for approval is likely the zoneMemberId (assigned user)
      // or we can look for the last activity that indicates submission for approval
      String? submittedByUserId = task.zoneMemberId; // Use assigned user as primary
      
      print('Task ${task.id} - zoneMemberId: ${task.zoneMemberId}, createdBy: ${task.createdBy}');
      
      // If no zoneMemberId, try to find from activity
      if (submittedByUserId == null || submittedByUserId.isEmpty) {
        if (task.activity.isNotEmpty) {
          // Look for the most recent activity that indicates submission for approval
          final recentActivity = task.activity.last;
          print('Recent activity: ${recentActivity.status} - ${recentActivity.description} - by: ${recentActivity.actionBy}');
          if (recentActivity.status == 'PENDING_APPROVAL' || 
              recentActivity.description.toLowerCase().contains('approval')) {
            submittedByUserId = recentActivity.actionBy;
          }
        }
        // Fallback to creator if still no user found
        if (submittedByUserId == null || submittedByUserId.isEmpty) {
          submittedByUserId = task.createdBy;
        }
      }
      
      print('Final submittedByUserId: $submittedByUserId');
      
      // If user details are not provided, try to fetch them
      if (task.submittedByUserName == null && submittedByUserId != null && submittedByUserId.isNotEmpty) {
        try {
          // Try to get user details from zone members
          final memberResponse = await _memberService.getZoneMembers(
            orgId: task.orgId,
            zoneId: task.zoneId,
          );
          
          if (memberResponse['data'] != null) {
            final List<dynamic> members = memberResponse['data'];
            print('Found ${members.length} members for zone ${task.zoneId}');
            final userMember = members.firstWhere(
              (member) => member['id'] == submittedByUserId,
              orElse: () => null,
            );
            
            if (userMember != null) {
              enhancedTask = Task(
                id: task.id,
                taskName: task.taskName,
                description: task.description,
                taskPhotos: task.taskPhotos,
                zoneMemberId: task.zoneMemberId,
                orgId: task.orgId,
                zoneId: task.zoneId,
                targetDate: task.targetDate,
                status: task.status,
                activity: task.activity,
                approved: task.approved,
                createdAt: task.createdAt,
                modifiedAt: task.modifiedAt,
                createdBy: task.createdBy,
                modifiedBy: task.modifiedBy,
                zoneName: task.zoneName ?? zoneNames[task.zoneId],
                submittedByUserName: userMember['fullName'],
                submittedByEmail: userMember['email'],
                submittedByDesignation: userMember['designation'],
              );
            } else {
              print('User member not found for ID: $submittedByUserId');
              print('Available members: ${members.map((m) => '${m['id']}: ${m['fullName']}').toList()}');
              // Fallback: use the user ID as name if we can't find the user
              enhancedTask = Task(
                id: task.id,
                taskName: task.taskName,
                description: task.description,
                taskPhotos: task.taskPhotos,
                zoneMemberId: task.zoneMemberId,
                orgId: task.orgId,
                zoneId: task.zoneId,
                targetDate: task.targetDate,
                status: task.status,
                activity: task.activity,
                approved: task.approved,
                createdAt: task.createdAt,
                modifiedAt: task.modifiedAt,
                createdBy: task.createdBy,
                modifiedBy: task.modifiedBy,
                zoneName: task.zoneName ?? zoneNames[task.zoneId],
                submittedByUserName: 'User ID: $submittedByUserId',
                submittedByEmail: null,
                submittedByDesignation: null,
              );
            }
          }
        } catch (e) {
          print('Error fetching user details for task ${task.id}: $e');
          // Fallback: use the user ID as name if we can't fetch user details
          enhancedTask = Task(
            id: task.id,
            taskName: task.taskName,
            description: task.description,
            taskPhotos: task.taskPhotos,
            zoneMemberId: task.zoneMemberId,
            orgId: task.orgId,
            zoneId: task.zoneId,
            targetDate: task.targetDate,
            status: task.status,
            activity: task.activity,
            approved: task.approved,
            createdAt: task.createdAt,
            modifiedAt: task.modifiedAt,
            createdBy: task.createdBy,
            modifiedBy: task.modifiedBy,
            zoneName: task.zoneName ?? zoneNames[task.zoneId],
            submittedByUserName: 'User ID: $submittedByUserId',
            submittedByEmail: null,
            submittedByDesignation: null,
          );
        }
      }
      
      // If zone name is still not available, use the cached zone names
      if (enhancedTask.zoneName == null && zoneNames.containsKey(enhancedTask.zoneId)) {
        enhancedTask = Task(
          id: enhancedTask.id,
          taskName: enhancedTask.taskName,
          description: enhancedTask.description,
          taskPhotos: enhancedTask.taskPhotos,
          zoneMemberId: enhancedTask.zoneMemberId,
          orgId: enhancedTask.orgId,
          zoneId: enhancedTask.zoneId,
          targetDate: enhancedTask.targetDate,
          status: enhancedTask.status,
          activity: enhancedTask.activity,
          approved: enhancedTask.approved,
          createdAt: enhancedTask.createdAt,
          modifiedAt: enhancedTask.modifiedAt,
          createdBy: enhancedTask.createdBy,
          modifiedBy: enhancedTask.modifiedBy,
          zoneName: zoneNames[enhancedTask.zoneId],
          submittedByUserName: enhancedTask.submittedByUserName,
          submittedByEmail: enhancedTask.submittedByEmail,
          submittedByDesignation: enhancedTask.submittedByDesignation,
        );
      }
      
      enhancedTasks.add(enhancedTask);
    }
    
    return enhancedTasks;
  }

  Future<void> _handleTaskAction(String taskId, bool approve) async {
    print('_handleTaskAction called - taskId: $taskId, approve: $approve');
    
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
                labelText: 'Remarks (Optional)',
                hintText: 'Enter your remarks here (optional)',
              ),
              maxLines: 3,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('Cancel button pressed');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('Submit button pressed - remarks: ${remarksController.text}');
              Navigator.of(context).pop(remarksController.text);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    print('Dialog result - remarks: $remarks');

    if (remarks == null) {
      print('Dialog cancelled, returning early');
      return; // User cancelled the dialog
    }

    // Allow empty remarks - don't return early
    print('Making API call to approve/reject task');
    
    // Set loading state
    setState(() {
      _isProcessingAction = true;
    });
    
    try {
      final requestBody = {
        'action': approve ? 'APPROVE' : 'REJECT',
        'remarks': remarks.isEmpty ? 'NA' : remarks, // Send empty string if no remarks
      };
      
      print('Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/tasks/approve/$taskId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Task action successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Task approved successfully' : 'Task rejected successfully'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        print('Refreshing task list');
        _fetchTasks(); // Refresh the list
      } else {
        print('Task action failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task status: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in _handleTaskAction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Clear loading state
      setState(() {
        _isProcessingAction = false;
      });
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
      body: Stack(
        children: [
          _isLoading
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
                                  // Task Header
                                  Row(
                                    children: [
                                      const Icon(Icons.task, color: Color(0xFF1565C0)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          task.taskName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9800),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Pending Approval',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Task Description
                                  Text(
                                    task.description,
                                    style: const TextStyle(fontSize: 15, color: Color(0xFF424242)),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Submitted By Information
                                  _buildInfoRow('Submitted by', task.submittedByUserName ?? 'Unknown User'),
                                  if (task.submittedByEmail != null)
                                    _buildInfoRow('Email', task.submittedByEmail!),
                                  if (task.submittedByDesignation != null)
                                    _buildInfoRow('Designation', task.submittedByDesignation!),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Zone Information
                                  if (task.zoneName != null)
                                    _buildInfoRow('Zone', task.zoneName!),
                                  
                                  // Target Date
                                  if (task.targetDate != null)
                                    _buildInfoRow('Target Date', task.targetDate!.split('T')[0]),
                                  
                                  // Created Date
                                  _buildInfoRow('Submitted on', task.createdAt.split('T')[0]),
                                  
                                  // Task Photos
                                  if (task.taskPhotos.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Task Photos',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
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
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Action Buttons
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
                                          onPressed: _isProcessingAction ? null : () {
                                            print('Approve button pressed for task: ${task.id}');
                                            _handleTaskAction(task.id, true);
                                          },
                                          child: _isProcessingAction 
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(
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
                                          onPressed: _isProcessingAction ? null : () {
                                            print('Disapprove button pressed for task: ${task.id}');
                                            _handleTaskAction(task.id, false);
                                          },
                                          child: _isProcessingAction 
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC2185B)),
                                                ),
                                              )
                                            : const Text('Disapprove'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
          // Loading overlay
          if (_isProcessingAction)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF424242),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}