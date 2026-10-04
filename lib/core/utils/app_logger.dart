import 'package:flutter/foundation.dart';

/// Centralized logger that ensures logs only appear in debug mode
/// and never leak sensitive user data or technical stack traces in production.
class AppLogger {
  AppLogger._();

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARN] $message ${error != null ? "- $error" : ""}');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('Details: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }
}
