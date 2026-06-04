import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class DriverBookingScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  final String? driverId;
  const DriverBookingScreen({
    super.key,
    required this.supabaseService,
    this.driverId,
  });

  @override
  State<DriverBookingScreen> createState() => _DriverBookingScreenState();
}

class _DriverBookingScreenState extends State<DriverBookingScreen> {
  void _showFillDetails(Map<String, dynamic> trip) {
    final destCtrl = TextEditingController(text: trip['destination'] ?? '');
    final amtCtrl = TextEditingController(
      text: (trip['amount'] ?? 0).toString(),
    );
    String payStatus = trip['payment_status'] ?? 'pending';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Fill Booking Details',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination/Route',
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
              DropdownButtonFormField<String>(
                initialValue: payStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                ],
                onChanged: (v) => setS(() => payStatus = v ?? 'pending'),
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
                await widget.supabaseService.updateBookingTrip(trip['id'], {
                  'destination': destCtrl.text,
                  'amount': double.tryParse(amtCtrl.text) ?? 0,
                  'payment_status': payStatus,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updated'),
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
      ),
    );
  }

  Future<void> _generateBookingPdf(Map<String, dynamic> trip) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, text: 'Booking Trip Receipt'),
            pw.Paragraph(
              text: 'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Customer: ${trip['customer_name'] ?? ''}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Destination: ${trip['destination'] ?? 'N/A'}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Amount: ₹${trip['amount'] ?? 0}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Payment: ${trip['payment_status']?.toUpperCase() ?? 'PENDING'}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Trip Date: ${trip['trip_date'] ?? ''}',
              style: pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/booking_${trip['customer_name'] ?? 'trip'}.pdf',
    );
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Booking Receipt');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.bookingTripsStream(),
        builder: (context, snap) {
          var trips = snap.data ?? [];
          if (widget.driverId != null) {
            trips = trips
                .where((t) => t['driver_id'] == widget.driverId)
                .toList();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Booking Assignments',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 12),
                if (trips.isEmpty)
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
                          Icons.bookmark_outline,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No bookings assigned to you',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...trips.map(
                    (t) => Card(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            (t['payment_status'] == 'paid'
                                                    ? Colors.green
                                                    : Colors.orange)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.bookmark,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['customer_name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          t['trip_date'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t['payment_status']?.toUpperCase() ??
                                        'PENDING',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To: ${t['destination'] ?? 'Not filled yet'}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Amount: ₹${t['amount'] ?? 0}',
                              style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showFillDetails(t),
                                    icon: const Icon(Icons.edit, size: 14),
                                    label: const Text(
                                      'Fill Details',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1A237E),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => _generateBookingPdf(t),
                                ),
                              ],
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
