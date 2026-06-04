import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final bool isDriverView;
  const EventsScreen({
    super.key,
    required this.supabaseService,
    this.isDriverView = false,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  void _showAddEventDialog() async {
    final vehicles = await widget.supabaseService.getVehicles();
    if (!mounted) return;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final receivedCtrl = TextEditingController();
    final pendingCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    List<String> selectedVehicleIds = [];
    String status = 'upcoming';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Create Event',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Event Date',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 8),
                TextField(
                  controller: receivedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Received (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pendingCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Pending (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'upcoming',
                      child: Text('Upcoming'),
                    ),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (v) => setS(() => status = v ?? 'upcoming'),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assign Vehicles:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: vehicles.map((v) {
                    final vId = v['id'] as String;
                    final isSelected = selectedVehicleIds.contains(vId);
                    return FilterChip(
                      label: Text(
                        '${v['car_name']} ${v['number_plate']}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: isSelected,
                      onSelected: (sel) {
                        setS(() {
                          if (sel) {
                            selectedVehicleIds.add(vId);
                          } else {
                            selectedVehicleIds.remove(vId);
                          }
                        });
                      },
                      selectedColor: const Color(
                        0xFF1A237E,
                      ).withValues(alpha: 0.2),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
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
                if (titleCtrl.text.isEmpty) return;
                await widget.supabaseService.addEvent(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  eventDate: dateCtrl.text,
                  createdBy: 'admin',
                  vehiclesAssigned: selectedVehicleIds,
                  paymentReceived: double.tryParse(receivedCtrl.text),
                  paymentPending: double.tryParse(pendingCtrl.text),
                  status: status,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event created!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> event) async {
    final vehicles = await widget.supabaseService.getVehicles();
    if (!mounted) return;
    final titleCtrl = TextEditingController(text: event['title'] ?? '');
    final descCtrl = TextEditingController(text: event['description'] ?? '');
    final receivedCtrl = TextEditingController(
      text: (event['payment_received'] ?? 0).toString(),
    );
    final pendingCtrl = TextEditingController(
      text: (event['payment_pending'] ?? 0).toString(),
    );
    String status = event['status'] ?? 'upcoming';
    List<dynamic> currentAssigned = event['vehicles_assigned'] is List
        ? List.from(event['vehicles_assigned'])
        : [];
    List<String> selectedVehicleIds = currentAssigned
        .map((e) => e.toString())
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Event',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: receivedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Received (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pendingCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Pending (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'upcoming',
                      child: Text('Upcoming'),
                    ),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (v) => setS(() => status = v ?? 'upcoming'),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assigned Vehicles:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: vehicles.map((v) {
                    final vId = v['id'] as String;
                    final isSelected = selectedVehicleIds.contains(vId);
                    return FilterChip(
                      label: Text(
                        '${v['car_name']} ${v['number_plate']}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: isSelected,
                      onSelected: (sel) {
                        setS(() {
                          if (sel) {
                            selectedVehicleIds.add(vId);
                          } else {
                            selectedVehicleIds.remove(vId);
                          }
                        });
                      },
                      selectedColor: const Color(
                        0xFF1A237E,
                      ).withValues(alpha: 0.2),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
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
                await widget.supabaseService.updateEvent(event['id'], {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'vehicles_assigned': selectedVehicleIds,
                  'payment_received': double.tryParse(receivedCtrl.text) ?? 0,
                  'payment_pending': double.tryParse(pendingCtrl.text) ?? 0,
                  'status': status,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.eventsStream(),
        builder: (context, snap) {
          final events = snap.data ?? [];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Events & Fleet Deployment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    if (!widget.isDriverView)
                      ElevatedButton.icon(
                        onPressed: _showAddEventDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Event'),
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
              ),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No events created yet',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: events.length,
                        itemBuilder: (ctx, i) => _buildEventCard(events[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final assignedVehicles = event['vehicles_assigned'] is List
        ? List<String>.from(event['vehicles_assigned'])
        : <String>[];
    final received = (event['payment_received'] ?? 0);
    final pending = (event['payment_pending'] ?? 0);
    final statusColor = event['status'] == 'completed'
        ? Colors.green
        : event['status'] == 'active'
        ? Colors.orange
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Date: ${event['event_date'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (!widget.isDriverView)
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: () => _showEditEventDialog(event),
                      ),
                    if (!widget.isDriverView)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete this event?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true)
                            await widget.supabaseService.deleteEvent(
                              event['id'],
                            );
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (event['description'] != null &&
                event['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  event['description'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            // Vehicles assigned chips
            if (assignedVehicles.isNotEmpty)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.supabaseService.vehicleStream(),
                builder: (ctx, vSnap) {
                  final allVehicles = vSnap.data ?? [];
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: assignedVehicles.map((vId) {
                      final match = allVehicles.where((v) => v['id'] == vId);
                      final label = match.isNotEmpty
                          ? '${match.first['car_name']} ${match.first['number_plate']}'
                          : 'Vehicle';
                      return Chip(
                        avatar: const Icon(
                          Icons.directions_car,
                          size: 14,
                          color: Color(0xFF1A237E),
                        ),
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 8),
            // Payment summary row
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _paymentChip(
                    'Vehicles',
                    '${assignedVehicles.length}',
                    Icons.directions_car,
                    Colors.blue,
                  ),
                  _paymentChip(
                    'Received',
                    '₹${received.toStringAsFixed(0)}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _paymentChip(
                    'Pending',
                    '₹${pending.toStringAsFixed(0)}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event['status']?.toUpperCase() ?? 'UPCOMING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentChip(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}
