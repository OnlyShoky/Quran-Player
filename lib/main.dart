import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';
import 'core/analytics/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.quran_player.audio',
    androidNotificationChannelName: 'Quran audio playback',
    androidNotificationOngoing: true,
  );
  runApp(QuranPlayerApp());

  AnalyticsService.initialize();
}
