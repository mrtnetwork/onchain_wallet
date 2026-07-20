import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class ContainerWithBorder extends StatelessWidget {
  const ContainerWithBorder(
      {super.key,
      this.child,
      this.padding = WidgetConstant.padding10,
      this.margin = WidgetConstant.padding5,
      this.onRemove,
      this.borderRadius,
      this.backgroundColor,
      this.onRemoveWidget,
      this.onRemoveIcon,
      this.validate = true,
      this.validateText,
      this.shadow = false,
      this.enableTap = true,
      this.iconAlginment = CrossAxisAlignment.center,
      this.onTapError,
      this.constraints = WidgetConstant.constraintsMinHeight60,
      this.errorIcon,
      this.hoverColor,
      this.focusColor});
  final Widget? child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final DynamicVoid? onRemove;
  final Widget? onRemoveWidget;
  final Widget? onRemoveIcon;
  final bool validate;
  final String? validateText;
  final bool shadow;
  final bool enableTap;
  final CrossAxisAlignment iconAlginment;
  final DynamicVoid? onTapError;
  final BoxConstraints? constraints;
  final IconData? errorIcon;
  final Color? focusColor;
  final Color? hoverColor;
  @override
  Widget build(BuildContext context) {
    final tap = enableTap && onRemove != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: borderRadius ?? WidgetConstant.border8,
          onTap: tap ? onRemove : null,
          mouseCursor: tap ? SystemMouseCursors.click : null,
          hoverColor: hoverColor,
          focusColor: focusColor,
          child: Container(
            padding: padding,
            margin: margin,
            constraints: constraints,
            decoration: BoxDecoration(
                color: backgroundColor ?? context.colors.primaryContainer,
                borderRadius: borderRadius ?? WidgetConstant.border8,
                boxShadow: !shadow
                    ? null
                    : [
                        BoxShadow(
                            color: context.colors.shadow,
                            blurRadius: 4,
                            spreadRadius: 0.2)
                      ],
                border: validate
                    ? null
                    : Border.all(color: context.colors.error, width: 2, strokeAlign: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConditionalWidget(
                  enable: child != null,
                  onActive: (context) => Row(
                    crossAxisAlignment: iconAlginment,
                    children: [
                      Expanded(child: child!),
                      if (onRemove != null)
                        Row(
                          children: [
                            WidgetConstant.width8,
                            onRemoveWidget ??
                                IconButton(
                                    onPressed: onRemove,
                                    icon: onRemoveIcon ?? Icon(Icons.remove_circle))
                          ],
                        )
                    ],
                  ),
                ),
                APPAnimatedSize(
                    isActive: !validate && validateText != null,
                    onActive: (context) => ErrorTextContainer(
                          error: validateText ?? "",
                          margin: WidgetConstant.padding5,
                          // padding: WidgetConstant.padding10,
                          oTapError: onTapError,
                          errorIcon: errorIcon,
                          showErrorIcon: onTapError != null,
                        ),
                    onDeactive: (context) => WidgetConstant.sizedBox)
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AddOrEditIconWidget extends StatelessWidget {
  const AddOrEditIconWidget(this.edit, {this.color, super.key});
  final bool edit;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return switch (edit) {
      true => Icon(Icons.edit, color: color ?? context.onPrimaryContainer),
      _ => Icon(Icons.add_box, color: color ?? context.onPrimaryContainer)
    };
  }
}

class EditOrRemoveIconWidget extends StatelessWidget {
  const EditOrRemoveIconWidget(this.remove, {this.color, super.key});
  final bool remove;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return switch (remove) {
      true => Icon(Icons.remove_circle, color: color ?? context.onPrimaryContainer),
      _ => Icon(Icons.edit, color: color ?? context.onPrimaryContainer)
    };
  }
}

class AddOrRemoveIconWidget extends StatelessWidget {
  const AddOrRemoveIconWidget(this.remove, {this.color, super.key});
  final bool remove;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return switch (remove) {
      true => Icon(Icons.remove_circle, color: color ?? context.onPrimaryContainer),
      _ => Icon(Icons.add_box, color: color ?? context.onPrimaryContainer)
    };
  }
}

class CustomizedContainer extends StatelessWidget {
  const CustomizedContainer(
      {super.key,
      this.child,
      this.padding = WidgetConstant.padding10,
      this.margin = WidgetConstant.padding5,
      this.onRemove,
      this.borderRadius,
      this.backgroundColor,
      this.onRemoveWidget,
      this.onRemoveIcon,
      this.validate = true,
      this.validateText,
      this.shadow = false,
      this.enableTap = true,
      this.iconAlginment = CrossAxisAlignment.center,
      this.onTapError,
      this.constraints = WidgetConstant.constraintsMinHeight60,
      this.errorIcon,
      this.hoverColor,
      this.focusColor,
      this.onStackIcon,
      this.onTapStackIcon,
      this.reverseColor,
      this.onStackWidget,
      this.onButtomStackWidget});
  final Widget? child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? reverseColor;
  final DynamicVoid? onRemove;
  final Widget? onRemoveWidget;
  final Widget? onRemoveIcon;
  final IconData? onStackIcon;
  final DynamicVoid? onTapStackIcon;
  final Widget? onStackWidget;
  final bool validate;
  final String? validateText;
  final bool shadow;
  final bool enableTap;
  final CrossAxisAlignment iconAlginment;
  final DynamicVoid? onTapError;
  final BoxConstraints? constraints;
  final IconData? errorIcon;
  final Color? focusColor;
  final Color? hoverColor;
  final Widget? onButtomStackWidget;
  @override
  Widget build(BuildContext context) {
    final backgroundColor = this.backgroundColor ?? context.colors.primaryContainer;
    final reverseColor = this.reverseColor ?? context.colors.onPrimaryContainer;
    final tap = enableTap && (onRemove != null || onTapStackIcon != null);
    final bool hasTapStack = onTapStackIcon != null;
    return Stack(
      children: [
        InkWell(
          borderRadius: borderRadius ?? WidgetConstant.border8,
          onTap: tap ? onRemove ?? onTapStackIcon : null,
          mouseCursor: tap ? SystemMouseCursors.click : null,
          hoverColor: hoverColor,
          focusColor: focusColor,
          child: Container(
            padding: padding,
            margin: margin,
            constraints: constraints,
            decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius ?? WidgetConstant.border8,
                boxShadow: !shadow
                    ? null
                    : [
                        BoxShadow(
                            color: context.colors.shadow,
                            blurRadius: 4,
                            spreadRadius: 0.2)
                      ],
                border: validate
                    ? null
                    : Border.all(color: context.colors.error, width: 2, strokeAlign: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConditionalWidget(
                  enable: child != null,
                  onActive: (context) => Row(
                    crossAxisAlignment: iconAlginment,
                    children: [
                      Expanded(child: child!),
                      ConditionalWidget(
                          enable: onRemove != null,
                          onActive: (context) => Row(
                                children: [
                                  WidgetConstant.width8,
                                  onRemoveWidget ??
                                      IconButton(
                                          onPressed: onRemove,
                                          icon:
                                              onRemoveIcon ?? Icon(Icons.remove_circle)),
                                  if (hasTapStack) WidgetConstant.width20,
                                ],
                              ))
                      // if (onRemove != null)
                    ],
                  ),
                ),
                APPAnimatedSize(
                    isActive: !validate && validateText != null,
                    onActive: (context) => ErrorTextContainer(
                          error: validateText ?? "",
                          margin: WidgetConstant.padding5,
                          // padding: WidgetConstant.padding10,
                          oTapError: onTapError,
                          errorIcon: errorIcon,
                          showErrorIcon: onTapError != null,
                        ),
                    onDeactive: (context) => WidgetConstant.sizedBox)
              ],
            ),
          ),
        ),
        ConditionalWidget(
            enable: onTapStackIcon != null,
            onActive: (context) => Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: margin,
                  child: Material(
                      elevation: 5,
                      color: reverseColor,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8), bottomLeft: Radius.circular(25)),
                      child: ConditionalWidget(
                          enable: onStackWidget != null,
                          onDeactive: (context) => InkWell(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(25)),
                                onTap: onTapStackIcon,
                                child: IgnorePointer(
                                  child: IconButton(
                                      onPressed: onTapStackIcon,
                                      icon: Icon(onStackIcon ?? Icons.remove_circle,
                                          color: backgroundColor)),
                                ),
                              ),
                          onActive: (context) => ClipRRect(
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(25)),
                              child: onStackWidget!))),
                ))),
        // Positioned.fill(child: child),
        ConditionalWidgetWithValue(
            value: onButtomStackWidget,
            onValue: (context, onButtomStackWidget) => Positioned(
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: margin,
                  child: Material(
                      elevation: 5,
                      color: reverseColor,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                      child: onButtomStackWidget),
                )))
      ],
    );
  }
}
