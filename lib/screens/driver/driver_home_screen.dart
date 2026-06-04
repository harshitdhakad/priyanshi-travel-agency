import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
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
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendance section
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.supabaseService.attendanceStream(),
              builder: (context, snap) {
                final allAtts = snap.data ?? [];
                final myAtts = widget.driverId != null
                    ? allAtts
                          .where((a) => a['driver_id'] == widget.driverId)
                          .toList()
                    : [];
                final currentMonth = DateFormat(
                  'yyyy-MM',
                ).format(DateTime.now());
                final monthAtts = myAtts
                    .where((a) => (a['date'] ?? '').startsWith(currentMonth))
                    .toList();
                final present = monthAtts
                    .where((a) => a['status'] == 'present')
                    .length;
                final absent = monthAtts
                    .where((a) => a['status'] == 'absent')
                    .length;
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
                final todayAtt = myAtts
                    .where((a) => a['date'] == today)
                    .toList();
                final todayStatus = todayAtt.isNotEmpty
                    ? todayAtt.first['status']
                    : 'not marked';

                return Column(
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
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${earnedSalary.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
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
                                _statItem(
                                  'Present',
                                  '$present',
                                  AppTheme.success,
                                ),
                                _statItem('Absent', '$absent', AppTheme.error),
                                _statItem(
                                  'Holiday',
                                  '$holiday',
                                  AppTheme.secondary,
                                ),
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
                        color: AppTheme.primary,
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
                                        color: AppTheme.success,
                                        title: '$present',
                                        radius: 55,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: absent.toDouble(),
                                        color: AppTheme.error,
                                        title: '$absent',
                                        radius: 55,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: holiday.toDouble(),
                                        color: AppTheme.secondary,
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
                                  _legend('Present', AppTheme.success),
                                  const SizedBox(width: 16),
                                  _legend('Absent', AppTheme.error),
                                  const SizedBox(width: 16),
                                  _legend('Holiday', AppTheme.secondary),
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
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 40,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No attendance data this month',
                              style: TextStyle(color: AppTheme.textHint),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Assigned Bookings
            const Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.driverId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supabaseService.driverBookingsStream(
                  widget.driverId!,
                ),
                builder: (context, snap) {
                  final bookings = snap.data ?? [];
                  if (bookings.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.book_online_outlined,
                            size: 36,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No bookings assigned',
                            style: TextStyle(color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: bookings.take(5).map((b) {
                      final status = b['status']?.toString() ?? 'pending';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: AppTheme.success,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            b['customer_name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${b['pickup_location'] ?? ''} → ${b['drop_location'] ?? ''}\n${b['booking_date'] ?? ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'confirmed'
                                  ? AppTheme.success
                                  : status == 'completed'
                                  ? AppTheme.primary
                                  : AppTheme.warning,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Assigned Vehicles from Office
            const Text(
              'Office Assignments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.driverId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supabaseService.driverAssignmentsStream(
                  widget.driverId!,
                ),
                builder: (context, snap) {
                  final assignments = snap.data ?? [];
                  if (assignments.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 36,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No office assignments',
                            style: TextStyle(color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: assignments.take(5).map((a) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.assignment,
                              color: AppTheme.accent,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            a['vehicle_number']?.toString() ?? 'Vehicle',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'Assigned: ${a['assigned_date'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
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
        return AppTheme.success;
      case 'absent':
        return AppTheme.error;
      case 'holiday':
        return AppTheme.secondary;
      default:
        return AppTheme.textHint;
    }
  }

  Color _statusBgColor(String? status) {
    switch (status) {
      case 'present':
        return AppTheme.success.withValues(alpha: 0.05);
      case 'absent':
        return AppTheme.error.withValues(alpha: 0.05);
      case 'holiday':
        return AppTheme.secondary.withValues(alpha: 0.05);
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
