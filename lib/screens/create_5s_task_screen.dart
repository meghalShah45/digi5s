import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class Create5STaskScreen extends StatefulWidget {
  const Create5STaskScreen({super.key});

  @override
  State<Create5STaskScreen> createState() => _Create5STaskScreenState();
}

class _Create5STaskScreenState extends State<Create5STaskScreen> {
  String? selectedMember;
  final TextEditingController _descController = TextEditingController();
  String? attachedPhotoPath;

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
            const Text('Select Zone Member', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              items: ['Self', 'Member A', 'Member B', 'Member C']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              value: selectedMember,
              onChanged: (v) => setState(() => selectedMember = v),
            ),
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
              onTap: () {
                // TODO: Implement photo picker
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: attachedPhotoPath == null
                    ? const Center(child: Icon(Icons.camera_alt, size: 40, color: Color(0xFF1565C0)))
                    : Image.file(
                        File(attachedPhotoPath!),
                        fit: BoxFit.cover,
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
                onPressed: () {
                  // TODO: Submit logic
                },
                child: const Text('Submit Task', style: TextStyle(
                    color: AppColors.secondaryLight,
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 