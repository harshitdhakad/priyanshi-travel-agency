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
    final destination = logbook['destination'] ?? 'N/A';
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
                        _headerCell('Destination'),
                        _headerCell('Start KM'),
                        _headerCell('End KM'),
                        _headerCell('Total KM'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _cell(source),
                        _cell(destination),
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
}
