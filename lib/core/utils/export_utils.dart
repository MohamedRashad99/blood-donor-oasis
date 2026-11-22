import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class ExportUtils {
  /// Converts rows of data to CSV with UTF-8 BOM so Excel opens it in Arabic correctly
  static String generateCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Header row
    buffer.writeln(headers.map(_escapeCsvValue).join(','));

    // Data rows
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvValue).join(','));
    }

    return buffer.toString();
  }

  static String _escapeCsvValue(dynamic value) {
    if (value == null) return '""';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Downloads CSV file in browser or opens it
  static Future<void> downloadCsv({
    required String fileName,
    required String csvContent,
  }) async {
    try {
      final bytes = utf8.encode(csvContent);
      final base64Data = base64Encode(bytes);
      final uri = Uri.parse('data:text/csv;charset=utf-8;base64,$base64Data');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }
}
