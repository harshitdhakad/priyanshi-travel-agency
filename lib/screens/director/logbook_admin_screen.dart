import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/government_pdf_service.dart';
import 'package:intl/intl.dart';

class LogbookAdminScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  const LogbookAdminScreen({super.key, required this.supabaseService});

  @override
  State<LogbookAdminScreen> createState() => _LogbookAdminScreenState();
}

class _LogbookAdminScreenState extends State<LogbookAdminScreen> {
  String _filterMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String? _uploadingId;

  Future<void> _generateAndUploadOfficialPdf(Map<String, dynamic> log) async {
    final logId = log['id']?.toString() ?? '';
    setState(() => _uploadingId = logId);
    try {
      // Get driver name
      String driverName = 'Driver';
      if (log['driver_id'] != null) {
        try {
          final drivers = await widget.supabaseService.getProfiles('driver');
          final match = drivers.where((d) => d['id'] == log['driver_id']);
          if (match.isNotEmpty) driverName = match.first['name'] ?? 'Driver';
        } catch (_) {}
      }

      // 1. Generate PDF
      final pdfBytes = await GovernmentPdfService.generateLogbookPdf(
        logbook: log,
        driverName: driverName,
        agencyName: 'Priyanshi Travel Agency',
      );

      // 2. Build file name: vehicleNo_tripId_date.pdf
      final vehicleNo = (log['vehicle_number'] ?? 'UNKNOWN')
          .toString()
          .replaceAll(' ', '_');
      final tripId = logId.length >= 8 ? logId.substring(0, 8) : logId;
      final dateStr =
          log['log_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = '${vehicleNo}_trip${tripId}_$dateStr.pdf';

      // 3. Upload to Supabase Storage
      final pdfUrl = await widget.supabaseService.uploadLogbookPdf(
        fileBytes: pdfBytes,
        fileName: fileName,
      );

      // 4. Save URL back to DB
      if (pdfUrl != null) {
        await widget.supabaseService.updateLogbookPdfUrl(logId, pdfUrl);
      }

      // 5. Save locally and share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Official Logbook - $fileName');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pdfUrl != null
                  ? 'Official PDF saved to cloud & shared!'
                  : 'PDF shared (cloud upload failed, saved locally)',
            ),
            backgroundColor: pdfUrl != null ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingId = null);
    }
  }

  void _showEditDialog(Map<String, dynamic> log) {
    final srcCtrl = TextEditingController(text: log['source'] ?? '');
    final destCtrl = TextEditingController(text: log['destination'] ?? '');
    final startCtrl = TextEditingController(
      text: (log['start_odometer'] ?? 0).toString(),
    );
    final endCtrl = TextEditingController(
      text: (log['end_odometer'] ?? 0).toString(),
    );
    final fuelCtrl = TextEditingController(text: (log['fuel'] ?? 0).toString());
    final tollCtrl = TextEditingController(text: (log['toll'] ?? 0).toString());
    String status = log['bill_status'] ?? 'draft';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Logbook Entry',
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
                  controller: srcCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: destCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Start KM',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'End KM',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fuelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fuel',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tollCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Toll',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Bill Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'submitted',
                      child: Text('Submitted'),
                    ),
                    DropdownMenuItem(value: 'cleared', child: Text('Cleared')),
                  ],
                  onChanged: (v) => setS(() => status = v ?? 'draft'),
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
                await widget.supabaseService.updateLogbook(log['id'], {
                  'source': srcCtrl.text,
                  'destination': destCtrl.text,
                  'start_odometer': double.tryParse(startCtrl.text) ?? 0,
                  'end_odometer': double.tryParse(endCtrl.text) ?? 0,
                  'fuel': double.tryParse(fuelCtrl.text) ?? 0,
                  'toll': double.tryParse(tollCtrl.text) ?? 0,
                  'bill_status': status,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.supabaseService.logbookStream(),
        builder: (context, snap) {
          var logs = snap.data ?? [];
          logs = logs
              .where((l) => (l['log_date'] ?? '').startsWith(_filterMonth))
              .toList();
          final draftCount = logs
              .where((l) => l['bill_status'] == 'draft')
              .length;
          final submittedCount = logs
              .where((l) => l['bill_status'] == 'submitted')
              .length;
          final clearedCount = logs
              .where((l) => l['bill_status'] == 'cleared')
              .length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Logbook Admin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null)
                          setState(
                            () => _filterMonth = DateFormat(
                              'yyyy-MM',
                            ).format(picked),
                          );
                      },
                      icon: const Icon(Icons.date_range, size: 16),
                      label: Text(
                        _filterMonth,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard('Draft', '$draftCount', Colors.grey),
                    const SizedBox(width: 8),
                    _statCard('Submitted', '$submittedCount', Colors.orange),
                    const SizedBox(width: 8),
                    _statCard('Cleared', '$clearedCount', Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                if (logs.isEmpty)
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
                          Icons.book_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No logbook entries for $_filterMonth',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else
                  ...logs.map((l) => _buildLogCard(l)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> l) {
    final logId = l['id']?.toString() ?? '';
    final isUploading = _uploadingId == logId;
    final hasPdfUrl =
        l['pdf_report_url'] != null &&
        l['pdf_report_url'].toString().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            (l['bill_status'] == 'cleared'
                                    ? Colors.green
                                    : l['bill_status'] == 'submitted'
                                    ? Colors.orange
                                    : Colors.grey)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.book, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l['vehicle_number'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l['log_date'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Official PDF Download/Upload button
                    if (isUploading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A237E),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          hasPdfUrl ? Icons.cloud_done : Icons.picture_as_pdf,
                          size: 18,
                          color: hasPdfUrl ? Colors.green : Colors.redAccent,
                        ),
                        tooltip: hasPdfUrl
                            ? 'Re-generate & Upload Official PDF'
                            : 'Generate & Upload Official PDF',
                        onPressed: () => _generateAndUploadOfficialPdf(l),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue,
                      ),
                      onPressed: () => _showEditDialog(l),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete?'),
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
                          await widget.supabaseService.deleteLogbook(l['id']);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${l['source'] ?? ''} → ${l['destination'] ?? ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A237E),
              ),
            ),
            Row(
              children: [
                Text(
                  'KM: ${l['total_km'] ?? 0}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Fuel: ₹${l['fuel'] ?? 0}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Toll: ₹${l['toll'] ?? 0}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (l['govt_metadata'] is Map &&
                (l['govt_metadata'] as Map).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  children: (l['govt_metadata'] as Map).entries
                      .map(
                        (e) => Chip(
                          label: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: l['bill_status'] == 'cleared'
                        ? Colors.green
                        : l['bill_status'] == 'submitted'
                        ? Colors.orange
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l['bill_status']?.toUpperCase() ?? 'DRAFT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasPdfUrl)
                  TextButton.icon(
                    onPressed: () async {
                      // Open the PDF URL
                      final url = l['pdf_report_url'].toString();
                      await Share.share(url, subject: 'Official Logbook PDF');
                    },
                    icon: const Icon(Icons.cloud_download, size: 14),
                    label: const Text(
                      'Cloud PDF',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
