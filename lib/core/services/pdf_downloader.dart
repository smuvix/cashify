import 'dart:typed_data';

abstract class PdfDownloader {
  Future<void> download(Uint8List bytes, String title);
}
