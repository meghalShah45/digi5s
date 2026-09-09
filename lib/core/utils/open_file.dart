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
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) _snack(context, 'Could not open the file.');
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
