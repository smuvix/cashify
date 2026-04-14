import 'dart:io';
import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_downloader.dart';

class PdfDownloaderImpl implements PdfDownloader {
  @override
  Future<void> download(Uint8List bytes, String title) async {
    final safeTitle = title.replaceAll(' ', '_').toLowerCase();

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);
  }
}
