import 'dart:async';
import 'dart:ui';

class Handler {
  Timer post(Duration delay, VoidCallback callback) {
    // Schedule the task to be executed in the future.
    return Timer(delay, callback);
  }
}
