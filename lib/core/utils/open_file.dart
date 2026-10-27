import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an uploaded file (S3 URL) in the system browser / viewer.
Future<void> openRemoteFile(BuildContext context, String? url) async {
  if (url == null || url.trim().isEmpty) {
    _snack(context, 'No file attached.');
    return;
  }
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    _snack(context, 'Invalid file link.');
    return;
  }
  bool ok;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) _snack(context, 'Could not open the file.');
}

bool isImagePath(String? path) => RegExp(r'\.(png|jpe?g|gif|webp|heic)(\?|$)').hasMatch((path ?? '').toLowerCase());

/// Shows an uploaded attachment: images inline (tap to open full size),
/// other files (PDF, video) as a tappable tile.
class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({super.key, required this.url, this.height = 200});
  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: () => openRemoteFile(context, url),
      child: Container(
        height: 72,
        width: double.infinity,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fileIcon(url), color: Colors.grey.shade700),
            const SizedBox(width: 8),
            const Text('Open attachment'),
          ],
        ),
      ),
    );
    if (!isImagePath(url)) return tile;
    return GestureDetector(
      onTap: () => openRemoteFile(context, url),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => tile,
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// Icon for a file by extension.
IconData fileIcon(String? path) {
  final p = (path ?? '').toLowerCase();
  if (p.contains('.pdf')) return Icons.picture_as_pdf;
  if (p.contains('.mp4') || p.contains('.mov')) return Icons.play_circle_fill;
  if (RegExp(r'\.(png|jpe?g|gif|webp)').hasMatch(p)) return Icons.image;
  return Icons.insert_drive_file;
}
