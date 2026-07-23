import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';

class _WindowsFrameTracker with WindowListener {
  final DynamicVoid onChange;
  const _WindowsFrameTracker(this.onChange);

  @override
  void onWindowResize() {
    super.onWindowResize();
    onChange();
  }

  @override
  void onWindowMove() {
    super.onWindowMove();
    onChange();
  }
}

mixin DesktopFrameTracker on StateController {
  MainAppContext get context;
  APPStatus get appStatus;
  late _WindowsFrameTracker _tracker;

  GlobalKey<NavigatorState>? get navigatorKey;
  IDesktopPlatformInterface? _windowsPlatform;
  Timer? _onUpdateFrame;

  Future<void> _updateFrame() async {
    final pixelRatio =
        navigatorKey?.currentContext?.mediaQuery.devicePixelRatio;
    if (pixelRatio == null) return;
    WidgetRect? rect = await _windowsPlatform?.getBounds(pixelRatio);
    if (rect == null) return;
    rect = rect.copyWith(devicePixelRatio: pixelRatio);
    context.setting
        .updateAppSetting(context.setting.setting.copyWith(size: rect))
        .then((e) {
      Logg.log(
          "Frame updated! ${rect?.x} ${rect?.y} ${rect?.height} ${rect?.width} $e");
    });
  }

//// [Main]: Frame updated! 1139.0 83.0 729.0 833.0 ResultOk(null)
  void _start() {
    if (appStatus.status.isError) return;
    context
        .platformInterface()
        .andThen((e) => e.desktop.toResult())
        .map((wPlatform) {
      _windowsPlatform = wPlatform;
      _tracker = _WindowsFrameTracker(_detectFrame);
      wPlatform.addListener(_tracker);
    });
  }

  void _detectFrame() {
    _onUpdateFrame?.cancel();
    _onUpdateFrame = null;
    _onUpdateFrame = Timer(APPConst.twoSecoundDuration, _updateFrame);
  }

  @override
  void init() {
    super.init();
    _start();
  }
}
