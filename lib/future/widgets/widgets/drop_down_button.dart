import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/models/models/typedef.dart'
    show FuncVoidNullT, NullStringT;
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';

class AppDropDownBottom<T> extends StatelessWidget {
  const AppDropDownBottom(
      {super.key,
      this.items,
      this.menuItems,
      this.label,
      this.selectedItemBuilder,
      this.value,
      this.onChanged,
      this.validator,
      this.icon,
      this.error,
      this.contentPadding,
      this.isExpanded = false,
      this.isDense = true,
      this.focusColor,
      this.fillColor,
      this.helperText,
      this.labelStyle,
      this.border = InputBorder.none,
      this.iconEnabledColor,
      this.hint});
  final Map<T, Widget>? items;
  final List<DropdownMenuItem<T>>? menuItems;
  final Map<T, Widget>? selectedItemBuilder;
  final FuncVoidNullT<T?>? onChanged;
  final NullStringT<T>? validator;
  final String? label;
  final Widget? icon;
  final String? error;
  final T? value;
  final bool isExpanded;
  final Color? focusColor;
  final Color? fillColor;
  final String? helperText;
  final TextStyle? labelStyle;
  final InputBorder border;
  final Color? iconEnabledColor;
  final String? hint;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final currentItems = menuItems ??
        items?.keys
            .map<DropdownMenuItem<T>>(
                (e) => DropdownMenuItem<T>(value: e, child: items![e]!))
            .toList() ??
        [];

    return DropdownButtonFormField<T>(
      items: selectedItemBuilder?.keys
              .map<DropdownMenuItem<T>>(
                  (e) => DropdownMenuItem<T>(value: e, child: selectedItemBuilder![e]!))
              .toList() ??
          currentItems,
      icon: icon,
      selectedItemBuilder: (context) => currentItems,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      isDense: isDense,
      initialValue: value,
      focusColor: focusColor,
      iconEnabledColor: iconEnabledColor,
      hint: hint == null ? null : Text(hint!),
      decoration: InputDecoration(
          focusColor: focusColor,
          labelText: label,
          errorText: error,
          fillColor: fillColor,
          errorMaxLines: 3,
          helperText: helperText,
          contentPadding: contentPadding,
          alignLabelWithHint: true,
          border: border,
          helperMaxLines: 3),
    );
  }
}

class AppDropDownBottomWithBorder<T> extends StatelessWidget {
  const AppDropDownBottomWithBorder(
      {super.key,
      this.items,
      this.menuItems,
      this.label,
      this.selectedItemBuilder,
      this.value,
      this.onChanged,
      this.validator,
      this.icon,
      this.contentPadding,
      this.isExpanded = false,
      this.isDense = true,
      this.backgroundColor,
      this.helperText,
      this.labelStyle,
      this.padding = WidgetConstant.padding10,
      this.margin = WidgetConstant.padding5,
      this.hint,
      this.borderRadius,
      this.reverseColor});
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Map<T, Widget>? items;
  final List<DropdownMenuItem<T>>? menuItems;
  final Map<T, Widget>? selectedItemBuilder;
  final FuncVoidNullT<T?>? onChanged;
  final NullStringT<T>? validator;
  final String? label;
  final Widget? icon;
  final T? value;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? reverseColor;
  final String? helperText;
  final TextStyle? labelStyle;
  final String? hint;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = this.backgroundColor ?? context.colors.primaryContainer;
    final reverseColor = this.reverseColor ?? context.colors.onPrimaryContainer;
    final currentItems = menuItems ??
        items?.keys
            .map<DropdownMenuItem<T>>(
                (e) => DropdownMenuItem<T>(value: e, child: items![e]!))
            .toList() ??
        [];
    final border = OutlineInputBorder(
        borderRadius: WidgetConstant.border8,
        borderSide: BorderSide(width: 0.25, color: reverseColor));
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? WidgetConstant.border8,
      ),
      child: DropdownButtonFormField<T>(
        items: selectedItemBuilder?.keys
                .map<DropdownMenuItem<T>>(
                    (e) => DropdownMenuItem<T>(value: e, child: selectedItemBuilder![e]!))
                .toList() ??
            items?.keys
                .map<DropdownMenuItem<T>>((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Padding(
                      padding: WidgetConstant.paddingVertical10,
                      child: items![e]!,
                    )))
                .toList() ??
            [],
        icon: icon,
        selectedItemBuilder: (context) {
          return currentItems;
        },
        onChanged: onChanged,
        validator: validator,
        isExpanded: isExpanded,
        isDense: isDense,
        initialValue: value,
        iconEnabledColor: reverseColor,
        hint: hint == null
            ? null
            : Text(hint!,
                style: context.textTheme.bodyMedium?.copyWith(color: reverseColor)),
        decoration: InputDecoration(
            focusColor: backgroundColor,
            labelText: label,
            labelStyle: context.textTheme.labelLarge?.copyWith(color: reverseColor),
            // errorText: error,
            fillColor: backgroundColor,
            errorMaxLines: 3,
            helperText: helperText,
            focusedBorder: border,
            enabledBorder: border,
            border: border,
            errorBorder: border,
            disabledBorder: border,
            contentPadding: contentPadding,
            alignLabelWithHint: true,
            // border: border,
            helperMaxLines: 3),
      ),
    );
  }
}
