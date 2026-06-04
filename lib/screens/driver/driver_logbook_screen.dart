import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
import '../../services/localization_service.dart';
import '../../widgets/credits_footer.dart';
import 'package:intl/intl.dart';

class DriverLogbookScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final String? driverId;
  const DriverLogbookScreen({
    super.key,
    required this.supabaseService,
    this.driverId,
  });

  @override
  State<DriverLogbookScreen> createState() => _DriverLogbookScreenState();
}

class _DriverLogbookScreenState extends State<DriverLogbookScreen> {
  final _formKey = GlobalKey<FormState>();
  final vehicleCtrl = TextEditingController();
  final fuelCtrl = TextEditingController();
  final tollCtrl = TextEditingController();
  final startKmCtrl = TextEditingController();
  final endKmCtrl = TextEditingController();
  final dateCtrl = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final List<TextEditingController> _cityStops = [];
  final List<Map<String, TextEditingController>> _dynamicFields = [];
  bool _saving = false;
  bool _notWentAnywhere = false;
  final AppLocalizations _loc = AppLocalizations();

  @override
  void initState() {
    super.initState();
    _autoFillVehicle();
  }

  Future<void> _autoFillVehicle() async {
    if (widget.driverId == null) return;
    try {
      final vehicles = await widget.supabaseService.getVehicles();
      if (!mounted) return;
      final match = vehicles.where(
        (v) => v['assigned_driver_id'] == widget.driverId,
      );
      if (match.isNotEmpty && vehicleCtrl.text.isEmpty) {
        vehicleCtrl.text = match.first['number_plate']?.toString() ?? '';
      }
    } catch (_) {}
  }

  void _addCityStop() {
    setState(() {
      _cityStops.add(TextEditingController());
    });
  }

  void _removeCityStop(int idx) {
    setState(() {
      _cityStops[idx].dispose();
      _cityStops.removeAt(idx);
    });
  }

  void _addDynamicField() {
    setState(() {
      _dynamicFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeDynamicField(int idx) {
    setState(() => _dynamicFields.removeAt(idx));
  }

  String _buildRouteString() {
    final cities = _cityStops
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.text.trim())
        .toList();
    return cities.join(' → ');
  }

  Future<void> _saveLogbook(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_notWentAnywhere &&
        _cityStops.where((c) => c.text.trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one city stop or mark "Didn\'t go anywhere"',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final metadata = <String, dynamic>{};
      for (final field in _dynamicFields) {
        final key = field['key']!.text.trim();
        final val = field['value']!.text.trim();
        if (key.isNotEmpty && val.isNotEmpty) metadata[key] = val;
      }

      // Build route stops from city names
      final cities = _cityStops
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => c.text.trim())
          .toList();

      final stops = <Map<String, dynamic>>[];
      for (int i = 0; i < cities.length; i++) {
        stops.add({
          'source': i == 0 ? cities[0] : cities[i - 1],
          'destination': cities[i],
          'start_km': 0,
          'end_km': 0,
        });
      }

      final _ = cities.join(' → '); // route display string (future use)
      String mainSource = cities.isNotEmpty ? cities.first : '';
      String mainDest = cities.isNotEmpty ? cities.last : '';
      double mainStart = double.tryParse(startKmCtrl.text) ?? 0;
      double mainEnd = double.tryParse(endKmCtrl.text) ?? 0;

      if (_notWentAnywhere) {
        mainSource = 'Station';
        mainDest = 'No trip';
        mainStart = 0;
        mainEnd = 0;
      }

      await widget.supabaseService.addLogbook(
        driverId: widget.driverId,
        vehicleNumber: vehicleCtrl.text,
        startOdometer: mainStart,
        endOdometer: mainEnd,
        source: mainSource,
        destination: mainDest,
        fuel: double.tryParse(fuelCtrl.text) ?? 0,
        toll: double.tryParse(tollCtrl.text) ?? 0,
        govtMetadata: metadata,
        logDate: dateCtrl.text,
        billStatus: _notWentAnywhere ? 'submitted' : status,
        routeStops: stops,
        notWentAnywhere: _notWentAnywhere,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _notWentAnywhere
                  ? 'Marked as no trip today'
                  : status == 'draft'
                  ? 'Saved as draft'
                  : 'Logbook submitted',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _markNotWentAnywhere() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm'),
        content: const Text(
          "Mark today as 'Didn't go anywhere'?\nThis will submit that you were present but had no trip.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_loc.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _notWentAnywhere = true);
      if (vehicleCtrl.text.isEmpty) {
        await _autoFillVehicle();
      }
      await _saveLogbook('submitted');
    }
  }

  void _clearForm() {
    vehicleCtrl.clear();
    fuelCtrl.clear();
    tollCtrl.clear();
    startKmCtrl.clear();
    endKmCtrl.clear();
    for (final c in _cityStops) {
      c.dispose();
    }
    _cityStops.clear();
    for (final field in _dynamicFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    _dynamicFields.clear();
    _notWentAnywhere = false;
    dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.t('daily_logbook_entry'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Not went anywhere button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _markNotWentAnywhere,
                        icon: const Icon(Icons.beach_access, size: 18),
                        label: Text(_loc.t('didnt_go_anywhere')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning,
                          side: const BorderSide(color: AppTheme.warning),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Basic info card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: dateCtrl,
                              decoration: InputDecoration(
                                labelText: _loc.t('date'),
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final p = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                );
                                if (p != null) {
                                  dateCtrl.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(p);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: vehicleCtrl,
                              decoration: InputDecoration(
                                labelText: _loc.t('vehicle_number'),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: fuelCtrl,
                                    decoration: InputDecoration(
                                      labelText: '${_loc.t('fuel')} (₹)',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: tollCtrl,
                                    decoration: InputDecoration(
                                      labelText: '${_loc.t('toll')} (₹)',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Day-level KM fields
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Odometer Reading (Day)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: startKmCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'Start KM',
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.play_arrow,
                                              size: 18,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: endKmCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'End KM',
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.stop,
                                              size: 18,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (startKmCtrl.text.isNotEmpty &&
                                      endKmCtrl.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Total: ${((double.tryParse(endKmCtrl.text) ?? 0) - (double.tryParse(startKmCtrl.text) ?? 0)).abs().toStringAsFixed(0)} KM',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Route Stops section - simplified city names
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route (Cities)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addCityStop,
                          icon: const Icon(Icons.add_location, size: 16),
                          label: const Text('Add City'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_cityStops.isNotEmpty && _buildRouteString().isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.route,
                              color: AppTheme.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _buildRouteString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._cityStops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ctrl = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: ctrl,
                                decoration: InputDecoration(
                                  labelText: 'City / Stop Name',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.error,
                              ),
                              onPressed: () => _removeCityStop(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Dynamic fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Extra Fields (Optional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addDynamicField,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Field'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    ..._dynamicFields.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final field = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: field['key'],
                                decoration: const InputDecoration(
                                  labelText: 'Field Name',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: field['value'],
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.error,
                              ),
                              onPressed: () => _removeDynamicField(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _saveLogbook('draft'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                            child: Text(
                              _loc.t('save_as_draft'),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () => _saveLogbook('submitted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _loc.t('submit'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // My logbook entries
                    Text(
                      _loc.t('my_logbook_entries'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: widget.supabaseService.logbookStream(),
                      builder: (context, snap) {
                        var logs = snap.data ?? [];
                        if (widget.driverId != null) {
                          logs = logs
                              .where((l) => l['driver_id'] == widget.driverId)
                              .toList();
                        }
                        if (logs.isEmpty) {
                          return Text(
                            _loc.t('no_entries'),
                            style: TextStyle(color: AppTheme.textHint),
                          );
                        }
                        return Column(
                          children: logs.take(10).map((l) {
                            final isNoTrip = l['not_went_anywhere'] == true;
                            final statusColor = l['bill_status'] == 'cleared'
                                ? AppTheme.success
                                : l['bill_status'] == 'submitted'
                                ? AppTheme.warning
                                : AppTheme.textHint;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isNoTrip ? Icons.beach_access : Icons.book,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  isNoTrip
                                      ? '${l['log_date'] ?? ''} - No trip'
                                      : '${l['source'] ?? ''} → ${l['destination'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isNoTrip
                                      ? 'Station duty'
                                      : '${l['log_date'] ?? ''} | ${l['total_km'] ?? 0} KM | ₹${l['fuel'] ?? 0} fuel',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l['bill_status']?.toUpperCase() ?? '',
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
                  ],
                ),
              ),
            ),
          ),
          const CreditsFooter(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    vehicleCtrl.dispose();
    fuelCtrl.dispose();
    tollCtrl.dispose();
    startKmCtrl.dispose();
    endKmCtrl.dispose();
    dateCtrl.dispose();
    for (final c in _cityStops) {
      c.dispose();
    }
    for (final f in _dynamicFields) {
      f['key']?.dispose();
      f['value']?.dispose();
    }
    super.dispose();
  }
}
