import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../services/zone_service.dart';
import '../services/member_service.dart';
import '../core/config/app_config.dart';

class Create5STaskScreen extends StatefulWidget {
  const Create5STaskScreen({super.key});

  @override
  State<Create5STaskScreen> createState() => _Create5STaskScreenState();
}

class _Create5STaskScreenState extends State<Create5STaskScreen> {
  String? selectedMember;
  Zone? _selectedZone;
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? attachedPhotoPath;
  List<Map<String, dynamic>> _zoneMembers = [];
  List<Zone> _zones = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New 5S Task'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(
                hintText: 'Enter task name...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Zone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<Zone>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              items: _zones.map((zone) => DropdownMenuItem(
                value: zone,
                child: Text(zone.zoneName),
              )).toList(),
              value: _selectedZone,
              onChanged: (Zone? value) {
                setState(() {
                  _selectedZone = value;
                  selectedMember = null; // Reset member selection when zone changes
                });
                if (value != null) {
                  _loadZoneMembers();
                }
              },
            ),
            const SizedBox(height: 24),
            const Text('Select Zone Member', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _buildMemberDropdown(),
            const SizedBox(height: 24),
            const Text('Describe the Task', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter task details...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Attach Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: attachedPhotoPath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 40, color: Color(0xFF1565C0)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Image.file(
                            File(attachedPhotoPath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  attachedPhotoPath = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitTask,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Task', style: TextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadZoneMembers() async {
    if (_selectedZone == null) {
      print('No zone selected');
      return;
    }

    print('Loading members for zone: ${_selectedZone!.id}');
    setState(() {
      _isLoading = true;
      _zoneMembers = []; // Clear existing members
      selectedMember = null; // Reset selection when loading new members
    });

    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      final memberService = MemberService();
      final response = await memberService.getZoneMembers(
        orgId: orgId,
        zoneId: _selectedZone!.id,
      );
      
      print('Successfully loaded members response: $response');
      if (response['data'] != null) {
        final List<dynamic> membersData = response['data'];
        print('Members data: $membersData');
        setState(() {
          _zoneMembers = membersData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('No members data in response');
      }
    } catch (e) {
      print('Error loading zone members: $e');
      setState(() {
        _isLoading = false;
        _zoneMembers = []; // Clear members on error
        selectedMember = null; // Reset selection on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load zone members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final zoneService = ZoneService();
      // TODO: Replace with actual orgId
      final zones = await zoneService.getZonesByOrgId('your-org-id');
      setState(() {
        _zones = zones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load zones: $e')),
        );
      }
    }
  }

  Future<void> _submitTask() async {
    if (_selectedZone == null || selectedMember == null || _taskNameController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      final userId = await storage.read(key: 'userId') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/tasks'),
      );

      // Add text fields
      request.fields.addAll({
        'taskName': _taskNameController.text,
        'description': _descController.text,
        'zoneMemberId': selectedMember!,
        'orgId': orgId,
        'zoneId': _selectedZone!.id,
        'createdBy': userId,
      });

      // Add file if exists
      if (attachedPhotoPath != null) {
        final file = File(attachedPhotoPath!);
        final fileName = attachedPhotoPath!.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        final mimeType = fileExtension == 'jpg' || fileExtension == 'jpeg' 
            ? 'image/jpeg' 
            : 'image/png';

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      print('Request fields: ${request.fields}');
      print('Request files: ${request.files.map((f) => '${f.filename} (${f.contentType})').join(', ')}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Return to previous screen
          }
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create task');
        }
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          attachedPhotoPath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMemberDropdown() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_zoneMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF5F5F5),
        ),
        child: const Center(
          child: Text(
            'No members available for this zone',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Debug the member data
    print('Member data: $_zoneMembers');

    // Create unique member items
    final memberItems = _zoneMembers.map((member) {
      print('Processing member: $member');
      final userId = member['id']?.toString() ?? '';
      final fullName = member['fullName']?.toString() ?? "";
      final role = member['role']!.toString();
      print('Created item - userId: $userId, fullName: $fullName');
      return DropdownMenuItem<String>(
        key: ValueKey(userId),
        value: userId,
        child: Text('${fullName} (${role})'),
      );
    }).toList();

    // Debug logging
    print('Current selectedMember: $selectedMember');
    print('Available member values: ${memberItems.map((item) => item.value).toList()}');

    // Validate selectedMember
    String? validSelectedMember;
    if (selectedMember != null) {
      final matchingItems = memberItems.where((item) => item.value == selectedMember).toList();
      if (matchingItems.length == 1) {
        validSelectedMember = selectedMember;
      }
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('member_dropdown_${_zoneMembers.length}'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
      ),
      items: memberItems,
      value: validSelectedMember,
      onChanged: _selectedZone == null ? null : (String? newValue) {
        print('Selected new value: $newValue');
        setState(() {
          selectedMember = newValue;
        });
      },
    );
  }
} 