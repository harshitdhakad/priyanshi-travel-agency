import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class SalaryManagementScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final bool isDriverView;
  final String? currentDriverId;
  const SalaryManagementScreen({
    super.key,
    required this.supabaseService,
    this.isDriverView = false,
    this.currentDriverId,
  });

  @override
  State<SalaryManagementScreen> createState() => _SalaryManagementScreenState();
}

class _SalaryManagementScreenState extends State<SalaryManagementScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  void _showAdvanceDialog({String? driverId, String? driverName}) {
    final amtCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          driverName != null ? 'Advance for $driverName' : 'Add Advance',
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (what for?)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final p = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (p != null) {
                  dateCtrl.text = DateFormat('yyyy-MM-dd').format(p);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amtCtrl.text.isEmpty || driverId == null) return;
              await widget.supabaseService.addSalaryAdvance(
                driverId: driverId,
                amount: double.tryParse(amtCtrl.text) ?? 0,
                reason: reasonCtrl.text,
                date: dateCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Advance added'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.profileStream('driver'),
        builder: (context, driverSnap) {
          final drivers = driverSnap.data ?? [];
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.supabaseService.attendanceStream(),
            builder: (context, attSnap) {
              final allAtts = attSnap.data ?? [];
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supabaseService.salaryAdvancesStream(),
                builder: (context, advSnap) {
                  final allAdvances = advSnap.data ?? [];
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.supabaseService.salaryPaymentsStream(),
                    builder: (context, paySnap) {
                      final allPayments = paySnap.data ?? [];
                      return _buildContent(
                        drivers,
                        allAtts,
                        allAdvances,
                        allPayments,
                      );
                    },
                  );
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
    List<Map<String, dynamic>> allPayments,
  ) {
    var displayDrivers = drivers;
    if (widget.isDriverView && widget.currentDriverId != null) {
      displayDrivers = drivers
          .where((d) => d['id'] == widget.currentDriverId)
          .toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Salary Management',
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
          const SizedBox(height: 12),
          ...displayDrivers.map((driver) {
            final driverId = driver['id'] as String;
            final driverName = driver['name'] ?? 'Unknown';
            final baseSalary =
                double.tryParse(driver['salary']?.toString() ?? '0') ?? 0;
            // Attendance for this month
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
            final workingDays = present + holiday;
            final perDay = baseSalary > 0 ? baseSalary / 30 : 0;
            final attendanceSalary = perDay * workingDays;
            // Advances this month
            final monthAdvances = allAdvances
                .where(
                  (a) =>
                      a['driver_id'] == driverId &&
                      (a['advance_date'] ?? '').startsWith(_selectedMonth),
                )
                .toList();
            final totalAdvance = monthAdvances.fold(
              0.0,
              (s, a) =>
                  s + (double.tryParse(a['amount']?.toString() ?? '0') ?? 0),
            );
            // Final salary
            final finalSalary = attendanceSalary - totalAdvance;
            // Payment status
            final payment = allPayments
                .where(
                  (p) =>
                      p['driver_id'] == driverId &&
                      p['month'] == _selectedMonth,
                )
                .toList();
            final isPaid =
                payment.isNotEmpty && payment.first['is_paid'] == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF1A237E),
                              child: Text(
                                driverName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Base: ₹${baseSalary.toStringAsFixed(0)}/month',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (!widget.isDriverView)
                          Column(
                            children: [
                              if (!isPaid)
                                ElevatedButton(
                                  onPressed: () =>
                                      widget.supabaseService.markSalaryPaid(
                                        driverId: driverId,
                                        month: _selectedMonth,
                                        amount: finalSalary,
                                        isPaid: true,
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Mark Paid',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                )
                              else
                                const Chip(
                                  label: Text(
                                    'PAID',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                            Colors.grey,
                          ),
                          _row(
                            'Working Days',
                            '$workingDays / 30',
                            Colors.blue,
                          ),
                          _row(
                            'Present: $present | Absent: $absent | Holiday: $holiday',
                            '',
                            Colors.grey,
                          ),
                          _row(
                            'After Attendance',
                            '₹${attendanceSalary.toStringAsFixed(0)}',
                            Colors.blue,
                          ),
                          _row(
                            'Advance Taken',
                            '- ₹${totalAdvance.toStringAsFixed(0)}',
                            Colors.red,
                          ),
                          const Divider(height: 16),
                          _row(
                            'Final Salary',
                            '₹${finalSalary.toStringAsFixed(0)}',
                            isPaid ? Colors.green : const Color(0xFF1A237E),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Advance button & list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Advances This Month',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (!widget.isDriverView ||
                            widget.currentDriverId == driverId)
                          TextButton.icon(
                            onPressed: () => _showAdvanceDialog(
                              driverId: driverId,
                              driverName: driverName,
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text(
                              'Add Advance',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    if (monthAdvances.isEmpty)
                      Text(
                        'No advances',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      )
                    else
                      ...monthAdvances.map(
                        (adv) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${adv['reason'] ?? 'No reason'} — ${adv['advance_date']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '₹${adv['amount']}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (!widget.isDriverView)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await widget.supabaseService
                                        .deleteSalaryAdvance(adv['id']);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
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
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
