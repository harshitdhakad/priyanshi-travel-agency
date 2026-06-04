import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
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
  void _showAddDiesel() async {
    final vehicles = await widget.supabaseService.getVehicles();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final amtCtrl = TextEditingController();
        final litersCtrl = TextEditingController();
        final dateCtrl = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
        String? selVehicle;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Diesel Purchase',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
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
                          child: Text('${v['car_name']} ${v['number_plate']}'),
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
                    if (p != null)
                      dateCtrl.text = DateFormat('yyyy-MM-dd').format(p);
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
                  if (amtCtrl.text.isEmpty) return;
                  final vehicle = vehicles.firstWhere(
                    (v) => v['id'] == selVehicle,
                    orElse: () => {},
                  );
                  await widget.supabaseService.addDieselPurchase(
                    driverId: widget.driverId,
                    vehicleId: selVehicle,
                    vehicleNumber: vehicle['number_plate'],
                    amount: double.tryParse(amtCtrl.text) ?? 0,
                    liters: double.tryParse(litersCtrl.text),
                    date: dateCtrl.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Diesel purchase added'),
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
        stream: widget.supabaseService.dieselPurchasesStream(),
        builder: (context, snap) {
          var purchases = snap.data ?? [];
          if (widget.driverId != null) {
            purchases = purchases
                .where((p) => p['driver_id'] == widget.driverId)
                .toList();
          }
          // Check for 3-day gap notification
          String? warningMsg;
          if (purchases.isNotEmpty) {
            try {
              final lastDate = DateTime.parse(
                purchases.first['purchase_date'] ?? '',
              );
              final daysSince = DateTime.now().difference(lastDate).inDays;
              if (daysSince >= 3) {
                warningMsg = '⚠ No diesel purchase in last $daysSince days!';
              }
            } catch (_) {}
          } else {
            warningMsg = '⚠ No diesel purchases recorded yet!';
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
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddDiesel,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
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
                const SizedBox(height: 10),
                if (warningMsg != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      warningMsg,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (purchases.isEmpty)
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
                          Icons.local_gas_station_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No diesel purchases',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else
                  ...purchases.map(
                    (p) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          p['vehicle_number'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${p['purchase_date']} | ${p['liters'] ?? 0}L',
                        ),
                        trailing: Text(
                          '₹${p['amount']}',
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
