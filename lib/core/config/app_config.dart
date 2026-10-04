import 'package:flutter/foundation.dart';

import '../services/offline_cache_service.dart';

/// Central application configuration controlling environment constants,
/// timeouts, and delegating local storage to OfflineCacheService.
class AppConfig {
  static final AppConfig instance = AppConfig._internal();

  AppConfig._internal();

  // Application metadata
  static const String appName = 'CampusCart';
  static const String appVersion = '1.0.0';

  // Request timeout duration for cloud calls
  static const Duration requestTimeout = Duration(seconds: 12);

  // Network connection proxy
  ValueNotifier<bool> get isOnlineNotifier =>
      OfflineCacheService.instance.isOnlineNotifier;
  bool get isOnline => OfflineCacheService.instance.isOnline;
  set isOnline(bool val) => OfflineCacheService.instance.isOnline = val;

  // Local storage convenience references
  OfflineCacheService get cache => OfflineCacheService.instance;

  // Verified safe trade zones on campus
  static const List<Map<String, String>> campusSafeTradeZones = [
    {
      'name': 'University Library Lobby',
      'description': 'Monitored area with reception desk and security.',
      'safety_level': 'High Security',
    },
    {
      'name': 'Student Center Main Quad',
      'description': 'High foot-traffic daytime area.',
      'safety_level': 'Daytime Monitored',
    },
    {
      'name': 'Campus Security Office',
      'description': 'Directly outside 24/7 campus security building.',
      'safety_level': '24/7 Guarded',
    },
  ];
}
