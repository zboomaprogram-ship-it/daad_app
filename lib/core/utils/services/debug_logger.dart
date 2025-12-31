import 'package:flutter/foundation.dart';

/// Debug logger that only logs in debug mode
/// Prevents sensitive data leakage in production builds
class DebugLogger {
  /// Log a debug message (only in debug mode)
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  /// Log with a category prefix
  static void logWithTag(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  /// Log an error (only in debug mode)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
      if (error != null) {
        print('   Error: $error');
      }
      if (stackTrace != null) {
        print('   Stack: $stackTrace');
      }
    }
  }

  /// Log a warning (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ WARNING: $message');
    }
  }

  /// Log a success message (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      print('✅ $message');
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }
}
