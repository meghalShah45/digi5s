import 'package:flutter/material.dart';

class My5STasksScreen extends StatefulWidget {
  const My5STasksScreen({super.key});

  @override
  State<My5STasksScreen> createState() => _My5STasksScreenState();
}

class _My5STasksScreenState extends State<My5STasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(context, 'pending'),
          _buildTaskList(context, 'completed'),
          _buildTaskList(context, 'approved'),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, String type) {
    // Dummy data
    final tasks = [
      {'desc': 'Cleaned storage area', 'date': '2024-06-01'},
      {'desc': 'Organized files', 'date': '2024-06-02'},
    ];
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final t = tasks[i];
        final isPending = type == 'pending';
        final color = isPending ? const Color(0xFFFFF9C4) : const Color(0xFFF5F5F5);
        return Container(
          decoration: BoxDecoration(
            color: color,
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
                  Text(t['date']!, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Text(t['desc']!, style: const TextStyle(fontSize: 15)),
              if (isPending) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    child: const Text('Mark as Completed'),
                  ),
                ),
              ],
              // TODO: Auto-delete logic after 1 month
            ],
          ),
        );
      },
    );
  }
} 