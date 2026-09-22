import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'core/services/media_artwork_service.dart';
import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/services/quran_audio_handler.dart';

Future<void> main() async {
  if (kDebugMode) {
    DevicePreview.enable(
      padding: const EdgeInsets.all(24),
    );
  }
  await MediaArtworkService.prepare();
  await QuranAudioHandler.initialize(
    androidNotificationChannelId: 'com.arakat.sukun.audio',
    androidNotificationChannelName: 'Quran audio playback',
    androidNotificationIcon: 'drawable/ic_notification',
  );
  await AnalyticsService.initialize();
  runApp(QuranPlayerApp());
}
