import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/colors.dart';
import '../models/audit_statistics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config.dart';

class AuditStatisticsScreen extends StatefulWidget {
  final String zoneId;

  const AuditStatisticsScreen({
    super.key,
    required this.zoneId,
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

      const String baseUrl = AppConfig.apiBaseUrl;
      final url = widget.zoneId == 'all' 
          ? '$baseUrl/audit-sheets/statistics'
          : '$baseUrl/audit-sheets/zone/${widget.zoneId}/statistics';
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
        year: DateTime.now().year,
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
      print('Filling in actual data for months: ${_statistics!.monthlyStats.map((m) => m.monthName).toList()}'); // Debug log
      for (var monthData in _statistics!.monthlyStats) {
        print('Processing month: ${monthData.monthName} with score: ${monthData.averagePercentage}'); // Debug log
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
                          _buildSubmissionsBarChart(),
                          const SizedBox(height: 24),
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

    // Calculate total submissions and scores
    final totalSubmissions = _statistics!.monthlyStats.fold(0, (sum, month) => sum + month.totalSubmissions);
    final totalScore = _statistics!.monthlyStats.fold(0, (sum, month) => sum + month.totalScore);
    final totalMaxScore = _statistics!.monthlyStats.fold(0, (sum, month) => sum + month.maxPossibleScore);
    
    // Calculate overall average percentage from individual submissions
    double totalPercentage = 0.0;
    int submissionCount = 0;
    
    for (var month in _statistics!.monthlyStats) {
      for (var submission in month.submissions) {
        totalPercentage += submission.percentage;
        submissionCount++;
      }
    }
    
    final averagePercentage = submissionCount > 0 ? totalPercentage / submissionCount : 0.0;

    // Find best performing month based on calculated average percentage
    final monthsWithData = _statistics!.monthlyStats.where((m) => m.totalSubmissions > 0);
    MonthlyStatistics? bestMonth;
    
    if (monthsWithData.isNotEmpty) {
      double bestAverage = 0.0;
      for (var month in monthsWithData) {
        double monthAverage = 0.0;
        for (var submission in month.submissions) {
          monthAverage += submission.percentage;
        }
        monthAverage = month.submissions.isNotEmpty ? monthAverage / month.submissions.length : 0.0;
        
        if (monthAverage > bestAverage) {
          bestAverage = monthAverage;
          bestMonth = month;
        }
      }
    }

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
                  bestMonth?.monthName ?? 'N/A',
                  Icons.emoji_events,
                ),
              ],
            ),
            if (totalMaxScore > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Score',
                    '$totalScore/$totalMaxScore',
                    Icons.analytics,
                  ),
                  _buildSummaryItem(
                    'Success Rate',
                    '${((totalScore / totalMaxScore) * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ],
              ),
            ],
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

    // Only show months that have data
    final monthsWithData = _statistics!.monthlyStats.where((month) => month.totalSubmissions > 0).toList();
    
    if (monthsWithData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No audit submissions found for this period'),
          ),
        ),
      );
    }

    // Sort months by year and month
    monthsWithData.sort((a, b) {
      if (a.year != b.year) return a.year.compareTo(b.year);
      return a.month.compareTo(b.month);
    });

    final maxSubmissions = monthsWithData
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
                        final month = monthsWithData[group.x];
                        // Calculate average percentage for tooltip
                        double monthAveragePercentage = 0.0;
                        if (month.submissions.isNotEmpty) {
                          double totalPercentage = 0.0;
                          for (var submission in month.submissions) {
                            totalPercentage += submission.percentage;
                          }
                          monthAveragePercentage = totalPercentage / month.submissions.length;
                        }
                        return BarTooltipItem(
                          '${month.monthName} ${month.year}\n${rod.toY.round()} submissions\nAvg: ${monthAveragePercentage.toStringAsFixed(1)}%',
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
                          if (value.toInt() >= 0 && value.toInt() < monthsWithData.length) {
                            final month = monthsWithData[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${month.monthName}\n${month.year}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
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
                  barGroups: monthsWithData.asMap().entries.map((entry) {
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

    // Only show months that have data
    final monthsWithData = _statistics!.monthlyStats.where((month) => month.totalSubmissions > 0).toList();

    if (monthsWithData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No audit submissions found for this period'),
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
              'Monthly Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...monthsWithData.map((month) => _buildMonthCard(month)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(MonthlyStatistics month) {
    // Calculate average percentage from individual submissions
    double monthAveragePercentage = 0.0;
    if (month.submissions.isNotEmpty) {
      double totalPercentage = 0.0;
      for (var submission in month.submissions) {
        totalPercentage += submission.percentage;
      }
      monthAveragePercentage = totalPercentage / month.submissions.length;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          '${month.monthName} ${month.year}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Average Score: ${monthAveragePercentage.toStringAsFixed(1)}% (${month.totalSubmissions} submissions)',
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
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem('Total Score', '${month.totalScore}/${month.maxPossibleScore}'),
                    ),
                    Expanded(
                      child: _buildStatItem('Average Score', '${month.averageScore.toStringAsFixed(1)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Submissions:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...month.submissions.map((submission) => _buildSubmissionItem(submission)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionItem(Submission submission) {
    final date = submission.submittedAt.toLocal();
    final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  submission.submittedByName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                submission.submissionId.substring(0, 8),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Submitted: $formattedDate',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.score, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Score: ${submission.totalScore} (${submission.percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 