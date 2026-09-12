import 'package:flutter/material.dart';
import 'core/services/media_artwork_service.dart';
import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/services/quran_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaArtworkService.prepare();
  await QuranAudioHandler.initialize(
    androidNotificationChannelId: 'com.example.quran_player.audio',
    androidNotificationChannelName: 'Quran audio playback',
    androidNotificationIcon: 'drawable/ic_notification',
  );
  runApp(QuranPlayerApp());

  AnalyticsService.initialize();
}
