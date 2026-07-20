import 'package:flutter/material.dart';

typedef NullWidget = Widget? Function();
typedef FuncWidget = Widget Function();
typedef FuncWidgetContext = Widget Function(BuildContext context);
typedef FuncVoidSize = Function(Size);
typedef FuncWidgetWithScroll = Widget Function(ScrollController);
typedef WidgetContext = Widget Function(BuildContext context);
typedef WidgetsContext = List<Widget> Function(BuildContext context);
typedef WidgetContextWithItem<T extends Object> = Widget Function(
    BuildContext context, T value);
typedef WidgetContextT<T extends Widget?> = T Function(BuildContext context);
typedef WidgetContextNullable = Widget? Function(BuildContext context);
typedef WidgetContextBool = Widget Function(BuildContext, bool);
typedef WidgetDataContext<T> = Widget Function(BuildContext context, T result);
typedef WidgetErrContext = Widget Function(
    BuildContext context, Object exception);
typedef VoidContext = void Function(BuildContext context);
