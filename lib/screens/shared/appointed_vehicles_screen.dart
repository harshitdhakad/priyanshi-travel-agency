import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AppointedVehiclesScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final bool isDriverView;
  final String? currentDriverId;
  const AppointedVehiclesScreen({
    super.key,
    required this.supabaseService,
    this.isDriverView = false,
    this.currentDriverId,
  });

  @override
  State<AppointedVehiclesScreen> createState() =>
      _AppointedVehiclesScreenState();
}

class _AppointedVehiclesScreenState extends State<AppointedVehiclesScreen> {
  void _showAppointDialog() {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait([
          widget.supabaseService.getProfiles('driver'),
          widget.supabaseService.getVehicles(),
        ]).then((r) => [...r[0], ...r[1]]),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const AlertDialog(content: CircularProgressIndicator());
          }
          // Split the data back
          final driversFuture = widget.supabaseService.getProfiles('driver');
          final vehiclesFuture = widget.supabaseService.getVehicles();
          return FutureBuilder<List<dynamic>>(
            future: Future.wait([driversFuture, vehiclesFuture]),
            builder: (ctx, s2) {
              if (!s2.hasData) {
                return const AlertDialog(content: CircularProgressIndicator());
              }
              final drivers = s2.data![0] as List<Map<String, dynamic>>;
              final vehicles = s2.data![1] as List<Map<String, dynamic>>;
              String? selectedDriver;
              String? selectedVehicle;
              bool isTemp = false;
              int durationDays = 1;
              return StatefulBuilder(
                builder: (ctx, setS) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Appoint Vehicle to Driver',
                    style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedDriver,
                        decoration: const InputDecoration(
                          labelText: 'Select Driver',
                          border: OutlineInputBorder(),
                        ),
                        items: drivers
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d['id'] as String,
                                child: Text(d['name'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setS(() => selectedDriver = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedVehicle,
                        decoration: const InputDecoration(
                          labelText: 'Select Vehicle',
                          border: OutlineInputBorder(),
                        ),
                        items: vehicles
                            .map(
                              (v) => DropdownMenuItem(
                                value: v['id'] as String,
                                child: Text(
                                  '${v['car_name']} ${v['number_plate']}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setS(() => selectedVehicle = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Type: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ChoiceChip(
                            label: const Text(
                              'Permanent',
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: !isTemp,
                            onSelected: (_) => setS(() => isTemp = false),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text(
                              'Temporary',
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: isTemp,
                            onSelected: (_) => setS(() => isTemp = true),
                          ),
                        ],
                      ),
                      if (isTemp) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Duration: '),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: durationDays,
                              items: [1, 2, 3, 5, 7, 15, 30]
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text('$d day${d > 1 ? 's' : ''}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setS(() => durationDays = v ?? 1),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedDriver == null || selectedVehicle == null) {
                          return;
                        }
                        if (isTemp) {
                          await widget.supabaseService.appointVehicleTemp(
                            driverId: selectedDriver!,
                            vehicleId: selectedVehicle!,
                            durationDays: durationDays,
                          );
                        } else {
                          await widget.supabaseService.appointVehicle(
                            driverId: selectedDriver!,
                            vehicleId: selectedVehicle!,
                          );
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vehicle appointed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Appoint'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.appointedVehiclesStream(),
        builder: (context, snap) {
          var appointments = snap.data ?? [];
          if (widget.isDriverView && widget.currentDriverId != null) {
            appointments = appointments
                .where((a) => a['driver_id'] == widget.currentDriverId)
                .toList();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isDriverView) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Appointed Vehicles',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAppointDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Appoint'),
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
                ] else ...[
                  const Text(
                    'My Appointed Vehicle',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (appointments.isEmpty)
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
                          Icons.directions_car_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No appointments',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else
                  ...appointments.map(
                    (a) => Card(
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
                                color:
                                    (a['is_active'] == true
                                            ? Colors.green
                                            : Colors.grey)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.directions_car,
                                color: a['is_active'] == true
                                    ? Colors.green
                                    : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver: ${a['driver_id']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Vehicle: ${a['vehicle_id']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'From: ${a['appointed_date'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.isDriverView)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await widget.supabaseService
                                      .removeAppointment(a['id']);
                                },
                              ),
                          ],
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
