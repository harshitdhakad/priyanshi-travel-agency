import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class VehicleManagementScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  const VehicleManagementScreen({super.key, required this.supabaseService});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  void _showAddVehicleDialog() {
    final carNameCtrl = TextEditingController();
    final modelNoCtrl = TextEditingController();
    final numberPlateCtrl = TextEditingController();
    final yearCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add New Vehicle',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  carNameCtrl,
                  'Car Name (e.g. Innova)',
                  Icons.directions_car,
                ),
                const SizedBox(height: 10),
                _dialogField(modelNoCtrl, 'Model No.', Icons.numbers),
                const SizedBox(height: 10),
                _dialogField(
                  numberPlateCtrl,
                  'Number Plate (e.g. RJ-14 AB 1234)',
                  Icons.credit_card,
                ),
                const SizedBox(height: 10),
                _dialogField(
                  yearCtrl,
                  'Year',
                  Icons.calendar_today,
                  keyboard: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (carNameCtrl.text.isEmpty || numberPlateCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Car name and number plate are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await widget.supabaseService.addVehicle(
                  carName: carNameCtrl.text,
                  modelNo: modelNoCtrl.text,
                  numberPlate: numberPlateCtrl.text,
                  year: int.tryParse(yearCtrl.text),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vehicle added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Vehicle',
          style: TextStyle(color: Colors.red),
        ),
        content: Text('Are you sure you want to remove "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.supabaseService.deleteVehicle(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name removed'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
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
        stream: widget.supabaseService.vehicleStream(),
        builder: (context, snapshot) {
          final vehicles = snapshot.data ?? [];
          final active = vehicles.where((v) => v['status'] == 'active').length;
          final maintenance = vehicles
              .where((v) => v['status'] == 'maintenance')
              .length;
          final idle = vehicles.where((v) => v['status'] == 'idle').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicles',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          '${vehicles.length} in fleet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddVehicleDialog,
                      icon: const Icon(Icons.directions_car_filled, size: 18),
                      label: const Text('Add Vehicle'),
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

                // Status chips
                Row(
                  children: [
                    _statusChip('Active', active, Colors.green),
                    const SizedBox(width: 8),
                    _statusChip('Maintenance', maintenance, Colors.orange),
                    const SizedBox(width: 8),
                    _statusChip('Idle', idle, Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                if (snapshot.connectionState == ConnectionState.waiting &&
                    vehicles.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (vehicles.isEmpty)
                  _emptyState()
                else
                  ...vehicles.map((v) {
                    final status = v['status'] ?? 'active';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_car,
                                color: _statusColor(status),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${v['car_name'] ?? ''} ${v['model_no'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    v['number_plate'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Year: ${v['year'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDelete(
                                    v['id'],
                                    '${v['car_name']} ${v['number_plate']}',
                                  ),
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _statusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'idle':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No vehicles added yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Vehicle" to get started',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A237E)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
