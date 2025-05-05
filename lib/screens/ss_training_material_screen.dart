import 'package:flutter/material.dart';

class SSTrainingMaterialScreen extends StatelessWidget {
  const SSTrainingMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final materials = [
      {'title': '5S Introduction PDF', 'type': 'PDF'},
      {'title': '5S Video Tutorial', 'type': 'Video'},
      {'title': '5S Poster', 'type': 'Image'},
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('5S Training Material'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final m = materials[i];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
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
            child: Row(
              children: [
                Icon(
                  m['type'] == 'PDF'
                      ? Icons.picture_as_pdf
                      : m['type'] == 'Video'
                          ? Icons.play_circle_fill
                          : Icons.image,
                  color: const Color(0xFF283593),
                  size: 32,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    m['title']!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFFBDBDBD)),
              ],
            ),
          );
        },
      ),
    );
  }
} 