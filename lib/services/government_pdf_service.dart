import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class GovernmentPdfService {
  /// Generates a formal government-style logbook PDF
  static Future<Uint8List> generateLogbookPdf({
    required Map<String, dynamic> logbook,
    required String driverName,
    required String agencyName,
  }) async {
    final pdf = pw.Document();

    final vehicleNo = logbook['vehicle_number'] ?? 'N/A';
    final tripId = logbook['id']?.toString().substring(0, 8) ?? 'N/A';
    final logDate =
        logbook['log_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final startKm = (logbook['start_odometer'] ?? 0).toString();
    final endKm = (logbook['end_odometer'] ?? 0).toString();
    final totalKm = (logbook['total_km'] ?? 0).toString();
    final source = logbook['source'] ?? 'N/A';
    // Build full route from route_stops or destination field
    final fullRoute = _buildRouteString(logbook);
    final fuel = (logbook['fuel'] ?? 0).toString();
    final toll = (logbook['toll'] ?? 0).toString();
    final billStatus = logbook['bill_status'] ?? 'draft';
    final govtMeta = logbook['govt_metadata'];
    final metaMap = govtMeta is Map
        ? Map<String, dynamic>.from(govtMeta)
        : <String, dynamic>{};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 2, color: PdfColors.black),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    agencyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Government Transport Department',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Form TRB-2026',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1, color: PdfColors.grey400),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'This is a computer-generated document. No signature required.',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Title
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.5),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'OFFICIAL TRAVEL LOGBOOK',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.Text(
                    '& TRIP EXPENSE CLAIM SHEET',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '(Under Rule 47-A of Motor Vehicles Act)',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Vehicle & Driver Info Block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SECTION A: VEHICLE & DRIVER INFORMATION',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      children: [
                        _cell('Vehicle Number', bold: true),
                        _cell(vehicleNo),
                        _cell('Trip Reference', bold: true),
                        _cell(tripId),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _cell('Driver Name', bold: true),
                        _cell(driverName),
                        _cell('Date of Journey', bold: true),
                        _cell(logDate),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _cell('Agency', bold: true),
                        _cell(agencyName),
                        _cell('Bill Status', bold: true),
                        _cell(billStatus.toUpperCase()),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Core Mileage Grid
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SECTION B: CORE MILEAGE GRID',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _headerCell('Source'),
                        _headerCell('Full Route'),
                        _headerCell('Start KM'),
                        _headerCell('End KM'),
                        _headerCell('Total KM'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _cell(source),
                        _cell(fullRoute),
                        _cell(startKm),
                        _cell(endKm),
                        _cell(totalKm, bold: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Financial Claims
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SECTION C: FINANCIAL CLAIMS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _headerCell('Expense Type'),
                        _headerCell('Amount (₹)'),
                        _headerCell('Remarks'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _cell('Fuel Expenses'),
                        _cell('₹$fuel'),
                        _cell('As declared by driver'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _cell('Toll Taxes'),
                        _cell('₹$toll'),
                        _cell('Original receipts attached'),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        _cell('TOTAL EXPENSES', bold: true),
                        _cell(
                          '₹${(double.tryParse(fuel) ?? 0) + (double.tryParse(toll) ?? 0)}',
                          bold: true,
                        ),
                        _cell(''),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Dynamic Auto-Fields (Additional Audit Remarks)
          if (metaMap.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SECTION D: ADDITIONAL AUDIT REMARKS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.black,
                      width: 0.5,
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [_headerCell('Field'), _headerCell('Value')],
                      ),
                      ...metaMap.entries.map(
                        (e) => pw.TableRow(
                          children: [_cell(e.key), _cell(e.value.toString())],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // Signature Blocks
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SECTION E: AUTHENTICATION',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 180,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        "Driver's Signature",
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Name: $driverName',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'Verifying Authority Seal',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Authorized Signatory',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              '--- END OF OFFICIAL DOCUMENT ---',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// Generates a monthly logbook PDF for a specific vehicle.
  /// One row per day with: Date, Start KM, End KM, Destinations, Officer
  static Future<Uint8List> generateMonthlyLogbookPdf({
    required String vehicleNumber,
    required String month, // yyyy-MM
    required List<Map<String, dynamic>> logEntries,
    required String agencyName,
  }) async {
    final pdf = pw.Document();

    // Sort entries by date ascending
    logEntries.sort((a, b) {
      final dateA = a['log_date']?.toString() ?? '';
      final dateB = b['log_date']?.toString() ?? '';
      return dateA.compareTo(dateB);
    });

    // Calculate totals
    double totalStartKm = 0;
    double totalEndKm = 0;
    for (final entry in logEntries) {
      totalStartKm +=
          (double.tryParse(entry['start_odometer']?.toString() ?? '0') ?? 0);
      totalEndKm +=
          (double.tryParse(entry['end_odometer']?.toString() ?? '0') ?? 0);
    }
    final totalKm = totalEndKm - totalStartKm;

    // Format month display
    String monthDisplay;
    try {
      final dt = DateTime.parse('$month-01');
      monthDisplay = DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      monthDisplay = month;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 2, color: PdfColors.black),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    agencyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Fleet Logbook Register',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Month: $monthDisplay',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1, color: PdfColors.grey400),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Priyanshi Travel Agency - Official Logbook',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Vehicle Info Header
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              color: PdfColors.grey100,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      'Vehicle No.',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      vehicleNumber,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      'Office',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      agencyName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      'Company',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      agencyName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Title
          pw.Center(
            child: pw.Text(
              'MONTHLY VEHICLE LOGBOOK - $monthDisplay',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),

          // Main Logbook Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2), // S.No
              1: const pw.FlexColumnWidth(1.5), // Date
              2: const pw.FlexColumnWidth(1.3), // Start KM
              3: const pw.FlexColumnWidth(1.3), // End KM
              4: const pw.FlexColumnWidth(1.3), // Total KM
              5: const pw.FlexColumnWidth(3.5), // Destinations
              6: const pw.FlexColumnWidth(2.5), // Officer
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _mHeaderCell('S.No'),
                  _mHeaderCell('Date'),
                  _mHeaderCell('Start KM'),
                  _mHeaderCell('End KM'),
                  _mHeaderCell('Total KM'),
                  _mHeaderCell('Destinations / Route'),
                  _mHeaderCell('Officer / Purpose'),
                ],
              ),
              // Data rows
              for (int i = 0; i < logEntries.length; i++)
                pw.TableRow(
                  decoration: i % 2 == 0
                      ? pw.BoxDecoration(color: PdfColors.white)
                      : const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _mCell('${i + 1}'),
                    _mCell(logEntries[i]['log_date']?.toString() ?? ''),
                    _mCell(logEntries[i]['start_odometer']?.toString() ?? '0'),
                    _mCell(logEntries[i]['end_odometer']?.toString() ?? '0'),
                    _mCell(
                      ((double.tryParse(
                                    logEntries[i]['end_odometer']?.toString() ??
                                        '0',
                                  ) ??
                                  0) -
                              (double.tryParse(
                                    logEntries[i]['start_odometer']
                                            ?.toString() ??
                                        '0',
                                  ) ??
                                  0))
                          .toStringAsFixed(0),
                    ),
                    _mCell(_buildRouteString(logEntries[i])),
                    _mCell(_extractOfficer(logEntries[i])),
                  ],
                ),
              // Totals row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _mCell('', bold: true),
                  _mCell('TOTAL', bold: true),
                  _mCell('', bold: true),
                  _mCell('', bold: true),
                  _mCell(totalKm.toStringAsFixed(0), bold: true),
                  _mCell(''),
                  _mCell(''),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Signature section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 160,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'Driver Signature',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 160,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'Verifying Officer',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _buildRouteString(Map<String, dynamic> entry) {
    final routeStops = entry['route_stops'];
    if (routeStops is List && routeStops.isNotEmpty) {
      final cities = routeStops
          .map((s) {
            if (s is Map) return s['destination']?.toString() ?? '';
            return s.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
      if (cities.isNotEmpty) return cities.join(' \u2192 ');
    }
    final dest = entry['destination']?.toString() ?? '';
    final src = entry['source']?.toString() ?? '';
    // If destination contains ' - ' it's a multi-stop route like "Vidisha - Bhopal - Vidisha"
    if (dest.contains(' - ')) {
      final stops = dest
          .split(' - ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return stops.join(' \u2192 ');
    }
    if (src.isNotEmpty && dest.isNotEmpty) return '$src \u2192 $dest';
    if (dest.isNotEmpty) return dest;
    if (entry['not_went_anywhere'] == true) return 'Station (No trip)';
    return '-';
  }

  static String _extractOfficer(Map<String, dynamic> entry) {
    final govtMeta = entry['govt_metadata'];
    if (govtMeta is Map && govtMeta.isNotEmpty) {
      // Look for officer-related keys
      for (final key in [
        'officer',
        'officer_name',
        'govt_officer',
        'purpose',
        'department',
      ]) {
        if (govtMeta.containsKey(key)) {
          return govtMeta[key].toString();
        }
      }
      // Return first value if no specific key found
      return govtMeta.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return '-';
  }

  static pw.Widget _mCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _mHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Generates a diesel mileage PDF for a vehicle.
  /// Shows each purchase with odometer readings and calculated mileage.
  static Future<Uint8List> generateDieselMileagePdf({
    required String vehicleName,
    required String vehicleNumber,
    required String agencyName,
    required String periodLabel,
    required List<Map<String, dynamic>> purchases,
  }) async {
    final pdf = pw.Document();

    // Sort purchases by date ascending
    purchases.sort(
      (a, b) => (a['purchase_date'] ?? '').compareTo(b['purchase_date'] ?? ''),
    );

    // Calculate totals
    double totalLiters = 0;
    double totalAmount = 0;
    double totalKm = 0;
    int mileageCount = 0;
    double totalMileage = 0;

    for (final p in purchases) {
      totalLiters += (double.tryParse(p['liters']?.toString() ?? '0') ?? 0);
      totalAmount += (double.tryParse(p['amount']?.toString() ?? '0') ?? 0);
    }

    // Calculate mileage between consecutive purchases
    final List<Map<String, dynamic>> rows = [];
    for (int i = 0; i < purchases.length; i++) {
      final p = purchases[i];
      final odo =
          double.tryParse(p['odometer_reading']?.toString() ?? '0') ?? 0;
      final liters = double.tryParse(p['liters']?.toString() ?? '0') ?? 0;
      String kmTravelled = '-';
      String mileage = '-';

      if (i > 0) {
        final prevOdo =
            double.tryParse(
              purchases[i - 1]['odometer_reading']?.toString() ?? '0',
            ) ??
            0;
        final prevLiters =
            double.tryParse(purchases[i - 1]['liters']?.toString() ?? '0') ?? 0;
        final km = odo - prevOdo;
        if (km > 0 && prevLiters > 0) {
          final m = km / prevLiters;
          kmTravelled = km.toStringAsFixed(0);
          mileage = m.toStringAsFixed(1);
          totalKm += km;
          totalMileage += m;
          mileageCount++;
        }
      }

      rows.add({
        'sr': i + 1,
        'date': p['purchase_date'] ?? '',
        'liters': liters.toStringAsFixed(1),
        'amount': (double.tryParse(p['amount']?.toString() ?? '0') ?? 0)
            .toStringAsFixed(0),
        'odometer': odo.toStringAsFixed(0),
        'km': kmTravelled,
        'mileage': mileage,
      });
    }

    final avgMileage = mileageCount > 0
        ? (totalMileage / mileageCount).toStringAsFixed(1)
        : '-';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 2, color: PdfColors.black),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    agencyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Diesel & Mileage Report',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Vehicle: $vehicleName ($vehicleNumber)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Period: $periodLabel',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1, color: PdfColors.grey400),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          // Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerHeight: 25,
            cellHeight: 22,
            headers: [
              'Sr.',
              'Date',
              'Qty (L)',
              'Amount (Rs)',
              'Odometer (KM)',
              'KM Travelled',
              'Mileage (KM/L)',
            ],
            data: rows
                .map(
                  (r) => [
                    r['sr'],
                    r['date'],
                    r['liters'],
                    r['amount'],
                    r['odometer'],
                    r['km'],
                    r['mileage'],
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          // Summary
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _summaryBox(
                      'Total Diesel',
                      '${totalLiters.toStringAsFixed(1)} L',
                      PdfColors.blue,
                    ),
                    _summaryBox(
                      'Total Amount',
                      'Rs ${totalAmount.toStringAsFixed(0)}',
                      PdfColors.red,
                    ),
                    _summaryBox(
                      'Total KM',
                      '${totalKm.toStringAsFixed(0)} KM',
                      PdfColors.green,
                    ),
                    _summaryBox(
                      'Avg Mileage',
                      '$avgMileage KM/L',
                      PdfColors.deepPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Generates a servicing history PDF for a vehicle
  static Future<Uint8List> generateServicingPdf({
    required String vehicleName,
    required String vehicleNumber,
    required String agencyName,
    required List<Map<String, dynamic>> records,
  }) async {
    final pdf = pw.Document();

    // Sort by date descending
    records.sort(
      (a, b) =>
          (b['servicing_date'] ?? '').compareTo(a['servicing_date'] ?? ''),
    );

    double totalCost = 0;
    for (final r in records) {
      totalCost += (double.tryParse(r['cost']?.toString() ?? '0') ?? 0);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 2, color: PdfColors.black),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    agencyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Vehicle Servicing Record',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Vehicle: $vehicleName ($vehicleNumber)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1, color: PdfColors.grey400),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'This is a computer-generated document. No signature required.',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerHeight: 25,
            cellHeight: 24,
            headers: [
              'Sr.',
              'Date',
              'Parts Serviced',
              'Description',
              'Cost (Rs)',
            ],
            data: List.generate(records.length, (i) {
              final r = records[i];
              final parts = r['parts_serviced'];
              final partsStr = parts is List
                  ? parts.map((p) => p.toString()).join(', ')
                  : (parts?.toString() ?? '-');
              return [
                '${i + 1}',
                r['servicing_date'] ?? '',
                partsStr,
                r['description']?.toString() ?? '-',
                (double.tryParse(r['cost']?.toString() ?? '0') ?? 0)
                    .toStringAsFixed(0),
              ];
            }),
          ),
          pw.SizedBox(height: 20),
          // Summary
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryBox(
                  'Total Services',
                  '${records.length}',
                  PdfColors.blue,
                ),
                _summaryBox(
                  'Total Cost',
                  'Rs ${totalCost.toStringAsFixed(0)}',
                  PdfColors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
