import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/typdef/typedef.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class DisabledWidget extends StatelessWidget {
  const DisabledWidget(
      {this.disabled = true,
      required this.onActive,
      this.isExpanded = false,
      this.duration = APPConst.animationDuraion,
      this.alignment = Alignment.topCenter,
      this.ignoring = false,
      super.key});
  final bool disabled;
  final WidgetContextBool onActive;
  final Duration duration;
  final Alignment alignment;
  final bool isExpanded;
  final bool ignoring;
  @override
  Widget build(BuildContext context) {
    return APPAnimated(
      alignment: alignment,
      duration: duration,
      isActive: disabled,
      isExpanded: isExpanded,
      onActive: (context) => IgnorePointer(
        ignoring: ignoring,
        child: Opacity(
          opacity: APPConst.disabledOpacity,
          child: onActive(context, false),
        ),
      ),
      onDeactive: (context) => onActive(context, true),
    );
  }
}
