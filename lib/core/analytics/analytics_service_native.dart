import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

FirebaseAnalytics? _analytics;

Future<void> initializeAnalytics() async {
  try {
    await Firebase.initializeApp();
    _analytics = FirebaseAnalytics.instance;
  } catch (_) {
    // Native Firebase configuration is supplied by the release build.
  }
}

Future<void> trackScreen(String name) async {
  await _analytics?.logScreenView(screenName: name);
}