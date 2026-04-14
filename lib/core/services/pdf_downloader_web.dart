import 'dart:typed_data';

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'pdf_downloader.dart';

class PdfDownloaderImpl implements PdfDownloader {
  @override
  Future<void> download(Uint8List bytes, String title) async {
    final safeTitle = title.replaceAll(' ', '_').toLowerCase();

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement()
      ..href = url
      ..download = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
  }
}
