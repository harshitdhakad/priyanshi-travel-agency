import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

/// Handles PDF saving differently for desktop (save dialog) vs mobile (share sheet).
class PdfSaveHelper {
  /// Returns true if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Save or share a PDF.
  /// - Desktop: Opens a "Save As" file dialog, user picks path, file is saved there.
  /// - Mobile: Shares the file using the system share sheet.
  ///
  /// Returns the saved file path on success, or null if cancelled.
  static Future<String?> saveOrSharePdf({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String suggestedFileName,
  }) async {
    if (isDesktop) {
      // Desktop: let user pick where to save
      return _saveOnDesktop(context, pdfBytes, suggestedFileName);
    } else {
      // Mobile: share via system share sheet
      return _shareOnMobile(context, pdfBytes, suggestedFileName);
    }
  }

  static Future<String?> _saveOnDesktop(
    BuildContext context,
    Uint8List pdfBytes,
    String suggestedFileName,
  ) async {
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savePath == null) return null; // User cancelled

      final file = File(savePath);
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $savePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return savePath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  static Future<String?> _shareOnMobile(
    BuildContext context,
    Uint8List pdfBytes,
    String suggestedFileName,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final safeName = suggestedFileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9._\- ]'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Priyanshi Travel Agency - Report',
      );
      return file.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
