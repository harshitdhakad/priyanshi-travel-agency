import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
import '../../services/localization_service.dart';
import '../../widgets/credits_footer.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final bool isDriverView;
  final String? currentDriverId;
  const AttendanceScreen({
    super.key,
    required this.supabaseService,
    this.isDriverView = false,
    this.currentDriverId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedDriverId;
  DateTime _selectedDate = DateTime.now();
  bool _didInitDate = false;
  final AppLocalizations _loc = AppLocalizations();

  @override
  void initState() {
    super.initState();
    _selectedDriverId = widget.currentDriverId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset to today every time screen becomes visible
    if (!_didInitDate) {
      _selectedDate = DateTime.now();
      _didInitDate = true;
    }
  }

  Future<void> _markAttendance(String driverId, String status) async {
    try {
      await widget.supabaseService.markAttendance(
        driverId: driverId,
        status: status,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        markedBy: widget.isDriverView ? 'self' : 'director',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: AppTheme.background,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.supabaseService.profileStream('driver'),
              builder: (context, driverSnap) {
                final drivers = driverSnap.data ?? [];
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.supabaseService.attendanceStream(),
                  builder: (context, attSnap) {
                    final allAttendance = attSnap.data ?? [];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date selector
                          Row(
                            children: [
                              Text(
                                '${_loc.t('date')}: ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Driver selector for non-driver view
                          if (!widget.isDriverView) ...[
                            Text(
                              _loc.t('mark_attendance'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...drivers.map((d) {
                              final driverAtts = allAttendance
                                  .where(
                                    (a) =>
                                        a['driver_id'] == d['id'] &&
                                        a['date'] ==
                                            DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(_selectedDate),
                                  )
                                  .toList();
                              final currentStatus = driverAtts.isNotEmpty
                                  ? driverAtts.first['status']
                                  : null;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _statusColor(
                                          currentStatus,
                                        ),
                                        child: Icon(
                                          _statusIcon(currentStatus),
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          d['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      _attButton(
                                        d['id'],
                                        'present',
                                        'P',
                                        Colors.green,
                                        currentStatus == 'present',
                                      ),
                                      const SizedBox(width: 4),
                                      _attButton(
                                        d['id'],
                                        'absent',
                                        'A',
                                        Colors.red,
                                        currentStatus == 'absent',
                                      ),
                                      const SizedBox(width: 4),
                                      _attButton(
                                        d['id'],
                                        'holiday',
                                        'H',
                                        Colors.blue,
                                        currentStatus == 'holiday',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],

                          // Self marking for drivers
                          if (widget.isDriverView &&
                              widget.currentDriverId != null) ...[
                            Text(
                              _loc.t('mark_my_attendance'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                final myAtts = allAttendance
                                    .where(
                                      (a) =>
                                          a['driver_id'] ==
                                              widget.currentDriverId &&
                                          a['date'] ==
                                              DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(_selectedDate),
                                    )
                                    .toList();
                                final currentStatus = myAtts.isNotEmpty
                                    ? myAtts.first['status']
                                    : null;
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _attButtonLarge(
                                          widget.currentDriverId!,
                                          'present',
                                          'Present',
                                          Colors.green,
                                          currentStatus == 'present',
                                        ),
                                        _attButtonLarge(
                                          widget.currentDriverId!,
                                          'absent',
                                          'Absent',
                                          Colors.red,
                                          currentStatus == 'absent',
                                        ),
                                        _attButtonLarge(
                                          widget.currentDriverId!,
                                          'holiday',
                                          'Holiday',
                                          Colors.blue,
                                          currentStatus == 'holiday',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Attendance pie chart
                          Text(
                            _loc.t('attendance_overview'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!widget.isDriverView)
                            // All drivers pie chart
                            _buildAllDriversChart(drivers, allAttendance)
                          else
                            // Individual driver chart
                            _buildSingleDriverChart(
                              widget.currentDriverId!,
                              allAttendance,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const CreditsFooter(),
      ],
    );
  }

  Widget _attButton(
    String driverId,
    String status,
    String label,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _markAttendance(driverId, status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _attButtonLarge(
    String driverId,
    String status,
    String label,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _markAttendance(driverId, status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAllDriversChart(
    List<Map<String, dynamic>> drivers,
    List<Map<String, dynamic>> allAttendance,
  ) {
    final totalPresent = allAttendance
        .where((a) => a['status'] == 'present')
        .length;
    final totalAbsent = allAttendance
        .where((a) => a['status'] == 'absent')
        .length;
    final totalHoliday = allAttendance
        .where((a) => a['status'] == 'holiday')
        .length;
    final total = totalPresent + totalAbsent + totalHoliday;

    if (total == 0) return _emptyState('No attendance records yet');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'All Drivers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalPresent.toDouble(),
                      color: Colors.green,
                      title: '$totalPresent',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: totalAbsent.toDouble(),
                      color: Colors.red,
                      title: '$totalAbsent',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: totalHoliday.toDouble(),
                      color: Colors.blue,
                      title: '$totalHoliday',
                      radius: 60,
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
    );
  }

  Widget _buildSingleDriverChart(
    String driverId,
    List<Map<String, dynamic>> allAttendance,
  ) {
    final driverAtts = allAttendance
        .where((a) => a['driver_id'] == driverId)
        .toList();
    final present = driverAtts.where((a) => a['status'] == 'present').length;
    final absent = driverAtts.where((a) => a['status'] == 'absent').length;
    final holiday = driverAtts.where((a) => a['status'] == 'holiday').length;
    final total = present + absent + holiday;

    if (total == 0) return _emptyState('No attendance records yet');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'My Attendance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: present.toDouble(),
                      color: Colors.green,
                      title: '$present',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: absent.toDouble(),
                      color: Colors.red,
                      title: '$absent',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: holiday.toDouble(),
                      color: Colors.blue,
                      title: '$holiday',
                      radius: 60,
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
                _legend('Present ($present)', Colors.green),
                const SizedBox(width: 16),
                _legend('Absent ($absent)', Colors.red),
                const SizedBox(width: 16),
                _legend('Holiday ($holiday)', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
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

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'present':
        return Icons.check;
      case 'absent':
        return Icons.close;
      case 'holiday':
        return Icons.wb_sunny;
      default:
        return Icons.help_outline;
    }
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
