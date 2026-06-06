import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class ServicingScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final bool isDriverView;
  final String? currentDriverId;
  const ServicingScreen({
    super.key,
    required this.supabaseService,
    this.isDriverView = false,
    this.currentDriverId,
  });

  @override
  State<ServicingScreen> createState() => _ServicingScreenState();
}

class _ServicingScreenState extends State<ServicingScreen> {
  void _showAddServicing() async {
    final vehicles = await widget.supabaseService.getVehicles();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        String? selVehicleId;
        String? selVehicleNum;
        final dateCtrl = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
        final costCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        final partsCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Servicing',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Select Car',
                      border: OutlineInputBorder(),
                    ),
                    items: vehicles
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text(
                              '${v['car_name']} - ${v['number_plate']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setS(() {
                        selVehicleId = v;
                        selVehicleNum = vehicles.firstWhere(
                          (x) => x['id'] == v,
                        )['number_plate'];
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Servicing Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: partsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Parts Serviced (comma separated)',
                      hintText: 'Oil, Brake, Tyre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: costCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cost (₹)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selVehicleId == null) return;
                  final parts = partsCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  await widget.supabaseService.addServicing(
                    vehicleId: selVehicleId!,
                    vehicleNumber: selVehicleNum ?? '',
                    date: dateCtrl.text,
                    partsServiced: parts,
                    cost: double.tryParse(costCtrl.text),
                    description: descCtrl.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Servicing added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
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
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.servicingStream(),
        builder: (context, snap) {
          final records = snap.data ?? [];
          // Group by vehicle
          final vehicleMap = <String, List<Map<String, dynamic>>>{};
          for (var r in records) {
            final vNum = r['vehicle_number'] ?? 'Unknown';
            vehicleMap.putIfAbsent(vNum, () => []).add(r);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Servicing',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    if (!widget.isDriverView)
                      ElevatedButton.icon(
                        onPressed: _showAddServicing,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (vehicleMap.isEmpty)
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
                          Icons.build_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No servicing records',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else
                  ...vehicleMap.entries.map((entry) {
                    final lastService = entry.value.first;
                    final lastDate = lastService['servicing_date'] ?? '';
                    int? daysAgo;
                    try {
                      daysAgo = DateTime.now()
                          .difference(DateTime.parse(lastDate))
                          .inDays;
                    } catch (_) {}
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.build,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Last service: $lastDate${daysAgo != null ? ' ($daysAgo days ago)' : ''}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        children: entry.value.map((r) {
                          final parts = r['parts_serviced'];
                          final partsList = parts is List
                              ? parts.map((p) => p.toString()).toList()
                              : [];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['servicing_date'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '₹${r['cost'] ?? 0}',
                                      style: const TextStyle(
                                        color: Color(0xFF1A237E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (partsList.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    children: partsList
                                        .map(
                                          (p) => Chip(
                                            label: Text(
                                              p,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                if (r['description'] != null &&
                                    r['description'].toString().isNotEmpty)
                                  Text(
                                    r['description'],
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 12,
                                    ),
                                  ),
                                const Divider(),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
