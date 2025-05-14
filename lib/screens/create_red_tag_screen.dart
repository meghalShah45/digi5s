import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seicho_app/theme/colors.dart';
import 'package:seicho_app/services/red_tag_service.dart';
import 'package:seicho_app/models/zone.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/zone_service.dart';

class CreateRedTagScreenWrapper extends StatefulWidget {
  const CreateRedTagScreenWrapper({Key? key}) : super(key: key);

  @override
  State<CreateRedTagScreenWrapper> createState() => _CreateRedTagScreenWrapperState();
}

class _CreateRedTagScreenWrapperState extends State<CreateRedTagScreenWrapper> {
  final ZoneService _zoneService = ZoneService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final RedTagService _redTagService = RedTagService();
  var userId;
  List<Zone> zones = [];
  String? selectedZoneId;
  String? attachedPhotoPath;
  bool isLoading = true;
  bool _isSubmitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    try {
      final storage = const FlutterSecureStorage();
      final orgId = await storage.read(key: 'orgId') ?? '';
      userId = await storage.read(key: 'userId') ?? '';
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        attachedPhotoPath = image.path;
      });
    }
  }

  Future<void> _createRedTag() async {
    if (selectedZoneId == null ||
        _descriptionController.text.isEmpty ||
        attachedPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a zone, fill in description and attach a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedZone = zones.firstWhere((z) => z.id == selectedZoneId);
      final result = await _redTagService.createRedTag(
        orgId: selectedZone.orgId,
        zoneId: selectedZone.id,
        redTagBy: userId, // TODO: Get from secure storage
        description: _descriptionController.text,
        remarks: _remarksController.text,
        file: File(attachedPhotoPath!),
        createdBy: userId, // TODO: Get from secure storage
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Red tag created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/manage-red-tags');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create red tag: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Red Tag'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedZoneId,
                  hint: const Text('Select Zone'),
                  isExpanded: true,
                  items: zones.map((zone) => DropdownMenuItem<String>(
                    value: zone.id,
                    child: Text(zone.zoneName),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedZoneId = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter description...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Red Tag List File',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF000000)),
                ),
                child: attachedPhotoPath == null
                    ? const Center(child: Icon(Icons.camera_alt, size: 40, color: Color(0xFF000000)))
                    : Image.file(
                        File(attachedPhotoPath!),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Remarks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter remarks...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
                onPressed: _isSubmitting ? null : _createRedTag,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryLight,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 