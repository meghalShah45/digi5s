import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/open_file.dart';
import '../features/training_material/models/training_material_model.dart';
import '../features/training_material/providers/training_material_provider.dart';

/// Read-only training material list for zone leaders, members and viewers.
class SSTrainingMaterialScreen extends ConsumerWidget {
  const SSTrainingMaterialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(trainingMaterialsProvider);
    final notifier = ref.watch(trainingMaterialsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('5S Training Material'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D2D),
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadTrainingMaterials,
        child: notifier.isLoading && materials.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifier.error != null && materials.isEmpty
                ? _empty(Icons.error_outline, notifier.error!)
                : materials.isEmpty
                    ? _empty(Icons.school_outlined, 'No training material has been shared yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: materials.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _MaterialTile(material: materials[i]),
                      ),
      ),
    );
  }

  Widget _empty(IconData icon, String text) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      );
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});
  final TrainingMaterial material;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openRemoteFile(context, material.path),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(fileIcon(material.path), color: const Color(0xFF283593), size: 32),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${material.materialType} · ${DateFormat('d MMM yyyy').format(material.createdAt.toLocal())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Color(0xFF283593)),
          ],
        ),
      ),
    );
  }
}
