import 'dart:typed_data';
import 'web_downloader_stub.dart'
    if (dart.library.js_interop) 'web_downloader_web.dart';

void downloadBytes(Uint8List bytes, String fileName) {
  downloadWebBytes(bytes, fileName);
}
