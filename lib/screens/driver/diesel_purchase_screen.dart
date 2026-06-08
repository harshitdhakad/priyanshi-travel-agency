import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
import 'package:intl/intl.dart';

class DieselPurchaseScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final String? driverId;
  const DieselPurchaseScreen({
    super.key,
    required this.supabaseService,
    this.driverId,
  });

  @override
  State<DieselPurchaseScreen> createState() => _DieselPurchaseScreenState();
}

class _DieselPurchaseScreenState extends State<DieselPurchaseScreen> {
  List<Map<String, dynamic>> _purchases = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.supabaseService.getDieselPurchases(
        driverId: widget.driverId,
      );
      if (!mounted) return;
      setState(() {
        _purchases = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showAddDiesel() async {
    final vehicles = await widget.supabaseService.getVehicles();
    if (!mounted) return;

    // Auto-select driver's assigned vehicle
    String? selVehicle;
    if (widget.driverId != null && vehicles.isNotEmpty) {
      final match = vehicles.where(
        (v) => v['assigned_driver_id'] == widget.driverId,
      );
      if (match.isNotEmpty) {
        selVehicle = match.first['id'] as String;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final amtCtrl = TextEditingController();
        final litersCtrl = TextEditingController();
        final odoCtrl = TextEditingController();
        final dateCtrl = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Diesel Purchase',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selVehicle,
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
                    onChanged: (v) => setS(() => selVehicle = v),
                  ),
                  const SizedBox(height: 10),
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
                    controller: litersCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Liters',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: odoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Odometer Reading (KM)',
                      hintText: 'Current odometer KM',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed, size: 18),
                    ),
                    keyboardType: TextInputType.number,
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
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (selVehicle == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a vehicle'),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                          return;
                        }
                        if (amtCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter amount'),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                          return;
                        }
                        setS(() => saving = true);
                        try {
                          final vehicle = vehicles.firstWhere(
                            (v) => v['id'] == selVehicle,
                            orElse: () => <String, dynamic>{},
                          );
                          await widget.supabaseService.addDieselPurchase(
                            driverId: widget.driverId,
                            vehicleId: selVehicle,
                            vehicleNumber: vehicle['number_plate'] as String?,
                            amount: double.tryParse(amtCtrl.text) ?? 0,
                            liters: double.tryParse(litersCtrl.text),
                            odometerReading: double.tryParse(odoCtrl.text),
                            date: dateCtrl.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          // Reload data after adding
                          await _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Diesel purchase added'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setS(() => saving = false);
                          if (mounted) {
                            final errStr = e.toString();
                            final isRls =
                                errStr.contains('row-level security') ||
                                errStr.contains('42501');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isRls
                                      ? 'RLS is blocking diesel_purchases. Go to Supabase SQL Editor and run: ALTER TABLE diesel_purchases DISABLE ROW LEVEL SECURITY;'
                                      : 'Error saving: $errStr',
                                ),
                                backgroundColor: isRls
                                    ? Colors.deepOrange
                                    : AppTheme.error,
                                duration: Duration(seconds: isRls ? 8 : 4),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Error loading diesel purchases',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    var purchases = _purchases;
    // Helper functions for safe date handling
    String getDateStr(dynamic val) {
      if (val == null) return '';
      if (val is DateTime) return val.toIso8601String().split('T')[0];
      return val.toString();
    }

    String getDisplayDate(dynamic val) {
      if (val == null) return 'N/A';
      if (val is DateTime) return DateFormat('yyyy-MM-dd').format(val);
      return val.toString();
    }

    // Check for 3-day gap notification
    String? warningMsg;
    if (purchases.isNotEmpty) {
      try {
        final lastDateStr = getDateStr(purchases.first['purchase_date']);
        if (lastDateStr.isNotEmpty) {
          final lastDate = DateTime.parse(lastDateStr);
          final daysSince = DateTime.now().difference(lastDate).inDays;
          if (daysSince >= 3) {
            warningMsg = 'No diesel purchase in last $daysSince days!';
          }
        }
      } catch (_) {}
    } else {
      warningMsg = 'No diesel purchases recorded yet!';
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
                'Diesel Purchases',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddDiesel,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (warningMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningMsg,
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (purchases.isEmpty)
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
                    Icons.local_gas_station_outlined,
                    size: 40,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No diesel purchases',
                    style: TextStyle(color: AppTheme.textHint),
                  ),
                ],
              ),
            )
          else
            ...List<Map<String, dynamic>>.from(
              purchases,
            ).reversed.toList().asMap().entries.map((entry) {
              final p = entry.value;
              final pDateStr = getDateStr(p['purchase_date']);
              // Find previous purchase for same vehicle to calc mileage
              String? mileageStr;
              final prevPurchases = purchases
                  .where(
                    (x) =>
                        x['vehicle_id'] == p['vehicle_id'] &&
                        getDateStr(x['purchase_date']).compareTo(pDateStr) < 0,
                  )
                  .toList();
              if (prevPurchases.isNotEmpty) {
                final prev = prevPurchases.last;
                final prevOdo =
                    double.tryParse(
                      prev['odometer_reading']?.toString() ?? '0',
                    ) ??
                    0;
                final currOdo =
                    double.tryParse(p['odometer_reading']?.toString() ?? '0') ??
                    0;
                final prevLiters =
                    double.tryParse(prev['liters']?.toString() ?? '0') ?? 0;
                final kmTravelled = currOdo - prevOdo;
                if (prevLiters > 0 && kmTravelled > 0) {
                  final mileage = kmTravelled / prevLiters;
                  mileageStr =
                      '${kmTravelled.toStringAsFixed(0)} KM / ${prevLiters.toStringAsFixed(1)}L = ${mileage.toStringAsFixed(1)} KM/L';
                }
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_gas_station,
                          color: AppTheme.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['vehicle_number'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${getDisplayDate(p['purchase_date'])} | ${p['liters'] ?? 0}L | Odo: ${p['odometer_reading'] ?? 0} KM',
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (mileageStr != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 12,
                                      color: AppTheme.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      mileageStr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${p['amount']}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
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
}
