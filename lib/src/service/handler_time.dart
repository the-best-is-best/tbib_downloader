import 'dart:async';
import 'dart:ui';

class Handler {
  void post(Duration delay, VoidCallback callback) {
    // Schedule the task to be executed in the future.
    Timer(delay, callback);
  }
}
