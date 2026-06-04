import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class DriverHomeScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final String? driverId;
  final double monthlySalary;
  const DriverHomeScreen({
    super.key,
    required this.supabaseService,
    this.driverId,
    this.monthlySalary = 0,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.attendanceStream(),
        builder: (context, snap) {
          final allAtts = snap.data ?? [];
          final myAtts = widget.driverId != null
              ? allAtts.where((a) => a['driver_id'] == widget.driverId).toList()
              : [];
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
          final monthAtts = myAtts
              .where((a) => (a['date'] ?? '').startsWith(currentMonth))
              .toList();
          final present = monthAtts
              .where((a) => a['status'] == 'present')
              .length;
          final absent = monthAtts.where((a) => a['status'] == 'absent').length;
          final holiday = monthAtts
              .where((a) => a['status'] == 'holiday')
              .length;
          final total = present + absent + holiday;
          final workingDays = present + holiday;
          final salaryPerDay = widget.monthlySalary > 0
              ? widget.monthlySalary / 30
              : 0;
          final earnedSalary = salaryPerDay * workingDays;

          // Today's status
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayAtt = myAtts.where((a) => a['date'] == today).toList();
          final todayStatus = todayAtt.isNotEmpty
              ? todayAtt.first['status']
              : 'not marked';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's attendance card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  color: _statusBgColor(todayStatus),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(todayStatus),
                          color: _statusColor(todayStatus),
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Status',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              todayStatus.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(todayStatus),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              today,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Monthly salary card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Salary (This Month)',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${earnedSalary.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          'of ₹${widget.monthlySalary.toStringAsFixed(0)} (Base)',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('Present', '$present', Colors.green),
                            _statItem('Absent', '$absent', Colors.red),
                            _statItem('Holiday', '$holiday', Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pie chart
                const Text(
                  'Attendance Overview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 10),
                if (total > 0)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: present.toDouble(),
                                    color: Colors.green,
                                    title: '$present',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: absent.toDouble(),
                                    color: Colors.red,
                                    title: '$absent',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: holiday.toDouble(),
                                    color: Colors.blue,
                                    title: '$holiday',
                                    radius: 55,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legend('Present', Colors.green),
                              const SizedBox(width: 16),
                              _legend('Absent', Colors.red),
                              const SizedBox(width: 16),
                              _legend('Holiday', Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No attendance data this month',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'holiday':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _statusBgColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green.withValues(alpha: 0.05);
      case 'absent':
        return Colors.red.withValues(alpha: 0.05);
      case 'holiday':
        return Colors.blue.withValues(alpha: 0.05);
      default:
        return Colors.white;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'holiday':
        return Icons.wb_sunny;
      default:
        return Icons.help_outline;
    }
  }
}
