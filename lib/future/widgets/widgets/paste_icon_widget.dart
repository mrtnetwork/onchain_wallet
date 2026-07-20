import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class PasteTextIcon extends StatefulWidget {
  const PasteTextIcon(
      {required this.onPaste,
      required this.isSensitive,
      super.key,
      this.size,
      this.color});
  final StringVoid onPaste;
  final double? size;
  final Color? color;
  final bool isSensitive;

  @override
  State<PasteTextIcon> createState() => PasteTextIconState();
}

class PasteTextIconState extends State<PasteTextIcon> with SafeState<PasteTextIcon> {
  bool inPaste = false;
  void onTap() async {
    if (inPaste) return;
    inPaste = true;
    updateState(() {});
    try {
      final data = (await context.appContextOrNull?.platformUtls.readClipboard())?.ok();
      if (!mounted) return;
      final String txt = data ?? "";
      if (txt.isEmpty) {
        // ignore: use_build_context_synchronously
        context.showAlert("clipboard_empty".tr);
        await Future.delayed(APPConst.milliseconds100);
        return;
      }
      widget.onPaste(txt);
      if (widget.isSensitive) _resetClipoard(txt, context.appContext);
      await Future.delayed(APPConst.oneSecoundDuration);
    } finally {
      inPaste = false;
      updateState(() {});
    }
  }

  static void _resetClipoard(String txt, AppContext? context) {
    if (context == null) return;
    MethodUtils.executeAfterDelay(() async {
      final data = await context.platformUtls.readClipboard();
      if (data.ok() != txt) return;
      context.platformUtls.writeClipboard('');
    }, duration: APPConst.tenSecoundDuration);
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      inPaste ? Icons.check_circle : Icons.paste,
      size: widget.size,
      key: ValueKey<bool>(inPaste),
      color: widget.color,
    );
    return IconButton(
      onPressed: onTap,
      icon: AnimatedSwitcher(duration: APPConst.animationDuraion, child: icon),
    );
  }
}
