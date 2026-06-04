import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class DriverAnalysisScreen extends StatefulWidget {
  final AuthService authService;
  final SupabaseService? supabaseService;
  const DriverAnalysisScreen({
    super.key,
    required this.authService,
    this.supabaseService,
  });

  @override
  State<DriverAnalysisScreen> createState() => _DriverAnalysisScreenState();
}

class _DriverAnalysisScreenState extends State<DriverAnalysisScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    if (widget.supabaseService == null) {
      return _buildLegacyView();
    }
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService!.profileStream('driver'),
        builder: (context, dSnap) {
          final drivers = dSnap.data ?? [];
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.supabaseService!.attendanceStream(),
            builder: (context, aSnap) {
              final allAtts = aSnap.data ?? [];
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supabaseService!.salaryAdvancesStream(),
                builder: (context, advSnap) {
                  final allAdvances = advSnap.data ?? [];
                  return _buildContent(drivers, allAtts, allAdvances);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    List<Map<String, dynamic>> drivers,
    List<Map<String, dynamic>> allAtts,
    List<Map<String, dynamic>> allAdvances,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Driver Analysis',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(
                      () =>
                          _selectedMonth = DateFormat('yyyy-MM').format(picked),
                    );
                  }
                },
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  _selectedMonth,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // All drivers summary pie chart
          Builder(
            builder: (_) {
              final monthAtts = allAtts
                  .where((a) => (a['date'] ?? '').startsWith(_selectedMonth))
                  .toList();
              final p = monthAtts.where((a) => a['status'] == 'present').length;
              final ab = monthAtts.where((a) => a['status'] == 'absent').length;
              final h = monthAtts.where((a) => a['status'] == 'holiday').length;
              final total = p + ab + h;
              if (total == 0) return const SizedBox.shrink();
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'All Drivers Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 160,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: p.toDouble(),
                                color: Colors.green,
                                title: '$p P',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              PieChartSectionData(
                                value: ab.toDouble(),
                                color: Colors.red,
                                title: '$ab A',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              PieChartSectionData(
                                value: h.toDouble(),
                                color: Colors.blue,
                                title: '$h H',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend('Present', Colors.green),
                          const SizedBox(width: 12),
                          _legend('Absent', Colors.red),
                          const SizedBox(width: 12),
                          _legend('Holiday', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Individual drivers
          ...drivers.map((driver) {
            final driverId = driver['id'] as String;
            final name = driver['name'] ?? 'Unknown';
            final baseSalary =
                double.tryParse(driver['salary']?.toString() ?? '0') ?? 0;
            final monthAtts = allAtts
                .where(
                  (a) =>
                      a['driver_id'] == driverId &&
                      (a['date'] ?? '').startsWith(_selectedMonth),
                )
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
            final monthAdv = allAdvances
                .where(
                  (a) =>
                      a['driver_id'] == driverId &&
                      (a['advance_date'] ?? '').startsWith(_selectedMonth),
                )
                .toList();
            final totalAdv = monthAdv.fold(
              0.0,
              (s, a) =>
                  s + (double.tryParse(a['amount']?.toString() ?? '0') ?? 0),
            );
            final workingDays = present + holiday;
            final perDay = baseSalary > 0 ? baseSalary / 30 : 0;
            final finalSalary = (perDay * workingDays) - totalAdv;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1A237E),
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'P:$present A:$absent H:$holiday | Salary: ₹${finalSalary.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Individual pie chart
                        if (total > 0)
                          SizedBox(
                            height: 150,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: present.toDouble(),
                                    color: Colors.green,
                                    title: '$present',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: absent.toDouble(),
                                    color: Colors.red,
                                    title: '$absent',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: holiday.toDouble(),
                                    color: Colors.blue,
                                    title: '$holiday',
                                    radius: 45,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Salary breakdown
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              _row(
                                'Base Salary',
                                '₹${baseSalary.toStringAsFixed(0)}',
                              ),
                              _row('Working Days', '$workingDays / 30'),
                              _row(
                                'After Attendance',
                                '₹${(perDay * workingDays).toStringAsFixed(0)}',
                              ),
                              _row(
                                'Advance Taken',
                                '- ₹${totalAdv.toStringAsFixed(0)}',
                              ),
                              const Divider(height: 12),
                              _row(
                                'Final Salary',
                                '₹${finalSalary.toStringAsFixed(0)}',
                                bold: true,
                                color: const Color(0xFF1A237E),
                              ),
                            ],
                          ),
                        ),
                        // Advances list
                        if (monthAdv.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Advances:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          ...monthAdv.map(
                            (a) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '• ${a['reason'] ?? 'N/A'} (${a['advance_date']})',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '₹${a['amount']}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegacyView() {
    final drivers = widget.authService.drivers;
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Performance',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
            ...drivers.map(
              (d) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(child: Text(d.name[0])),
                  title: Text(
                    d.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Vehicle: ${d.vehicleAssigned ?? 'N/A'} | Salary: ₹${d.salary?.toStringAsFixed(0) ?? 'N/A'}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
