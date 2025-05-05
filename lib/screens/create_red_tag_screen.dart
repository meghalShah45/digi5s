import 'dart:io';
import 'package:flutter/material.dart';
import 'package:seicho_app/theme/colors.dart';

class CreateRedTagScreen extends StatefulWidget {
  const CreateRedTagScreen({super.key});

  @override
  State<CreateRedTagScreen> createState() => _CreateRedTagScreenState();
}

class _CreateRedTagScreenState extends State<CreateRedTagScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  String? attachedPhotoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Red Tag'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Red Tag Item Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: 'Enter item name...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter quantity...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Action to Take', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _actionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Describe action...',
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
                  // color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF000000)),
                ),
                child: attachedPhotoPath == null
                    ? const Center(child: Icon(Icons.camera_alt, size: 40, color: Color(
                    0xFF000000)))
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
                  // TODO: Create logic
                },
                child: const Text('Create', style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 