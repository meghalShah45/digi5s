import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/colors.dart';
import '../../../features/audit/models/audit_statistics.dart';
import '../../../models/zone_response.dart';
import '../../providers/zone_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuditStatisticsByZoneScreen extends ConsumerStatefulWidget {
  const AuditStatisticsByZoneScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuditStatisticsByZoneScreen> createState() => _AuditStatisticsByZoneScreenState();
}

class _AuditStatisticsByZoneScreenState extends ConsumerState<AuditStatisticsByZoneScreen> {
  bool _isLoadingStatistics = false;
  AuditStatistics? _statistics;
  ZoneData? _selectedZone;
  final List<String> _allMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize zones if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final zonesState = ref.read(zoneListProvider);
      if (zonesState is AsyncData && zonesState.value == null) {
        ref.read(zoneListProvider.notifier).fetchZones();
      }
    });
  }

  Future<void> _fetchStatistics(String zoneId) async {
    try {
      setState(() {
        _isLoadingStatistics = true;
      });

      const String baseUrl = 'http://localhost:8081';
      final url = zoneId == 'all' 
          ? '$baseUrl/audit-sheets/statistics'
          : '$baseUrl/audit-sheets/zone/$zoneId/statistics';
      
      print('Fetching statistics from: $url');

      final token = await const FlutterSecureStorage().read(key: 'token');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          throw Exception('Invalid response format: null data');
        }
        
        setState(() {
          _statistics = AuditStatistics.fromJson(data);
          _isLoadingStatistics = false;
        });
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to load statistics';
        setState(() {
          _isLoadingStatistics = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching statistics: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoadingStatistics = false;
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
      for (var monthData in _statistics!.monthlyStats) {
        monthMap[monthData.monthName] = monthData;
      }
    }

    return monthMap;
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zoneListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Audit Statistics by Zone'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: zonesAsync.when(
        data: (zones) {
          if (zones == null || zones.isEmpty) {
            return const Center(
              child: Text('No zones available'),
            );
          }
          
          return Column(
            children: [
              _buildZoneSelector(zones),
              if (_selectedZone != null || _statistics != null) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: _buildStatisticsContent(),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Select a zone to view statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choose a zone from the dropdown above to see audit statistics',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading zones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(zoneListProvider.notifier).fetchZones();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneSelector(List<ZoneData> zones) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ZoneData?>(
            value: _selectedZone,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Choose a zone'),
            items: [
              const DropdownMenuItem<ZoneData?>(
                value: null,
                child: Text('All Zones'),
              ),
              ...zones.map((zone) => DropdownMenuItem<ZoneData?>(
                value: zone,
                child: Text(zone.name),
              )).toList(),
            ],
            onChanged: (ZoneData? zone) {
              setState(() {
                _selectedZone = zone;
                _statistics = null; // Clear previous statistics
              });
              
              if (zone != null) {
                _fetchStatistics(zone.id);
              } else {
                _fetchStatistics('all');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (_isLoadingStatistics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statistics == null) {
      return const Center(
        child: Text('No statistics available for the selected zone'),
      );
    }

    return SingleChildScrollView(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedZone?.name ?? 'All Zones',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Submissions',
                    totalSubmissions.toString(),
                    Icons.assignment,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Average Score',
                    '${averagePercentage.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Score',
                    '$totalScore/$totalMaxScore',
                    Icons.score,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Best Month',
                    bestMonth?.monthName ?? 'N/A',
                    Icons.star,
                    AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsBarChart() {
    final monthlyData = _getMonthlyDataMap();
    final months = monthlyData.keys.toList();
    final submissions = months.map((month) => monthlyData[month]!.totalSubmissions.toDouble()).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Submissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: submissions.isNotEmpty ? submissions.reduce((a, b) => a > b ? a : b) + 2 : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()].substring(0, 3),
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
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    months.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: submissions[index],
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyDetails() {
    final monthlyData = _getMonthlyDataMap();
    final monthsWithData = monthlyData.values.where((month) => month.totalSubmissions > 0).toList();

    if (monthsWithData.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No monthly data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...monthsWithData.map((month) => _buildMonthCard(month)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(MonthlyStatistics month) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month.monthName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${month.totalSubmissions} submissions',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthStat(
                  'Average Score',
                  '${month.averagePercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMonthStat(
                  'Total Score',
                  '${month.totalScore}/${month.maxPossibleScore}',
                  Icons.score,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 