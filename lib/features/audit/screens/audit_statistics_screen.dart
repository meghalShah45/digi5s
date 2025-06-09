import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/colors.dart';
import '../models/audit_statistics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuditStatisticsScreen extends StatefulWidget {
  final String zoneId;
  final int year;

  const AuditStatisticsScreen({
    super.key,
    required this.zoneId,
    required this.year,
  });

  @override
  State<AuditStatisticsScreen> createState() => _AuditStatisticsScreenState();
}

class _AuditStatisticsScreenState extends State<AuditStatisticsScreen> {
  bool _isLoading = true;
  String? _error;
  AuditStatistics? _statistics;
  final List<String> _allMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      const String baseUrl = 'http://localhost:8081';
      final url = widget.zoneId == 'all' 
          ? '$baseUrl/audit-sheets/statistics?year=${widget.year}'
          : '$baseUrl/audit-sheets/zone/${widget.zoneId}/statistics?year=${widget.year}';
      print('Fetching statistics from: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await const FlutterSecureStorage().read(key: 'token')}',
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          throw Exception('Invalid response format: null data');
        }
        print('Parsed data: $data'); // Debug log
        setState(() {
          _statistics = AuditStatistics.fromJson(data);
          print('Monthly stats: ${_statistics!.monthlyStats}'); // Debug log
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to load statistics';
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching statistics: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Map<String, MonthlyStatistics> _getMonthlyDataMap() {
    final Map<String, MonthlyStatistics> monthMap = {};
    
    // Initialize all months with empty data
    for (var month in _allMonths) {
      monthMap[month] = MonthlyStatistics(
        month: _allMonths.indexOf(month) + 1,
        monthName: month,
        totalSubmissions: 0,
        averageScore: 0.0,
        averagePercentage: 0.0,
        totalScore: 0,
        maxPossibleScore: 0,
        submissions: [],
      );
    }

    // Fill in actual data
    if (_statistics != null) {
      print('Filling in actual data for months: ${_statistics!.monthlyStats.map((m) => m.month).toList()}'); // Debug log
      for (var monthData in _statistics!.monthlyStats) {
        print('Processing month: ${monthData.month} with score: ${monthData.averagePercentage}'); // Debug log
        monthMap[monthData.monthName] = monthData;
      }
    }

    return monthMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.zoneId == 'all' ? 'Overall Statistics' : 'Zone Statistics'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _statistics == null
                  ? const Center(child: Text('No statistics available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 24),
                          _buildMonthlyChart(),
                          const SizedBox(height: 24),
                          // _buildScoreDistributionChart(),
                          // const SizedBox(height: 24),
                          // _buildSubmissionsBarChart(),
                          // const SizedBox(height: 24),
                          _buildMonthlyDetails(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSummaryCard() {
    if (_statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No summary data available'),
          ),
        ),
      );
    }

    // Calculate total submissions and average percentage
    final totalSubmissions = _statistics!.monthlyStats.fold(0, (sum, month) => sum + month.totalSubmissions);
    final totalPercentage = _statistics!.monthlyStats.fold(0.0, (sum, month) => sum + month.averagePercentage);
    final averagePercentage = totalSubmissions > 0 ? totalPercentage / _statistics!.monthlyStats.where((m) => m.totalSubmissions > 0).length : 0.0;

    // Find best performing month
    final bestMonth = _statistics!.monthlyStats
        .where((m) => m.totalSubmissions > 0)
        .reduce((a, b) => a.averagePercentage > b.averagePercentage ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.zoneId == 'all' ? 'Overall Summary' : 'Zone Summary',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Submissions',
                  totalSubmissions.toString(),
                  Icons.assignment_turned_in,
                ),
                _buildSummaryItem(
                  'Average Score',
                  '${averagePercentage.toStringAsFixed(1)}%',
                  Icons.score,
                ),
                _buildSummaryItem(
                  'Best Month',
                  bestMonth.monthName,
                  Icons.emoji_events,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    if (_statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No monthly performance data available'),
          ),
        ),
      );
    }

    final monthMap = _getMonthlyDataMap();
    final monthlyData = _allMonths.map((month) => monthMap[month]!).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _allMonths.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _allMonths[value.toInt()],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.averagePercentage);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistributionChart() {
    if (_statistics == null || _statistics!.monthlyStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No score distribution data available'),
          ),
        ),
      );
    }

    // Calculate score distribution
    final scoreRanges = {
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0,
    };

    for (var month in _statistics!.monthlyStats) {
      for (var submission in month.submissions) {
        if (submission.percentage <= 20) {
          scoreRanges['0-20'] = scoreRanges['0-20']! + 1;
        } else if (submission.percentage <= 40) {
          scoreRanges['21-40'] = scoreRanges['21-40']! + 1;
        } else if (submission.percentage <= 60) {
          scoreRanges['41-60'] = scoreRanges['41-60']! + 1;
        } else if (submission.percentage <= 80) {
          scoreRanges['61-80'] = scoreRanges['61-80']! + 1;
        } else {
          scoreRanges['81-100'] = scoreRanges['81-100']! + 1;
        }
      }
    }

    // Check if there's any data to display
    if (scoreRanges.values.every((value) => value == 0)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No score distribution data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: scoreRanges.entries.map((entry) {
                    final color = _getColorForScoreRange(entry.key);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      color: color,
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: scoreRanges.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: _getColorForScoreRange(entry.key),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsBarChart() {
    if (_statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No submission data available'),
          ),
        ),
      );
    }

    final monthMap = _getMonthlyDataMap();
    final monthlyData = _allMonths.map((month) => monthMap[month]!).toList();
    final maxSubmissions = monthlyData
        .map((m) => m.totalSubmissions.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Submissions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSubmissions * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.round()} submissions',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _allMonths.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _allMonths[value.toInt()],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: monthlyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalSubmissions.toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyDetails() {
    if (_statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No monthly details available'),
          ),
        ),
      );
    }

    final monthMap = _getMonthlyDataMap();
    final monthlyData = _allMonths.map((month) => monthMap[month]!).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...monthlyData.map((month) => _buildMonthCard(month)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(MonthlyStatistics month) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          month.monthName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Average Score: ${month.averagePercentage.toStringAsFixed(1)}%',
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submissions: ${month.totalSubmissions}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...month.submissions.map((submission) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Submitted: ${submission.submittedAt.toString().split('.')[0]}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Score: ${submission.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForScoreRange(String range) {
    switch (range) {
      case '0-20':
        return Colors.red;
      case '21-40':
        return Colors.orange;
      case '41-60':
        return Colors.yellow;
      case '61-80':
        return Colors.lightGreen;
      case '81-100':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 