import 'package:flutter/material.dart';

class ViewRedTagListScreen extends StatelessWidget {
  const ViewRedTagListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final tags = [
      {'item': 'Broken Chair', 'qty': '2', 'action': 'Repair', 'status': 'pending'},
      {'item': 'Old Computer', 'qty': '1', 'action': 'Dispose', 'status': 'approved'},
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Red Tag List'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final t = tags[i];
          final isPending = t['status'] == 'pending';
          final statusColor = isPending ? const Color(0xFFFFF9C4) : const Color(0xFFF5F5F5);
          final statusText = isPending ? 'Decision Pending' : 'Approved';
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
                    const Icon(Icons.label_important, color: Color(0xFFC62828)),
                    const SizedBox(width: 8),
                    Text(t['item']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Qty: ${t['qty']}', style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Action: ${t['action']!}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? const Color(0xFFFFF176) : const Color(0xFFB2FF59),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isPending ? Colors.black : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 