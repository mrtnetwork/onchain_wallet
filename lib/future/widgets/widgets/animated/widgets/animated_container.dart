import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/typdef/typedef.dart';

class APPAnimatedContainer extends StatelessWidget {
  const APPAnimatedContainer(
      {required this.isActive,
      required this.onActive,
      required this.onDeactive,
      this.duration = APPConst.animationDuraion,
      this.alignment = Alignment.topCenter,
      super.key});
  final bool isActive;
  final WidgetContext onActive;
  final WidgetContext onDeactive;
  final Duration duration;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      alignment: alignment,
      child: isActive ? onActive(context) : onDeactive(context),
    );
  }
}
