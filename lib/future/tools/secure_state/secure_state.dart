import 'package:flutter/material.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/platform_interface.dart';

mixin SecureState<T extends StatefulWidget> on State<T> {
  bool _enabled = false;
  @override
  void initState() {
    super.initState();
    if (PlatformInterface.appPlatform == AppPlatform.android) {
      PlatformInterface.instance.secureFlag(isSecure: true);
      _enabled = true;
    }
  }

  @override
  void dispose() {
    if (_enabled) {
      PlatformInterface.instance.secureFlag(isSecure: false);
      _enabled = false;
    }
    super.dispose();
  }
}
