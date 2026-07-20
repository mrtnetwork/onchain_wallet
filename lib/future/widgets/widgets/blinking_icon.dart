import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/constant/global/app.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/animated/widgets/animated_switcher.dart';
import 'package:on_chain_wallet/future/widgets/widgets/conditional_widget.dart';
import 'package:on_chain_wallet/future/widgets/widgets/opacity_widget.dart';

class BlinkingIcon extends StatefulWidget {
  final bool blinking;
  final Widget Function(BuildContext context) builder;
  const BlinkingIcon({required this.builder, required this.blinking, super.key});

  @override
  State<BlinkingIcon> createState() => _BlState();
}

class _BlState extends State<BlinkingIcon> with SafeState<BlinkingIcon> {
  bool _blinking = false;
  StreamSubscription<int>? _listener;

  void start() {
    _listener?.cancel();
    _listener = Stream.periodic(
      APPConst.oneSecoundDuration,
      (computationCount) => 0,
    ).listen((v) {
      updateState(() {
        _blinking = !_blinking;
      });
    });
  }

  @override
  void didUpdateWidget(covariant BlinkingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blinking) {
      if (_listener == null) start();
    } else {
      if (_listener != null) {
        _listener?.cancel();
        _listener = null;
      }
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    if (widget.blinking) start();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _listener?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
      enable: widget.blinking,
      onDeactive: (context) => widget.builder(context),
      onActive: (context) => APPAnimated(
          duration: APPConst.oneSecoundDuration,
          isActive: _blinking,
          onDeactive: (context) => widget.builder(context),
          onActive: (context) => DisabledWidget(
                disabled: true,
                onActive: (context, _) => widget.builder(context),
              )),
    );
  }
}
