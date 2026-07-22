import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

typedef ONTIMERTICK = void Function(int? tick);

class WalletTimeoutController {
  final ONTIMERTICK _onTick;
  final FutureVoid _onTimeout;
  final bool Function() _onLockTime;
  WalletLockTime Function() locktime;
  final int remainingShow = 110;
  final _lock = SafeAtomicLock();
  int _tick = 0;

  WalletTimeoutController(
      {required FutureVoid onTimeout,
      required bool Function() isUnlock,
      required ONTIMERTICK onTick,
      required this.locktime})
      : _onTimeout = onTimeout,
        _onLockTime = isUnlock,
        _onTick = onTick;

  StreamSubscription<int>? _subscibtion;
  bool get closed => _subscibtion == null;
  int get tick => _tick;

  void logout() {
    _lock.run(() {
      if (closed) return;
      _subscibtion?.cancel();
      _subscibtion = null;
    });
  }

  void login() {
    _lock.run(() {
      final bool unlock = _onLockTime();
      if (unlock && closed) {
        assert(_subscibtion == null);
        _subscibtion?.cancel();
        _tick = locktime().value;
        _subscibtion = _buildTimer();
        Logging.debug(
          fn: () =>
              AppLogData(runtime: runtimeType, function: "login", msg: "timer start"),
        );
      }
    });
  }

  void reset() {
    if (closed) return;
    final tick = _tick;
    _tick = locktime().value;
    if (tick < remainingShow) {
      _onTick(_tick);
    }
  }

  Future<void> _onListenTimer(int _) async {
    if (closed || _tick == 0) return;
    int? tick = --_tick;
    if (tick <= 0) tick = null;
    if (tick == null || tick < remainingShow) {
      _onTick(tick);
      if (tick == null) {
        await _onTimeout();
      }
    }
  }

  StreamSubscription<int> _buildTimer() {
    return Stream<int>.periodic(
      Duration(seconds: 1),
      (computationCount) => computationCount,
    ).listen(_onListenTimer);
  }
}
