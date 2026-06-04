import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class VehicleAnalysisScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  const VehicleAnalysisScreen({super.key, required this.supabaseService});

  @override
  State<VehicleAnalysisScreen> createState() => _VehicleAnalysisScreenState();
}

class _VehicleAnalysisScreenState extends State<VehicleAnalysisScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.vehicleStream(),
        builder: (context, vSnap) {
          final vehicles = vSnap.data ?? [];
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.supabaseService.servicingStream(),
            builder: (context, sSnap) {
              final servicing = sSnap.data ?? [];
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supabaseService.dieselPurchasesStream(),
                builder: (context, dSnap) {
                  final diesel = dSnap.data ?? [];
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.supabaseService.govtOfficesStream(),
                    builder: (context, oSnap) {
                      final offices = oSnap.data ?? [];
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: widget.supabaseService.bookingTripsStream(),
                        builder: (context, bSnap) {
                          final bookings = bSnap.data ?? [];
                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: widget.supabaseService.profileStream(
                              'driver',
                            ),
                            builder: (context, drSnap) {
                              final drivers = drSnap.data ?? [];
                              return _buildContent(
                                vehicles,
                                servicing,
                                diesel,
                                offices,
                                bookings,
                                drivers,
                              );
                            },
                          );
                        },
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
    List<Map<String, dynamic>> vehicles,
    List<Map<String, dynamic>> servicing,
    List<Map<String, dynamic>> diesel,
    List<Map<String, dynamic>> offices,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> drivers,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;
    double totalPending = 0;
    double totalPaid = 0;

    final vehicleData = <String, Map<String, double>>{};
    for (var v in vehicles) {
      final vId = v['id'] as String;
      final vNum = v['number_plate'] ?? '';
      // Income from offices assigned to this vehicle
      final officeIncome = offices
          .where((o) => o['vehicle_id'] == vId)
          .fold(
            0.0,
            (s, o) =>
                s +
                (double.tryParse(o['monthly_income']?.toString() ?? '0') ?? 0),
          );
      // Income from bookings
      final bookingIncome = bookings
          .where(
            (b) =>
                b['vehicle_id'] == vId &&
                (b['trip_date'] ?? '').startsWith(_selectedMonth),
          )
          .fold(
            0.0,
            (s, b) =>
                s + (double.tryParse(b['amount']?.toString() ?? '0') ?? 0),
          );
      final bookingPending = bookings
          .where(
            (b) => b['vehicle_id'] == vId && b['payment_status'] == 'pending',
          )
          .fold(
            0.0,
            (s, b) =>
                s + (double.tryParse(b['amount']?.toString() ?? '0') ?? 0),
          );
      final bookingPaid = bookings
          .where((b) => b['vehicle_id'] == vId && b['payment_status'] == 'paid')
          .fold(
            0.0,
            (s, b) =>
                s + (double.tryParse(b['amount']?.toString() ?? '0') ?? 0),
          );
      // Expenses: servicing
      final serviceCost = servicing
          .where(
            (s) =>
                s['vehicle_id'] == vId &&
                (s['servicing_date'] ?? '').startsWith(_selectedMonth),
          )
          .fold(
            0.0,
            (s, r) => s + (double.tryParse(r['cost']?.toString() ?? '0') ?? 0),
          );
      // Expenses: diesel
      final dieselCost = diesel
          .where(
            (d) =>
                d['vehicle_id'] == vId &&
                (d['purchase_date'] ?? '').startsWith(_selectedMonth),
          )
          .fold(
            0.0,
            (s, d) =>
                s + (double.tryParse(d['amount']?.toString() ?? '0') ?? 0),
          );
      // Driver salary (find appointed driver)
      double driverCost = 0;
      for (var d in drivers) {
        // Simple: sum salary of all drivers - in real scenario check appointed_vehicles
      }

      final income = officeIncome + bookingIncome;
      final expense = serviceCost + dieselCost;
      final profit = income - expense;

      vehicleData[vId] = {
        'income': income,
        'expense': expense,
        'profit': profit,
        'serviceCost': serviceCost,
        'dieselCost': dieselCost,
        'pending': bookingPending,
        'paid': bookingPaid,
      };

      totalIncome += income;
      totalExpense += expense;
      totalPending += bookingPending;
      totalPaid += bookingPaid;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vehicle Analysis',
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
          // Total P&L cards
          Row(
            children: [
              _summaryCard(
                'Total Income',
                '₹${totalIncome.toStringAsFixed(0)}',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _summaryCard(
                'Total Expense',
                '₹${totalExpense.toStringAsFixed(0)}',
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _summaryCard(
                'Net P&L',
                '₹${(totalIncome - totalExpense).toStringAsFixed(0)}',
                totalIncome - totalExpense >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              _summaryCard(
                'Pending',
                '₹${totalPending.toStringAsFixed(0)}',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Overall pie chart
          const Text(
            'Income vs Expense',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          if (totalIncome + totalExpense > 0)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalIncome,
                          color: Colors.green,
                          title: 'Income',
                          radius: 55,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalExpense > 0 ? totalExpense : 1,
                          color: Colors.red,
                          title: 'Expense',
                          radius: 55,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Individual vehicles
          const Text(
            'Individual Vehicles',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          if (vehicles.isEmpty)
            _emptyState()
          else
            ...vehicles.map((v) {
              final vId = v['id'] as String;
              final vd = vehicleData[vId] ?? {};
              final profit = vd['profit'] ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (profit >= 0 ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: profit >= 0 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${v['car_name']} ${v['number_plate']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'P/L: ₹${profit.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: profit >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _detailRow(
                            'Office Income',
                            '₹${((vd['income'] ?? 0) - (vd['paid'] ?? 0)).toStringAsFixed(0)}',
                            Colors.green,
                          ),
                          _detailRow(
                            'Booking Income',
                            '₹${(vd['paid'] ?? 0).toStringAsFixed(0)}',
                            Colors.green,
                          ),
                          _detailRow(
                            'Servicing Cost',
                            '-₹${(vd['serviceCost'] ?? 0).toStringAsFixed(0)}',
                            Colors.red,
                          ),
                          _detailRow(
                            'Diesel Cost',
                            '-₹${(vd['dieselCost'] ?? 0).toStringAsFixed(0)}',
                            Colors.red,
                          ),
                          _detailRow(
                            'Pending Payments',
                            '₹${(vd['pending'] ?? 0).toStringAsFixed(0)}',
                            Colors.orange,
                          ),
                          const Divider(),
                          _detailRow(
                            'Net Profit/Loss',
                            '₹${profit.toStringAsFixed(0)}',
                            profit >= 0 ? Colors.green : Colors.red,
                            bold: true,
                          ),
                          // Mini pie chart for this vehicle
                          if ((vd['income'] ?? 0) + (vd['expense'] ?? 0) > 0)
                            SizedBox(
                              height: 140,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: vd['income'] ?? 1,
                                      color: Colors.green,
                                      title: 'In',
                                      radius: 40,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: vd['serviceCost'] ?? 0,
                                      color: Colors.orange,
                                      title: 'Serv',
                                      radius: 40,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: vd['dieselCost'] ?? 0,
                                      color: Colors.red,
                                      title: 'Diesel',
                                      radius: 40,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
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

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
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
          Icon(
            Icons.directions_car_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text('No vehicles', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
