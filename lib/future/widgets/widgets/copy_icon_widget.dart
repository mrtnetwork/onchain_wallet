import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/animated/widgets/animated_switcher.dart';
import 'widget_constant.dart';

enum _CopyTextStatus {
  idlle,
  pending,
  success,
  error;

  bool get isIdle => this == idlle;
}

mixin _CopyTextState<T extends StatefulWidget> on SafeState<T> {
  String get dataToCopy;
  String? get message;
  bool get isSensitive;
  _CopyTextStatus status = _CopyTextStatus.idlle;
  void onTap(BuildContext context) async {
    if (!status.isIdle) return;
    status = _CopyTextStatus.pending;
    updateState();
    final response =
        await context.appContextOrNull?.platformUtls.writeClipboard(dataToCopy);
    if (response?.ok() ?? false) {
      status = _CopyTextStatus.success;
      context.showAlert(message ?? "copied_to_clipboard".tr);
    } else {
      status = _CopyTextStatus.error;
      context.showAlert("copied_to_clipboard_faild".tr);
    }
    await Future.delayed(APPConst.milliseconds100);
    updateState();
    await Future.delayed(APPConst.oneSecoundDuration);
    status = _CopyTextStatus.idlle;
    updateState();
    if (!isSensitive) return;
    _resetClipoard(dataToCopy, context.appContextOrNull);
  }

  static void _resetClipoard(String txt, AppContext? context) {
    if (context == null) return;
    MethodUtils.executeAfterDelay(() async {
      final data = await context.platformUtls.readClipboard();
      if (data.ok() != txt) return;
      context.platformUtls.writeClipboard('');
    }, duration: APPConst.tenSecoundDuration);
  }
}

class CopyTextIcon extends StatefulWidget {
  const CopyTextIcon(
      {super.key,
      required this.dataToCopy,
      this.widget,
      this.size,
      this.messaage,
      this.color,
      this.isSensitive = false});

  final String dataToCopy;
  final double? size;
  final String? messaage;
  final Color? color;
  final Widget? widget;
  final bool isSensitive;

  @override
  State<CopyTextIcon> createState() => CopyTextIconState();
}

class CopyTextIconState extends State<CopyTextIcon> with SafeState, _CopyTextState {
  @override
  String get dataToCopy => widget.dataToCopy;

  @override
  bool get isSensitive => widget.isSensitive;

  @override
  String? get message => widget.messaage;

  @override
  Widget build(BuildContext context) {
    final icon = IconButton(
      tooltip: "copy_to_clipboard".tr,
      onPressed: () => onTap(context),
      icon: APPAnimatedSwitcher(enable: status, widgets: {
        _CopyTextStatus.idlle: (context) =>
            Icon(Icons.copy, size: widget.size, color: widget.color),
        _CopyTextStatus.pending: (context) => SizedBox(
            width: widget.size ?? APPConst.iconSize,
            height: widget.size ?? APPConst.iconSize,
            child: CircularProgressIndicator(color: widget.color)),
        _CopyTextStatus.success: (context) =>
            Icon(Icons.check_circle, size: widget.size, color: widget.color),
        _CopyTextStatus.error: (context) =>
            Icon(Icons.error, size: widget.size, color: context.colors.error)
      }),
    );
    return InkWell(
      onTap: () => onTap(context),
      customBorder: RoundedRectangleBorder(
        borderRadius: WidgetConstant.border8,
      ),
      child: widget.widget != null
          ? Row(
              children: [Expanded(child: widget.widget!), WidgetConstant.width8, icon],
            )
          : icon,
    );
  }
}

class CopyableTextWidget extends StatefulWidget {
  const CopyableTextWidget(
      {super.key,
      required this.text,
      this.maxLines = 1,
      this.size,
      this.messaage,
      this.color,
      this.widget,
      this.isSensitive = false});

  final String text;
  final double? size;
  final String? messaage;
  final Color? color;
  final Widget? widget;
  final bool isSensitive;
  final int? maxLines;

  @override
  State<CopyableTextWidget> createState() => CopyableTextWidgetState();
}

class CopyableTextWidgetState extends State<CopyableTextWidget>
    with SafeState, _CopyTextState {
  @override
  String get dataToCopy => widget.text;

  @override
  bool get isSensitive => widget.isSensitive;

  @override
  String? get message => widget.messaage;

  @override
  Widget build(BuildContext context) {
    final icon = IconButton(
      onPressed: () => onTap(context),
      icon: APPAnimatedSwitcher(enable: status, widgets: {
        _CopyTextStatus.idlle: (context) =>
            Icon(Icons.copy, size: widget.size, color: widget.color),
        _CopyTextStatus.pending: (context) => SizedBox(
            width: widget.size ?? APPConst.iconSize,
            height: widget.size ?? APPConst.iconSize,
            child: CircularProgressIndicator(color: widget.color)),
        _CopyTextStatus.success: (context) =>
            Icon(Icons.check_circle, size: widget.size, color: widget.color),
        _CopyTextStatus.error: (context) =>
            Icon(Icons.error, size: widget.size, color: context.colors.error)
      }),
    );
    return InkWell(
      onTap: () => onTap(context),
      customBorder: RoundedRectangleBorder(
        borderRadius: WidgetConstant.border8,
      ),
      child: Row(
        children: [
          Expanded(
              child: widget.widget ??
                  Text(
                    widget.text,
                    style: context.textTheme.bodyMedium?.copyWith(color: widget.color),
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.ellipsis,
                  )),
          WidgetConstant.width8,
          icon
        ],
      ),
    );
  }
}
