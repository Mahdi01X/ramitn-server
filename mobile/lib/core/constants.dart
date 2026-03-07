class AppConstants {
  static const String wsNamespace = '/game';
  static const int defaultCardsPerPlayer = 14;
  static const int defaultOpeningThreshold = 71;
  static const int defaultMaxRounds = 5;

  /// Production server URL — Render.com permanent deployment.
  static const String serverUrl = 'https://ramitn-server-2.onrender.com';

  /// No-op init for backward compatibility.
  static Future<void> init() async {}

  /// No-op — server URL is hardcoded in production.
  static Future<void> setServerUrl(String url) async {}
}





