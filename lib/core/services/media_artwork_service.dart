import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MediaArtworkService {
  static Uri? uri;

  static Future<void> prepare() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final artworkFile = File('${directory.path}/sukun_media_artwork.png');
      if (!await artworkFile.exists()) {
        final data = await rootBundle.load('assets/data/favicon.png');
        await artworkFile.writeAsBytes(
          Uint8List.sublistView(data),
          flush: true,
        );
      }
      uri = artworkFile.uri;
    } catch (_) {
      uri = null;
    }
  }
}
