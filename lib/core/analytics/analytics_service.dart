import 'analytics_service_native.dart'
    if (dart.library.html) 'analytics_service_web.dart' as platform;

class AnalyticsService {
  static Future<void> initialize() => platform.initializeAnalytics();

  static Future<void> screen(String name) => platform.trackScreen(name);
}