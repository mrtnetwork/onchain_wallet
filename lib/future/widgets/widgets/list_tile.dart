import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/context.dart';
import 'package:on_chain_wallet/app/models/models/typedef.dart'
    show BoolVoid, DynamicVoid, NullBoolVoid;
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';

class AppListTile extends StatelessWidget {
  const AppListTile(
      {super.key,
      this.title,
      this.subtitle,
      this.trailing,
      this.leading,
      this.onTap,
      this.contentPadding,
      this.tileColor,
      this.enabled = true,
      this.selected = false,
      this.disabled = false,
      this.maxLine = 2});
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final DynamicVoid? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final Color? tileColor;
  final bool enabled;
  final bool selected;
  final bool disabled;
  final int maxLine;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title == null
          ? null
          : DefaultTextStyle(style: context.textTheme.labelLarge!, child: title!),
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle(
              style: context.textTheme.bodyMedium!,
              maxLines: maxLine,
              overflow: TextOverflow.ellipsis,
              child: subtitle!,
            ),
      trailing: trailing,
      leading: leading,
      onTap: onTap,
      contentPadding: contentPadding,
      tileColor: tileColor,
      enabled: enabled,
      selected: selected,
    );
  }
}

class AppCheckListTile extends StatelessWidget {
  const AppCheckListTile(
      {super.key,
      this.onChanged,
      required this.value,
      this.title,
      this.subtitle,
      this.contentPadding,
      this.color,
      this.backgroundColor,
      this.maxLine = 2});
  final int? maxLine;
  final NullBoolVoid? onChanged;
  final bool value;
  final Widget? title;
  final Widget? subtitle;
  final EdgeInsets? contentPadding;
  final Color? color;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      onChanged: onChanged,
      value: value,
      contentPadding: contentPadding,
      fillColor: backgroundColor == null ? null : WidgetStatePropertyAll(backgroundColor),
      checkColor: color,
      title: title == null
          ? null
          : DefaultTextStyle(style: context.textTheme.labelLarge!, child: title!),
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle(
              style: context.textTheme.bodyMedium!,
              maxLines: maxLine,
              overflow: TextOverflow.ellipsis,
              child: subtitle!,
            ),
    );
  }
}

typedef APPGROUPRADIOWIDGET<T> = Widget Function(BuildContext context);

class AppGroupRadioBuilder<T extends Object?> extends StatelessWidget {
  const AppGroupRadioBuilder({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.builder,
  });
  final void Function(T? value) onChanged;
  final APPGROUPRADIOWIDGET<T> builder;
  final T groupValue;
  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
        onChanged: onChanged, groupValue: groupValue, child: builder(context));
  }
}

class AppRadioListTile<T> extends StatelessWidget {
  const AppRadioListTile(
      {super.key,
      required this.value,
      this.title,
      this.subtitle,
      this.secondary,
      this.enabled});
  final T value;
  final Widget? title;
  final Widget? secondary;
  final Widget? subtitle;
  final bool? enabled;
  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      value: value,
      secondary: secondary,
      enabled: enabled,
      title: title == null
          ? null
          : DefaultTextStyle(style: context.textTheme.labelLarge!, child: title!),
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle(
              style: context.textTheme.bodyMedium!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              child: subtitle!,
            ),
    );
  }
}

// class AppRadioListTile<T> extends StatelessWidget {
//   const AppRadioListTile(
//       {super.key,
//       required this.groupValue,
//       required this.onChanged,
//       required this.value,
//       this.title,
//       this.subtitle,
//       this.secondary});
//   final void Function(T? value) onChanged;
//   final T value;
//   final Widget? title;
//   final Widget? secondary;
//   final Widget? subtitle;
//   final T? groupValue;
//   @override
//   Widget build(BuildContext context) {
//     return RadioGroup<T>(
//       onChanged: onChanged,
//       groupValue: groupValue,
//       child: RadioListTile<T>(
//         value: value,
//         secondary: secondary,
//         title: title == null
//             ? null
//             : DefaultTextStyle(
//                 style: context.textTheme.labelLarge!, child: title!),
//         subtitle: subtitle == null
//             ? null
//             : DefaultTextStyle(
//                 style: context.textTheme.bodyMedium!,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 child: subtitle!,
//               ),
//       ),
//     );
//   }
// }

class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile(
      {super.key,
      this.onChanged,
      required this.value,
      this.title,
      this.subtitle,
      this.maxLine = 2,
      this.contentPadding,
      this.leading});
  final NullBoolVoid? onChanged;
  final bool value;
  final Widget? title;
  final Widget? subtitle;
  final int? maxLine;
  final EdgeInsets? contentPadding;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    return AppListTile(
      contentPadding: contentPadding,
      leading: leading,
      onTap: () => onChanged?.call(!value),
      trailing: Switch(value: value, onChanged: onChanged),
      title: title,
      subtitle: subtitle,
    );
    // return SwitchListTile(
    //   onChanged: onChanged,
    //   contentPadding: contentPadding,
    //   value: value,
    //   title: title == null
    //       ? null
    //       : DefaultTextStyle(
    //           style: context.textTheme.bodyMedium!
    //               .copyWith(fontWeight: FontWeight.bold),
    //           child: title!),
    //   subtitle: subtitle == null
    //       ? null
    //       : DefaultTextStyle(
    //           style: context.textTheme.bodyMedium!,
    //           maxLines: maxLine,
    //           overflow: TextOverflow.ellipsis,
    //           child: subtitle!,
    //         ),
    // );
  }
}

class APPExpansionListTile extends StatelessWidget {
  const APPExpansionListTile(
      {required this.title,
      this.margin = EdgeInsets.zero,
      this.subtitle,
      this.trailing,
      this.children = const <Widget>[],
      this.tilePadding,
      this.onExpansionChanged,
      this.color,
      this.reverse,
      this.initiallyExpanded = false,
      this.enabled = true,
      super.key});
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry margin;
  final BoolVoid? onExpansionChanged;
  final Color? color;
  final Color? reverse;
  final bool initiallyExpanded;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ExpansionTile(
          enabled: enabled,
          shape: RoundedRectangleBorder(borderRadius: WidgetConstant.border8),
          collapsedShape: RoundedRectangleBorder(borderRadius: WidgetConstant.border8),
          backgroundColor: color ?? context.primaryContainer,
          collapsedBackgroundColor: color ?? context.primaryContainer,
          tilePadding: tilePadding,
          collapsedIconColor: reverse ?? context.onPrimaryContainer,
          iconColor: reverse ?? context.onPrimaryContainer,
          initiallyExpanded: initiallyExpanded,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          onExpansionChanged: onExpansionChanged,
          children: children),
    );
  }
}

class APPCheckBox extends StatelessWidget {
  const APPCheckBox(
      {super.key,
      this.ignoring = false,
      this.color,
      this.value,
      this.onChanged,
      this.activePress = true,
      this.backgroundColor});
  final bool ignoring;
  final Color? color;
  final Color? backgroundColor;
  final bool? value;
  final NullBoolVoid? onChanged;
  final bool activePress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignoring,
      child: Checkbox(
        fillColor:
            backgroundColor == null ? null : WidgetStatePropertyAll(backgroundColor),
        checkColor: color,
        activeColor: backgroundColor,
        value: value,
        onChanged: activePress ? onChanged : null,
      ),
    );
  }
}
