import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/supabase_service.dart';

class GoogleDriveBackupScreen extends StatefulWidget {
  final SupabaseService supabaseService;
  const GoogleDriveBackupScreen({super.key, required this.supabaseService});

  @override
  State<GoogleDriveBackupScreen> createState() =>
      _GoogleDriveBackupScreenState();
}

class _GoogleDriveBackupScreenState extends State<GoogleDriveBackupScreen> {
  bool _exporting = false;
  String? _lastExportTime;
  int? _lastRecordCount;

  Future<void> _exportBackup() async {
    setState(() => _exporting = true);
    try {
      final data = await widget.supabaseService.exportAllData();
      final meta = data['_meta'] as Map<String, dynamic>;
      int totalRecords = 0;
      for (final key in data.keys) {
        if (key != '_meta' && data[key] is List) {
          totalRecords += (data[key] as List).length;
        }
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'priyanshi_backup_$timestamp.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      setState(() {
        _lastExportTime = meta['exported_at'];
        _lastRecordCount = totalRecords;
      });

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Priyanshi Travel Agency Backup\n$totalRecords records exported on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}\n\nSave this file to Google Drive for backup.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup exported! $totalRecords records saved. Choose Google Drive to save.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportTableBackup(String table) async {
    setState(() => _exporting = true);
    try {
      final data = await widget.supabaseService.getTable(table);
      final backup = {
        'table': table,
        'records': data,
        'count': data.length,
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'Priyanshi Travel Agency',
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'priyanshi_${table}_$timestamp.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Backup: $table (${data.length} records)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_upload,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cloud Backup',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Save data to Google Drive / Gmail',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportBackup,
                      icon: _exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, size: 20),
                      label: Text(
                        _exporting ? 'Exporting...' : 'Export Full Backup',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Last export info
            if (_lastExportTime != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Export Successful',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_lastRecordCount ?? 0} records on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(_lastExportTime!))}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // How to use
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF1A237E),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How to Backup to Google Drive',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _stepRow('1', 'Tap "Export Full Backup" button above'),
                    _stepRow('2', 'Wait for data to be compiled'),
                    _stepRow(
                      '3',
                      'From share sheet, select "Drive" or "Gmail"',
                    ),
                    _stepRow('4', 'Choose folder and save the backup file'),
                    const SizedBox(height: 6),
                    Text(
                      'The backup file contains ALL your agency data in JSON format. Keep it safe!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Individual table backups
            const Text(
              'Backup Individual Tables',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 10),
            ..._tableItems(),
          ],
        ),
      ),
    );
  }

  Widget _stepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  List<Widget> _tableItems() {
    final tables = [
      ('profiles', 'Drivers, Staff & Director', Icons.people),
      ('vehicles', 'Fleet Vehicles', Icons.directions_car),
      ('bookings', 'Customer Bookings', Icons.book_online),
      ('attendance', 'Attendance Records', Icons.fact_check),
      ('salary_records', 'Salary Records', Icons.payments),
      ('diesel_records', 'Diesel Records', Icons.local_gas_station),
      ('fleet_logbooks', 'Fleet Logbooks', Icons.menu_book),
      ('govt_offices', 'Government Offices', Icons.business),
      ('booking_trips', 'Booking Trips', Icons.bookmark),
      ('events', 'Events', Icons.event),
      ('servicing_records', 'Servicing Records', Icons.build),
      ('appointed_vehicles', 'Vehicle Appointments', Icons.assignment),
    ];

    return tables.map((t) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          dense: true,
          leading: Icon(t.$3, color: const Color(0xFF1A237E), size: 20),
          title: Text(
            t.$2,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            t.$1,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          trailing: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.download,
                    size: 18,
                    color: Color(0xFF1A237E),
                  ),
                  onPressed: () => _exportTableBackup(t.$1),
                ),
        ),
      );
    }).toList();
  }
}
