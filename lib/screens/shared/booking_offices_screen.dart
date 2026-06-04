import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class BookingOfficesScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final bool isDriverView;
  final String? currentDriverId;
  const BookingOfficesScreen({
    super.key,
    required this.supabaseService,
    this.isDriverView = false,
    this.currentDriverId,
  });

  @override
  State<BookingOfficesScreen> createState() => _BookingOfficesScreenState();
}

class _BookingOfficesScreenState extends State<BookingOfficesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  void _showManageVehicles(String officeId, String officeName) async {
    final vehicles = await widget.supabaseService.getVehicles();
    final drivers = await widget.supabaseService.getProfiles('driver');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Vehicles: $officeName',
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.supabaseService.officeVehicleAssignmentsStream(),
              builder: (ctx2, snap) {
                final allAssignments = snap.data ?? [];
                final assignments = allAssignments
                    .where(
                      (a) =>
                          a['office_id'] == officeId && a['is_active'] == true,
                    )
                    .toList();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (assignments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No vehicles assigned yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    else
                      ...assignments.map((a) {
                        final vMatch = vehicles.where(
                          (v) => v['id'] == a['vehicle_id'],
                        );
                        final dMatch = drivers.where(
                          (d) => d['id'] == a['driver_id'],
                        );
                        final vLabel = vMatch.isNotEmpty
                            ? '${vMatch.first['car_name']} ${vMatch.first['number_plate']}'
                            : 'Unknown Vehicle';
                        final dLabel = dMatch.isNotEmpty
                            ? dMatch.first['name'] ?? ''
                            : 'No Driver';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.directions_car,
                              color: Color(0xFF1A237E),
                              size: 20,
                            ),
                            title: Text(
                              vLabel,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              dLabel,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () async {
                                await widget.supabaseService
                                    .deleteOfficeVehicleAssignment(a['id']);
                              },
                            ),
                          ),
                        );
                      }),
                    const Divider(),
                    _AddAssignmentRow(
                      vehicles: vehicles,
                      drivers: drivers,
                      onAdd: (vId, dId) async {
                        await widget.supabaseService.addOfficeVehicleAssignment(
                          officeId: officeId,
                          vehicleId: vId,
                          driverId: dId,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOffice() async {
    final vehicles = await widget.supabaseService.getVehicles();
    final drivers = await widget.supabaseService.getProfiles('driver');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final dateCtrl = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
        final incomeCtrl = TextEditingController();
        List<String> selectedVehicleIds = [];
        String? selDriver;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Govt Office',
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
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Office Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Joining Date',
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
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assign Vehicles (multi-select):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selDriver,
                    decoration: const InputDecoration(
                      labelText: 'Primary Driver',
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
                    onChanged: (v) => setS(() => selDriver = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: incomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Income (₹)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
                  if (nameCtrl.text.isEmpty) return;
                  await widget.supabaseService.addGovtOffice(
                    officeName: nameCtrl.text,
                    joiningDate: dateCtrl.text,
                    vehicleId: selectedVehicleIds.isNotEmpty
                        ? selectedVehicleIds.first
                        : null,
                    driverId: selDriver,
                    monthlyIncome: double.tryParse(incomeCtrl.text),
                  );
                  // Add multi-vehicle assignments
                  final offices = await widget.supabaseService.getGovtOffices();
                  final match = offices.where(
                    (o) => o['office_name'] == nameCtrl.text,
                  );
                  if (match.isNotEmpty) {
                    for (final vId in selectedVehicleIds) {
                      await widget.supabaseService.addOfficeVehicleAssignment(
                        officeId: match.first['id'],
                        vehicleId: vId,
                        driverId: selDriver,
                      );
                    }
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Office added with ${selectedVehicleIds.length} vehicle(s)',
                      ),
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

  void _showEditOffice(String id, Map<String, dynamic> current) async {
    final vehicles = await widget.supabaseService.getVehicles();
    final drivers = await widget.supabaseService.getProfiles('driver');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        String? selVehicle = current['vehicle_id'];
        String? selDriver = current['driver_id'];
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Update Office',
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
                    labelText: 'Vehicle',
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
                DropdownButtonFormField<String>(
                  initialValue: selDriver,
                  decoration: const InputDecoration(
                    labelText: 'Driver',
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
                  onChanged: (v) => setS(() => selDriver = v),
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
                  await widget.supabaseService.updateGovtOffice(id, {
                    'vehicle_id': selVehicle,
                    'driver_id': selDriver,
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddBooking() async {
    final vehicles = await widget.supabaseService.getVehicles();
    final drivers = await widget.supabaseService.getProfiles('driver');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final destCtrl = TextEditingController();
        final amtCtrl = TextEditingController();
        final dateCtrl = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
        String? selVehicle;
        String? selDriver;
        String payStatus = 'pending';
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Booking Trip',
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
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: destCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
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
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Trip Date',
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
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selVehicle,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      border: OutlineInputBorder(),
                    ),
                    items: vehicles
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text(
                              '${v['car_name']} ${v['number_plate']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setS(() => selVehicle = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selDriver,
                    decoration: const InputDecoration(
                      labelText: 'Driver',
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
                    onChanged: (v) => setS(() => selDriver = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: payStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    ],
                    onChanged: (v) => setS(() => payStatus = v ?? 'pending'),
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
                  if (nameCtrl.text.isEmpty) return;
                  await widget.supabaseService.addBookingTrip(
                    customerName: nameCtrl.text,
                    destination: destCtrl.text,
                    vehicleId: selVehicle,
                    driverId: selDriver,
                    amount: double.tryParse(amtCtrl.text),
                    paymentStatus: payStatus,
                    tripDate: dateCtrl.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking added'),
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
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Govt Offices'),
                Tab(text: 'Bookings'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildOfficesTab(), _buildBookingsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.supabaseService.govtOfficesStream(),
      builder: (context, snap) {
        final offices = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Government Offices',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  if (!widget.isDriverView)
                    ElevatedButton.icon(
                      onPressed: _showAddOffice,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Office'),
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
              const SizedBox(height: 12),
              if (offices.isEmpty)
                _emptyState('No offices added yet', Icons.business)
              else
                ...offices.map(
                  (o) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.business,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o['office_name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Joined: ${o['joining_date'] ?? 'N/A'} | Income: ₹${o['monthly_income'] ?? 0}/mo',
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
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showEditOffice(o['id'], o),
                                ),
                              if (!widget.isDriverView)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => widget.supabaseService
                                      .deleteGovtOffice(o['id']),
                                ),
                            ],
                          ),
                          // Multi-vehicle assignments row
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: widget.supabaseService
                                  .officeVehicleAssignmentsStream(),
                              builder: (ctx2, assignSnap) {
                                final allAssign = assignSnap.data ?? [];
                                final officeAssignments = allAssign
                                    .where(
                                      (a) =>
                                          a['office_id'] == o['id'] &&
                                          a['is_active'] == true,
                                    )
                                    .toList();
                                return StreamBuilder<
                                  List<Map<String, dynamic>>
                                >(
                                  stream: widget.supabaseService
                                      .vehicleStream(),
                                  builder: (ctx3, vSnap) {
                                    final allVehicles = vSnap.data ?? [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.directions_car,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${officeAssignments.length} vehicle(s) assigned',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const Spacer(),
                                            if (!widget.isDriverView)
                                              InkWell(
                                                onTap: () =>
                                                    _showManageVehicles(
                                                      o['id'],
                                                      o['office_name'] ?? '',
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF1A237E,
                                                    ).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Manage',
                                                    style: TextStyle(
                                                      color: Color(0xFF1A237E),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (officeAssignments.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: officeAssignments.map((
                                                a,
                                              ) {
                                                final vMatch = allVehicles
                                                    .where(
                                                      (v) =>
                                                          v['id'] ==
                                                          a['vehicle_id'],
                                                    );
                                                final label = vMatch.isNotEmpty
                                                    ? '${vMatch.first['car_name']} ${vMatch.first['number_plate']}'
                                                    : 'Vehicle';
                                                return Chip(
                                                  avatar: const Icon(
                                                    Icons.directions_car,
                                                    size: 12,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                  label: Text(
                                                    label,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          if (!widget.isDriverView)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: StreamBuilder<List<Map<String, dynamic>>>(
                                stream: widget.supabaseService
                                    .officePaymentsStream(),
                                builder: (ctx, paySnap) {
                                  final payments = paySnap.data ?? [];
                                  final currentMonth = DateFormat(
                                    'yyyy-MM',
                                  ).format(DateTime.now());
                                  final officePayment = payments
                                      .where(
                                        (p) =>
                                            p['office_id'] == o['id'] &&
                                            p['month'] == currentMonth,
                                      )
                                      .toList();
                                  final isPaid =
                                      officePayment.isNotEmpty &&
                                      officePayment.first['is_paid'] == true;
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'This month payment:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await widget.supabaseService
                                              .markOfficePayment(
                                                officeId: o['id'],
                                                month: currentMonth,
                                                isPaid: !isPaid,
                                                amount: double.tryParse(
                                                  o['monthly_income']
                                                          ?.toString() ??
                                                      '0',
                                                ),
                                              );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPaid
                                              ? Colors.green
                                              : Colors.orange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                        ),
                                        child: Text(
                                          isPaid ? 'PAID ✓' : 'Mark Paid',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
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
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.supabaseService.bookingTripsStream(),
      builder: (context, snap) {
        var trips = snap.data ?? [];
        if (widget.isDriverView && widget.currentDriverId != null) {
          trips = trips
              .where((t) => t['driver_id'] == widget.currentDriverId)
              .toList();
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
                    'Booking Trips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  if (!widget.isDriverView)
                    ElevatedButton.icon(
                      onPressed: _showAddBooking,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Booking'),
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
              const SizedBox(height: 12),
              if (trips.isEmpty)
                _emptyState('No bookings yet', Icons.bookmark_outline)
              else
                ...trips.map(
                  (t) => Card(
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
                                  (t['payment_status'] == 'paid'
                                          ? Colors.green
                                          : Colors.orange)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.bookmark,
                              color: t['payment_status'] == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['customer_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'To: ${t['destination'] ?? 'N/A'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${t['amount'] ?? 0}',
                                  style: const TextStyle(
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: t['payment_status'] == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t['payment_status']?.toUpperCase() ?? 'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!widget.isDriverView)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () => widget.supabaseService
                                  .deleteBookingTrip(t['id']),
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
    );
  }

  Widget _emptyState(String msg, IconData icon) {
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
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _AddAssignmentRow extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final List<Map<String, dynamic>> drivers;
  final Future<void> Function(String vehicleId, String? driverId) onAdd;

  const _AddAssignmentRow({
    required this.vehicles,
    required this.drivers,
    required this.onAdd,
  });

  @override
  State<_AddAssignmentRow> createState() => _AddAssignmentRowState();
}

class _AddAssignmentRowState extends State<_AddAssignmentRow> {
  String? _selVehicle;
  String? _selDriver;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Add Vehicle:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selVehicle,
          decoration: const InputDecoration(
            labelText: 'Select Vehicle',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          isDense: true,
          items: widget.vehicles
              .map(
                (v) => DropdownMenuItem<String>(
                  value: v['id'] as String,
                  child: Text(
                    '${v['car_name']} ${v['number_plate']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selVehicle = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selDriver,
          decoration: const InputDecoration(
            labelText: 'Select Driver (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          isDense: true,
          items: widget.drivers
              .map(
                (d) => DropdownMenuItem<String>(
                  value: d['id'] as String,
                  child: Text(
                    d['name'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selDriver = v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _adding
                ? null
                : () async {
                    if (_selVehicle == null) return;
                    setState(() => _adding = true);
                    await widget.onAdd(_selVehicle!, _selDriver);
                    setState(() {
                      _adding = false;
                      _selVehicle = null;
                      _selDriver = null;
                    });
                  },
            icon: _adding
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add, size: 16),
            label: const Text('Assign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
