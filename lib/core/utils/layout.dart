import 'package:flutter/widgets.dart';

/// Tile columns for the dashboard grids: 2 on phones, more on tablets so the
/// tiles do not grow to fill a whole iPad screen.
int dashboardColumns(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}
