import 'dart:async';

abstract mixin class TimerEvent {
  Timer? _timer;
  Duration? get timeoutDuration;
  void onTimerEvent() {}

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void startTimer() {
    _timer?.cancel();
    _timer = null;
    final duration = timeoutDuration;
    if (duration == null) return;
    _timer = Timer(duration, onTimerEvent);
  }
}
