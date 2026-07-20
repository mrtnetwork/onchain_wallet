import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

import 'animated/widgets/animated_switcher.dart';
import 'widget_constant.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  const PasswordStrengthIndicator({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    Widget buildItem(String label, String info, bool reached, Color reachedColor,
        {IconData reachedIcon = Icons.check_circle}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(reachedIcon, size: APPConst.smallIconSize, color: reachedColor),
          WidgetConstant.width8,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(label,
                    style: context.textTheme.labelLarge?.copyWith(color: reachedColor)),
                WidgetConstant.width8,
                Text(info, style: context.textTheme.bodyMedium)
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        APPAnimatedSwitcher(enable: strength, widgets: {
          PasswordStrength.weak: (context) => buildItem(
              PasswordStrength.weak.tr.tr,
              "weak_password_validator".tr,
              strength.index >= PasswordStrength.weak.index,
              context.colors.error,
              reachedIcon: Icons.cancel),
          PasswordStrength.fair: (context) => buildItem(
              PasswordStrength.fair.tr.tr,
              "fair_passowrd_desc".tr,
              strength.index >= PasswordStrength.fair.index,
              context.colors.error,
              reachedIcon: Icons.warning),
          PasswordStrength.normal: (context) => buildItem(
              PasswordStrength.normal.tr.tr,
              "normal_password_desc".tr,
              strength.index >= PasswordStrength.normal.index,
              context.colors.primary),
          PasswordStrength.strong: (context) => buildItem(
              PasswordStrength.strong.tr.tr,
              "strong_password_desc".tr,
              strength.index >= PasswordStrength.strong.index,
              context.colors.primary),
        }),
      ],
    );
  }
}
