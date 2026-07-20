import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class MnemonicView extends StatelessWidget {
  const MnemonicView(
      {super.key,
      required this.mnemonic,
      this.padding = WidgetConstant.padding10,
      this.color,
      this.reverse});
  final List<String> mnemonic;
  final Color? color;
  final Color? reverse;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: WidgetConstant.border8),
      child: Container(
        decoration: BoxDecoration(borderRadius: WidgetConstant.border8),
        padding: padding,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(
              mnemonic.length,
              (index) => AnimatedSize(
                    duration: APPConst.animationDuraion,
                    child: Padding(
                      key: ValueKey<String>(mnemonic[index]),
                      padding: WidgetConstant.padding10,
                      child: Stack(
                        children: [
                          Chip(
                            elevation: 3,
                            padding: WidgetConstant.padding10,
                            backgroundColor: color ?? context.colors.primaryContainer,
                            label: Text(
                              mnemonic[index],
                              style:
                                  context.textTheme.bodySmall?.copyWith(color: reverse),
                            ),
                          ),
                          Badge.count(
                              count: index + 1,
                              backgroundColor: context.colors.tertiary,
                              textColor: context.colors.onTertiary)
                        ],
                      ),
                    ),
                  )),
        ),
      ),
    );
  }
}
