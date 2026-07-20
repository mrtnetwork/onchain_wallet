import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

mixin AndroidSecureState<T extends StatefulWidget> on SafeState<T> {
  bool _enabled = false;
  @override
  void onInitOnce() {
    super.onInitOnce();
    appContext?.platformUtls.secureFlag(true).then((e) {
      if (e.isOk) _enabled = true;
    });
  }

  @override
  void safeDispose() {
    super.safeDispose();
    if (_enabled) {
      appContext?.platformUtls.secureFlag(false).then((e) {
        _enabled = false;
      });
    }
  }
}
