import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';

class TooltipConstrainsWidget extends StatelessWidget {
  const TooltipConstrainsWidget({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: APPConst.tooltipConstrainedWidth),
        child: child);
  }
}
