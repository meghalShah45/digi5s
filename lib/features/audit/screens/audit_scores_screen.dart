import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session.dart';
import '../../../models/zone.dart';
import '../../../services/zone_service.dart';
import '../../../theme/colors.dart';

/// One submitted audit, as shown on the scores screen.
class AuditScore {
  final String id;
  final String sheetName;
  final String submittedBy;
  final DateTime submittedAt;
  final double score;
  final double percentage;

  const AuditScore({
    required this.id,
    required this.sheetName,
    required this.submittedBy,
    required this.submittedAt,
    required this.score,
    required this.percentage,
  });

  /// Highest score possible on the questions that applied (NA excluded),
  /// derived from the stored score and percentage.
  double? get maxScore {
    if (percentage <= 0) return null;
    final raw = score * 100 / percentage;
    // Percentages are stored rounded (83.33), so snap back to the whole number it came from.
    return (raw - raw.round()).abs() < 0.05 ? raw.roundToDouble() : raw;
  }
}

/// Submissions for one calendar month.
class MonthScores {
  final DateTime month;
  final List<AuditScore> items;
  const MonthScores(this.month, this.items);

  double get averageScore => items.isEmpty ? 0 : items.fold<double>(0, (s, e) => s + e.score) / items.length;
  double get averagePercentage => items.isEmpty ? 0 : items.fold<double>(0, (s, e) => s + e.percentage) / items.length;
  double get totalScore => items.fold<double>(0, (s, e) => s + e.score);
  double? get totalMax {
    if (items.any((e) => e.maxScore == null)) return null;
    return items.fold<double>(0, (s, e) => s + e.maxScore!);
  }
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

/// `GET /audit-sheets/zone/{zoneId}/statistics`, flattened and regrouped by the
/// month each audit was submitted (the server groups by the sheet's month name).
final zoneAuditScoresProvider = FutureProvider.autoDispose.family<List<AuditScore>, String>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final orgId = ref.read(currentUserProvider)?.orgId ?? '';
  final results = await Future.wait([
    api.get('/audit-sheets/zone/$zoneId/statistics'),
    api.get('/audit-sheets', query: {'orgId': orgId}),
  ]);
  final sheetNames = {for (final s in results[1].list) s['id'].toString(): (s['name'] ?? '').toString()};
  final stats = results[0].map['statistics'];
  final seen = <String>{};
  final out = <AuditScore>[];
  for (final month in (stats is List ? stats : const [])) {
    for (final s in (month is Map ? (month['submissions'] as List? ?? const []) : const [])) {
      if (s is! Map) continue;
      final id = s['submissionId'].toString();
      if (!seen.add(id)) continue;
      final at = DateTime.tryParse('${s['submittedAt']}');
      if (at == null) continue;
      final name = sheetNames[s['auditSheetId']?.toString()] ?? '';
      out.add(AuditScore(
        id: id,
        sheetName: name.isEmpty ? 'Audit' : name,
        submittedBy: (s['submittedByName'] ?? '').toString(),
        submittedAt: at.toLocal(),
        score: _num(s['totalScore']),
        percentage: _num(s['percentage']),
      ));
    }
  }
  out.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return out;
});

final _orgZonesProvider = FutureProvider.autoDispose<List<Zone>>((ref) async {
  final orgId = ref.watch(currentUserProvider)?.orgId ?? '';
  if (orgId.isEmpty) return const [];
  return ZoneService().getZonesByOrgId(orgId);
});

/// "View Audit Scores": zone summary, monthly chart, monthly details and the
/// individual submissions. Available to every role.
class AuditScoresScreen extends ConsumerStatefulWidget {
  const AuditScoresScreen({super.key, this.initialZoneId});
  final String? initialZoneId;

  @override
  ConsumerState<AuditScoresScreen> createState() => _AuditScoresScreenState();
}

class _AuditScoresScreenState extends ConsumerState<AuditScoresScreen> {
  static const _panel = Color(0xFFF3EEFA);
  String? _zoneId; // null = "All Zones"
  bool _initialised = false;

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(_orgZonesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Audit Scores'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _message(Icons.error_outline, 'Could not load zones',
            e is ApiException ? e.message : 'Please check your connection and try again.',
            onRetry: () => ref.invalidate(_orgZonesProvider)),
        data: (zones) {
          if (!_initialised) {
            _initialised = true;
            final user = ref.read(currentUserProvider);
            final preferred = widget.initialZoneId ??
                ((user?.isZoneLeader ?? false) || (user?.isZoneMember ?? false) ? user?.zoneId : null);
            if (zones.any((z) => z.id == preferred)) _zoneId = preferred;
          }
          final zone = zones.where((z) => z.id == _zoneId).firstOrNull;
          return RefreshIndicator(
            onRefresh: () async {
              if (_zoneId != null) {
                ref.invalidate(zoneAuditScoresProvider(_zoneId!));
                await ref.read(zoneAuditScoresProvider(_zoneId!).future).catchError((_) => <AuditScore>[]);
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _zoneSelector(zones),
                const SizedBox(height: 16),
                if (zone == null)
                  _message(Icons.bar_chart_rounded, 'Select a zone to view statistics',
                      'Choose a zone from the dropdown above to see audit statistics')
                else
                  _zoneScores(zone),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _zoneSelector(List<Zone> zones) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            value: _zoneId,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All Zones')),
              for (final z in zones) DropdownMenuItem<String?>(value: z.id, child: Text(z.zoneName)),
            ],
            onChanged: (v) => setState(() => _zoneId = v),
          ),
        ],
      ),
    );
  }

  Widget _zoneScores(Zone zone) {
    final async = ref.watch(zoneAuditScoresProvider(zone.id));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _message(Icons.error_outline, 'Could not load audit scores',
          e is ApiException ? e.message : 'Please check your connection and try again.',
          onRetry: () => ref.invalidate(zoneAuditScoresProvider(zone.id))),
      data: (scores) {
        if (scores.isEmpty) {
          return _message(Icons.assignment_outlined, 'No audits yet', 'No audits have been submitted for ${zone.zoneName}.');
        }
        final byMonth = <DateTime, List<AuditScore>>{};
        for (final s in scores) {
          byMonth.putIfAbsent(DateTime(s.submittedAt.year, s.submittedAt.month), () => []).add(s);
        }
        final months = byMonth.entries.map((e) => MonthScores(e.key, e.value)).toList()
          ..sort((a, b) => a.month.compareTo(b.month));
        final avg = scores.fold<double>(0, (s, e) => s + e.percentage) / scores.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summary(zone, scores.length, avg),
            const SizedBox(height: 16),
            _chart(months.length > 12 ? months.sublist(months.length - 12) : months),
            const SizedBox(height: 16),
            _monthlyDetails(months.reversed.toList()),
            const SizedBox(height: 16),
            _individual(scores),
          ],
        );
      },
    );
  }

  Widget _section({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _title(String text, {IconData? icon}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: AppColors.primary, size: 22), const SizedBox(width: 8)],
            Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
      );

  Widget _summary(Zone zone, int count, double avg) {
    Widget tile(String label, String value, IconData icon, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                ]),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        );
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(zone.zoneName, icon: Icons.insert_chart_outlined),
          Row(children: [
            tile('Total Submissions', '$count', Icons.assignment_turned_in_outlined, Colors.green.shade700),
            const SizedBox(width: 12),
            tile('Average Percentage', '${avg.toStringAsFixed(1)}%', Icons.trending_up, Colors.orange.shade800),
          ]),
        ],
      ),
    );
  }

  Widget _chart(List<MonthScores> months) {
    final counts = months.map((m) => m.items.length.toDouble()).toList();
    final maxY = (counts.fold<double>(0, (a, b) => a > b ? a : b) + 1).ceilToDouble();
    final label = DateFormat('MMM');
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Monthly Submissions'),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY < 3 ? 3 : maxY,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(horizontalInterval: 1),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label.format(months[i].month),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: counts[i],
                        color: AppColors.primary,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyDetails(List<MonthScores> months) {
    final now = DateTime.now();
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Monthly Details'),
          for (final m in months) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        DateFormat(m.month.year == now.year ? 'MMMM' : 'MMMM yyyy').format(m.month),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${m.items.length} submission${m.items.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _stat(Icons.star_border, 'Average Score', _fmt(m.averageScore)),
                    _stat(Icons.trending_up, 'Average Percentage', '${m.averagePercentage.toStringAsFixed(1)}%'),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _stat(Icons.calculate_outlined, 'Total Score',
                        m.totalMax == null ? _fmt(m.totalScore) : '${_fmt(m.totalScore)}/${_fmt(m.totalMax!)}'),
                    _stat(Icons.pie_chart_outline, 'Score Ratio',
                        m.totalMax == null || m.totalMax == 0 ? '-' : '${(m.totalScore * 100 / m.totalMax!).toStringAsFixed(1)}%'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) => Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _individual(List<AuditScore> scores) {
    final date = DateFormat('d/M/yyyy');
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Individual Submissions'),
          for (final s in scores) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.sheetName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Submitted: ${date.format(s.submittedAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        if (s.submittedBy.isNotEmpty && s.submittedBy != 'Unknown User')
                          Text('By: ${s.submittedBy}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _pctColor(s.percentage).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${s.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _pctColor(s.percentage))),
                      ),
                      const SizedBox(height: 4),
                      Text('Score: ${_fmt(s.score)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  static Color _pctColor(double p) {
    if (p >= 90) return Colors.green.shade700;
    if (p >= 60) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _message(IconData icon, String title, String body, {VoidCallback? onRetry}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
