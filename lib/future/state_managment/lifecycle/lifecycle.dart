import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:on_chain_wallet/app/core.dart';

class AppLifecycle {
  final DynamicVoid onLostFocus;
  final DynamicVoid? onResume;
  final Duration? onLostTimeout;
  AppLifecycle({required this.onLostFocus, this.onLostTimeout, this.onResume});
  AppLifecycleListener? _listener;
  Timer? _timer;
  void _disposeTime() {
    _timer?.cancel();
    _timer = null;
  }

  void _onLostFocus() {
    final onLostTimeout = this.onLostTimeout;
    if (onLostTimeout == null) {
      onLostFocus();
      return;
    }
    _disposeTime();
    _timer = Timer(onLostTimeout, onLostFocus);
  }

  void _onResume() {
    _disposeTime();
    final onResume = this.onResume;
    if (onResume != null) onResume();
  }

  void init() {
    assert(_listener == null);
    if (_listener != null) return;
    _listener = AppLifecycleListener(
      onHide: _onLostFocus,
      onInactive: _onLostFocus,
      onResume: _onResume,
    );
  }

  void dispose() {
    _disposeTime();
    _listener?.dispose();
    _listener = null;
  }
}
