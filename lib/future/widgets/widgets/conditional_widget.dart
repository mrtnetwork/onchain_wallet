import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/typdef/typedef.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';

class ConditionalWidgets<T> extends StatelessWidget {
  const ConditionalWidgets({required this.enable, required this.widgets, super.key});
  final T? enable;
  final Map<T?, WidgetContext> widgets;

  @override
  Widget build(BuildContext context) {
    return _Wrap(widgets[enable]?.call(context) ?? WidgetConstant.sizedBox,
        key: ValueKey<T?>(enable));
  }
}

class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget(
      {required this.onActive, this.onDeactive, this.enable = true, super.key});
  final WidgetContext onActive;
  final WidgetContext? onDeactive;
  final bool enable;
  @override
  Widget build(BuildContext context) {
    return ConditionalWidgets(enable: enable, widgets: {
      true: onActive,
      false: (context) => onDeactive?.call(context) ?? WidgetConstant.sizedBox
    });
  }
}

class ConditionalWidgetWithValue<T extends Object> extends StatelessWidget {
  const ConditionalWidgetWithValue(
      {required this.onValue, this.onNull, this.value, super.key});
  final WidgetContextWithItem<T> onValue;
  final WidgetContext? onNull;
  final T? value;
  @override
  Widget build(BuildContext context) {
    return switch (value) {
      final T obj => onValue(context, obj),
      _ => onNull?.call(context) ?? WidgetConstant.sizedBox
    };
  }
}

class ConditionalWidgetIResult<T extends Object> extends StatelessWidget {
  const ConditionalWidgetIResult(
      {required this.onOk, required this.result, this.onErr, super.key});
  final WidgetContextWithItem<T> onOk;
  final WidgetContextWithItem<ResultErr<T>>? onErr;
  final IResult<T> result;
  @override
  Widget build(BuildContext context) {
    return switch (result) {
      ResultOk<T>(:final value) => onOk(context, value),
      ResultErr<T> err => onErr?.call(context, err) ?? WidgetConstant.sizedBox,
    };
  }
}

class _Wrap extends StatelessWidget {
  const _Wrap(this.widget, {super.key});
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return widget;
  }
}

List<Widget> conditionalWidgetsBuilder({
  required BuildContext context,
  required bool enable,
  required WidgetsContext onActive,
}) {
  return switch (enable) {
    true => onActive(context),
    false => [],
  };
}
