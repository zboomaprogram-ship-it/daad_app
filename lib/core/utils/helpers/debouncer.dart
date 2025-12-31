import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class to debounce rapid function calls
/// Useful for search fields and other input that triggers expensive operations
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 300});

  /// Run the action after the debounce delay
  /// If called again before the delay expires, the previous call is cancelled
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancel any pending debounced action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose of the debouncer (cancel any pending action)
  void dispose() {
    cancel();
  }
}
