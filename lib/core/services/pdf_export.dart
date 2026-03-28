import 'dart:js_interop';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

class PdfExportService {
  static Future<void> export({
    required String title,
    required List<Map<String, dynamic>> data,
  }) async {
    if (data.isEmpty) {
      throw Exception('No data to export');
    }

    final pdfBytes = await _generatePdf(title, data);
    _downloadPdf(pdfBytes, title);
  }

  static Future<Uint8List> _generatePdf(
    String title,
    List<Map<String, dynamic>> data,
  ) async {
    final pdf = pw.Document();

    final headers = data.first.keys.toList();

    final rows = data.map((row) {
      return headers.map((key) {
        final value = row[key];
        return _formatValue(value);
      }).toList();
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static void _downloadPdf(Uint8List bytes, String title) {
    final safeTitle = title.replaceAll(' ', '_').toLowerCase();

    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    web.document.body!.append(anchor);

    anchor.click();

    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '';

    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(value);
    }

    if (value is double) {
      return value.toStringAsFixed(2);
    }

    return value.toString();
  }
}
