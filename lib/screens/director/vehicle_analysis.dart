import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/supabase_service.dart';
import '../../services/government_pdf_service.dart';
import 'package:intl/intl.dart';

class VehicleAnalysisScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  const VehicleAnalysisScreen({super.key, required this.supabaseService});

  @override
  State<VehicleAnalysisScreen> createState() => _VehicleAnalysisScreenState();
}

class _VehicleAnalysisScreenState extends State<VehicleAnalysisScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String? _mileageVehicleId;
  DateTime _mileageFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _mileageTo = DateTime.now();
  bool _generatingMileagePdf = false;

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
                          // Avg mileage for this vehicle this month
                          Builder(
                            builder: (_) {
                              final vDiesel =
                                  diesel
                                      .where(
                                        (d) =>
                                            d['vehicle_id'] == vId &&
                                            (d['purchase_date'] ?? '')
                                                .startsWith(_selectedMonth),
                                      )
                                      .toList()
                                    ..sort(
                                      (a, b) => (a['purchase_date'] ?? '')
                                          .compareTo(b['purchase_date'] ?? ''),
                                    );
                              String avgMileageStr = '-';
                              if (vDiesel.length >= 2) {
                                double totalMileage = 0;
                                int count = 0;
                                for (int i = 1; i < vDiesel.length; i++) {
                                  final prevOdo =
                                      double.tryParse(
                                        vDiesel[i - 1]['odometer_reading']
                                                ?.toString() ??
                                            '0',
                                      ) ??
                                      0;
                                  final currOdo =
                                      double.tryParse(
                                        vDiesel[i]['odometer_reading']
                                                ?.toString() ??
                                            '0',
                                      ) ??
                                      0;
                                  final prevLiters =
                                      double.tryParse(
                                        vDiesel[i - 1]['liters']?.toString() ??
                                            '0',
                                      ) ??
                                      0;
                                  final km = currOdo - prevOdo;
                                  if (km > 0 && prevLiters > 0) {
                                    totalMileage += km / prevLiters;
                                    count++;
                                  }
                                }
                                if (count > 0)
                                  avgMileageStr =
                                      '${(totalMileage / count).toStringAsFixed(1)} KM/L';
                              }
                              return _detailRow(
                                'Avg Mileage (Month)',
                                avgMileageStr,
                                Colors.deepPurple,
                                bold: true,
                              );
                            },
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

          // ── Diesel Mileage Analysis Section ──
          const SizedBox(height: 20),
          const Text(
            'Diesel & Mileage Analysis',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle selector
                  DropdownButtonFormField<String>(
                    initialValue: _mileageVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Select Vehicle',
                      border: OutlineInputBorder(),
                    ),
                    items: vehicles
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text(
                              '${v['car_name'] ?? ''} ${v['number_plate'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _mileageVehicleId = v),
                  ),
                  const SizedBox(height: 12),
                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _mileageFrom,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null)
                              setState(() => _mileageFrom = picked);
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(_mileageFrom),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'to',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _mileageTo,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null)
                              setState(() => _mileageTo = picked);
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(_mileageTo),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mileage stats
                  if (_mileageVehicleId != null)
                    _buildMileageStats(vehicles, diesel),
                  const SizedBox(height: 8),
                  // Generate PDF button
                  if (_mileageVehicleId != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatingMileagePdf
                            ? null
                            : () => _generateMileagePdf(vehicles, diesel),
                        icon: _generatingMileagePdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(
                          _generatingMileagePdf
                              ? 'Generating...'
                              : 'Generate Mileage PDF',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMileageStats(
    List<Map<String, dynamic>> vehicles,
    List<Map<String, dynamic>> diesel,
  ) {
    final vId = _mileageVehicleId!;
    final vehicle = vehicles.firstWhere(
      (v) => v['id'] == vId,
      orElse: () => <String, dynamic>{},
    );
    final fromDate = DateFormat('yyyy-MM-dd').format(_mileageFrom);
    final toDate = DateFormat('yyyy-MM-dd').format(_mileageTo);
    final vDiesel =
        diesel
            .where(
              (d) =>
                  d['vehicle_id'] == vId &&
                  (d['purchase_date'] ?? '') >= fromDate &&
                  (d['purchase_date'] ?? '') <= toDate,
            )
            .toList()
          ..sort(
            (a, b) =>
                (a['purchase_date'] ?? '').compareTo(b['purchase_date'] ?? ''),
          );

    double totalLiters = 0;
    double totalAmount = 0;
    double totalKm = 0;
    int mileageCount = 0;
    double totalMileage = 0;

    for (final p in vDiesel) {
      totalLiters += (double.tryParse(p['liters']?.toString() ?? '0') ?? 0);
      totalAmount += (double.tryParse(p['amount']?.toString() ?? '0') ?? 0);
    }
    for (int i = 1; i < vDiesel.length; i++) {
      final prevOdo =
          double.tryParse(
            vDiesel[i - 1]['odometer_reading']?.toString() ?? '0',
          ) ??
          0;
      final currOdo =
          double.tryParse(vDiesel[i]['odometer_reading']?.toString() ?? '0') ??
          0;
      final prevLiters =
          double.tryParse(vDiesel[i - 1]['liters']?.toString() ?? '0') ?? 0;
      final km = currOdo - prevOdo;
      if (km > 0 && prevLiters > 0) {
        totalKm += km;
        totalMileage += km / prevLiters;
        mileageCount++;
      }
    }
    final avgMileage = mileageCount > 0
        ? (totalMileage / mileageCount).toStringAsFixed(1)
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mileage Summary',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _miniStat(
              'Diesel',
              '${totalLiters.toStringAsFixed(1)} L',
              Colors.blue,
            ),
            const SizedBox(width: 6),
            _miniStat(
              'Amount',
              '₹${totalAmount.toStringAsFixed(0)}',
              Colors.red,
            ),
            const SizedBox(width: 6),
            _miniStat('KM', '${totalKm.toStringAsFixed(0)}', Colors.green),
            const SizedBox(width: 6),
            _miniStat('Avg', '$avgMileage KM/L', Colors.deepPurple),
          ],
        ),
        if (vDiesel.length < 2)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Need at least 2 purchases to calculate mileage',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Future<void> _generateMileagePdf(
    List<Map<String, dynamic>> vehicles,
    List<Map<String, dynamic>> diesel,
  ) async {
    if (_mileageVehicleId == null) return;
    setState(() => _generatingMileagePdf = true);
    try {
      final vId = _mileageVehicleId!;
      final vehicle = vehicles.firstWhere(
        (v) => v['id'] == vId,
        orElse: () => <String, dynamic>{},
      );
      final fromDate = DateFormat('yyyy-MM-dd').format(_mileageFrom);
      final toDate = DateFormat('yyyy-MM-dd').format(_mileageTo);
      final vDiesel = diesel
          .where(
            (d) =>
                d['vehicle_id'] == vId &&
                (d['purchase_date'] ?? '') >= fromDate &&
                (d['purchase_date'] ?? '') <= toDate,
          )
          .toList();

      if (vDiesel.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No diesel purchases in this date range'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pdfBytes = await GovernmentPdfService.generateDieselMileagePdf(
        vehicleName: vehicle['car_name'] ?? 'Unknown',
        vehicleNumber: vehicle['number_plate'] ?? 'Unknown',
        agencyName: 'Priyanshi Travel Agency',
        periodLabel:
            '${DateFormat('dd MMM yyyy').format(_mileageFrom)} - ${DateFormat('dd MMM yyyy').format(_mileageTo)}',
        purchases: vDiesel,
      );

      final dir = await getTemporaryDirectory();
      final safeName = (vehicle['number_plate'] ?? 'vehicle')
          .toString()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File(
        '${dir.path}/diesel_mileage_${safeName}_${fromDate}_to_${toDate}.pdf',
      );
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Diesel Mileage Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _generatingMileagePdf = false);
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
