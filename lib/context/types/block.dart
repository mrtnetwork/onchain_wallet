import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';

class AppContextLockingTask {
  int _taskId = 0;
  Completer<void>? _completer;
  final SafeAtomicLock _sync = SafeAtomicLock();
  AppContextLockingTask();
  Future<void> run(
      {required bool Function(int id) onRelease, required Duration timeout}) {
    return _sync.run(() async {
      final id = ++_taskId;
      final lock = onRelease(id);
      if (lock) {
        final completer = _completer = Completer();
        await completer.future.timeout(timeout, onTimeout: () => null);
        _completer = null;
      }
    });
  }

  bool release(int id) {
    if (id == _taskId) {
      final completer = _completer;
      if (completer != null && !completer.isCompleted) {
        completer.complete(null);
        return true;
      }
    }
    return false;
  }
}
