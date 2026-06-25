import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
import 'package:intl/intl.dart';

class DieselDetailsScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  const DieselDetailsScreen({super.key, required this.supabaseService});

  @override
  State<DieselDetailsScreen> createState() => _DieselDetailsScreenState();
}

class _DieselDetailsScreenState extends State<DieselDetailsScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _purchases = [];
  String? _selectedVehicleId;
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
      final vehicles = await widget.supabaseService.getVehicles();
      final purchases = await widget.supabaseService.getDieselPurchases();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _purchases = purchases;
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

  /// Safe date to string helper
  static String _dateStr(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return DateFormat('yyyy-MM-dd').format(val);
    return val.toString();
  }

  static String _displayDate(dynamic val) {
    if (val == null) return 'N/A';
    if (val is DateTime) return DateFormat('dd MMM yyyy').format(val);
    return val.toString();
  }

  // ── Add Diesel Purchase Dialog ──
  void _showAddDiesel({String? preselectVehicleId}) async {
    final vehicles = _vehicles;
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicles available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selVehicle = preselectVehicleId;
    final amtCtrl = TextEditingController();
    final litersCtrl = TextEditingController();
    final odoCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
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
                  value: selVehicle,
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
                          vehicleId: selVehicle,
                          vehicleNumber: vehicle['number_plate'] as String?,
                          amount: double.tryParse(amtCtrl.text) ?? 0,
                          liters: double.tryParse(litersCtrl.text),
                          odometerReading: double.tryParse(odoCtrl.text),
                          date: dateCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving: $e'),
                              backgroundColor: AppTheme.error,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // If a vehicle is selected, show its diesel details
    if (_selectedVehicleId != null) {
      return _buildVehicleDieselDetails();
    }
    // Otherwise show the car list
    return _buildVehicleList();
  }

  // ════════════════════════════════════════
  //  VEHICLE LIST VIEW
  // ════════════════════════════════════════
  Widget _buildVehicleList() {
    // Calculate totals
    final totalLitres = _purchases.fold(
      0.0,
      (s, r) => s + (double.tryParse(r['liters']?.toString() ?? '0') ?? 0),
    );
    final totalAmount = _purchases.fold(
      0.0,
      (s, r) => s + (double.tryParse(r['amount']?.toString() ?? '0') ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diesel Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDiesel(),
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
            const SizedBox(height: 12),
            // Summary cards
            Row(
              children: [
                _summaryCard(
                  'Total Litres',
                  '${totalLitres.toStringAsFixed(1)} L',
                  AppTheme.warning,
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  'Total Spent',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  AppTheme.primary,
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  'Records',
                  '${_purchases.length}',
                  AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Vehicle',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            if (_vehicles.isEmpty)
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
                      Icons.directions_car_outlined,
                      size: 40,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No vehicles found',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  ],
                ),
              )
            else
              ..._vehicles.map((v) {
                final vId = v['id'] as String;
                final vPurchases = _purchases
                    .where((p) => p['vehicle_id'] == vId)
                    .toList();
                final vLitres = vPurchases.fold(
                  0.0,
                  (s, r) =>
                      s +
                      (double.tryParse(r['liters']?.toString() ?? '0') ?? 0),
                );
                final vAmount = vPurchases.fold(
                  0.0,
                  (s, r) =>
                      s +
                      (double.tryParse(r['amount']?.toString() ?? '0') ?? 0),
                );
                // Last purchase date
                String lastDate = '-';
                if (vPurchases.isNotEmpty) {
                  lastDate = _displayDate(vPurchases.last['purchase_date']);
                }
                // Avg mileage calculation
                String avgMileage = '-';
                if (vPurchases.length >= 2) {
                  final sorted = List<Map<String, dynamic>>.from(vPurchases)
                    ..sort(
                      (a, b) => _dateStr(
                        a['purchase_date'],
                      ).compareTo(_dateStr(b['purchase_date'])),
                    );
                  double totalM = 0;
                  int cnt = 0;
                  for (int i = 1; i < sorted.length; i++) {
                    final prevOdo =
                        double.tryParse(
                          sorted[i - 1]['odometer_reading']?.toString() ?? '0',
                        ) ??
                        0;
                    final currOdo =
                        double.tryParse(
                          sorted[i]['odometer_reading']?.toString() ?? '0',
                        ) ??
                        0;
                    final prevL =
                        double.tryParse(
                          sorted[i - 1]['liters']?.toString() ?? '0',
                        ) ??
                        0;
                    final km = currOdo - prevOdo;
                    if (km > 0 && prevL > 0) {
                      totalM += km / prevL;
                      cnt++;
                    }
                  }
                  if (cnt > 0) {
                    avgMileage = '${(totalM / cnt).toStringAsFixed(1)} KM/L';
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedVehicleId = vId),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_gas_station,
                              color: AppTheme.warning,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v['car_name'] ?? ''} ${v['number_plate'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${vPurchases.length} records  •  Last: $lastDate',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${vLitres.toStringAsFixed(1)}L',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${vAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    if (avgMileage != '-') ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        avgMileage,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textHint,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  VEHICLE DIESEL DETAILS VIEW
  // ════════════════════════════════════════
  Widget _buildVehicleDieselDetails() {
    final vId = _selectedVehicleId!;
    final vehicle = _vehicles.firstWhere(
      (v) => v['id'] == vId,
      orElse: () => <String, dynamic>{},
    );
    final vPurchases = _purchases
        .where((p) => p['vehicle_id'] == vId)
        .toList()
        .reversed
        .toList();
    final vLitres = vPurchases.fold(
      0.0,
      (s, r) => s + (double.tryParse(r['liters']?.toString() ?? '0') ?? 0),
    );
    final vAmount = vPurchases.fold(
      0.0,
      (s, r) => s + (double.tryParse(r['amount']?.toString() ?? '0') ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button + title
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedVehicleId = null),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    '${vehicle['car_name'] ?? ''} ${vehicle['number_plate'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDiesel(preselectVehicleId: vId),
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
            const SizedBox(height: 12),
            // Summary cards for this vehicle
            Row(
              children: [
                _summaryCard(
                  'Litres',
                  '${vLitres.toStringAsFixed(1)} L',
                  AppTheme.warning,
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  'Spent',
                  '₹${vAmount.toStringAsFixed(0)}',
                  AppTheme.primary,
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  'Records',
                  '${vPurchases.length}',
                  AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Purchase History',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            if (vPurchases.isEmpty)
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
                      'No diesel records for this vehicle',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  ],
                ),
              )
            else
              ...vPurchases.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                // Mileage calculation
                String? mileageStr;
                if (idx < vPurchases.length - 1) {
                  // Previous in reversed list = next chronologically
                  final next = vPurchases[idx + 1];
                  final currOdo =
                      double.tryParse(
                        p['odometer_reading']?.toString() ?? '0',
                      ) ??
                      0;
                  final nextOdo =
                      double.tryParse(
                        next['odometer_reading']?.toString() ?? '0',
                      ) ??
                      0;
                  final liters =
                      double.tryParse(p['liters']?.toString() ?? '0') ?? 0;
                  final km = currOdo - nextOdo;
                  if (km > 0 && liters > 0) {
                    mileageStr =
                        '${km.toStringAsFixed(0)} KM / ${liters.toStringAsFixed(1)}L = ${(km / liters).toStringAsFixed(1)} KM/L';
                  }
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: AppTheme.warning,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayDate(p['purchase_date']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p['liters'] ?? 0}L  •  Odo: ${p['odometer_reading'] ?? 0} KM',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              if (mileageStr != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
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
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '₹${(double.tryParse(p['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
