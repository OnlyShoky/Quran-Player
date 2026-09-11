import 'package:flutter/material.dart';
import 'app.dart';
import 'core/analytics/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.initialize();
  runApp(QuranPlayerApp());
}
