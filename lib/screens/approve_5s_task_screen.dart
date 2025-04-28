import 'package:flutter/material.dart';

import '../theme/colors.dart';

class Approve5STaskScreen extends StatelessWidget {
  const Approve5STaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for tasks
    final tasks = [
      {'member': 'Member A', 'desc': 'Cleaned storage area', 'date': '2024-06-01'},
      {'member': 'Member B', 'desc': 'Organized files', 'date': '2024-06-02'},
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Approve 5S Tasks'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final t = tasks[i];
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
                    const Icon(Icons.person, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(t['member']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(t['date']!, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(t['desc']!, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        child: const Text('Approve', style: TextStyle(color: AppColors.secondaryLight),),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC2185B),
                          side: const BorderSide(color: Color(0xFFC2185B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
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