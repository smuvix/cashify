import 'pdf_downloader.dart';
import 'pdf_downloader_mobile.dart'
    if (dart.library.html) 'pdf_downloader_web.dart';

PdfDownloader createPdfDownloader() {
  return PdfDownloaderImpl();
}
