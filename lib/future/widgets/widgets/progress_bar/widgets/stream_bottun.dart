import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

enum StreamWidgetStatus {
  idle,
  success,
  error,
  progress;

  bool get inProgress => this == StreamWidgetStatus.progress;
}

class ButtonProgress extends StatefulWidget {
  const ButtonProgress({
    GlobalKey<StreamWidgetState>? key,
    required this.child,
    this.onError,
    this.padding = EdgeInsets.zero,
    this.initialStatus = StreamWidgetStatus.idle,
    this.backToIdle,
    this.fixedSize = true,
    this.color,
  }) : super(key: key);
  final StreamWidgetStatus initialStatus;
  final EdgeInsets padding;
  final Duration? backToIdle;
  final WidgetContext child;
  final WidgetDataContext<String?>? onError;
  final bool fixedSize;
  final Color? color;

  @override
  State<ButtonProgress> createState() => StreamWidgetState();
}

class StreamWidgetState extends State<ButtonProgress> with SafeState<ButtonProgress> {
  late StreamWidgetStatus _status = widget.initialStatus;
  String? error;

  void _listen(StreamWidgetStatus status) async {
    if (status == StreamWidgetStatus.progress || status == StreamWidgetStatus.idle) {
      return;
    }
    if (widget.backToIdle == null) return;
    await Future.delayed(widget.backToIdle ?? Duration.zero);
    updateStream(StreamWidgetStatus.idle);
  }

  void updateStream(StreamWidgetStatus status) {
    error = null;
    _status = status;
    _listen(status);
    updateState();
  }

  void errorProgress({String? message}) {
    error = message;
    _status = StreamWidgetStatus.error;
    _listen(_status);
    updateState();
  }

  bool get isProgress => _status == StreamWidgetStatus.progress;

  Size? size;

  void onChangeSize(Size v) {
    if (!widget.fixedSize) return;
    if (_status == StreamWidgetStatus.idle) {
      size = v;
      updateState();
    }
  }

  Size? getSize() {
    switch (_status) {
      case StreamWidgetStatus.idle:
      case StreamWidgetStatus.progress:
        return size;
      case StreamWidgetStatus.error:
        if (widget.onError != null) return null;
        return size;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: AnimatedSwitcher(
        duration: APPConst.animationDuraion,
        child: MeasureSize(
          onChange: onChangeSize,
          child: SizedBox.fromSize(
            size: getSize(),
            child: _ProgressWidget(
                key: ValueKey<StreamWidgetStatus>(_status),
                status: _status,
                color: widget.color,
                child: widget.child,
                onError: (context) =>
                    widget.onError?.call(context, error) ?? WidgetConstant.errorIcon),
          ),
        ),
      ),
    );
  }
}

class _ProgressWidget extends StatelessWidget {
  final StreamWidgetStatus status;
  final Color? color;
  final WidgetContext child;
  final WidgetContext? onError;
  const _ProgressWidget(
      {required this.status, required this.child, this.onError, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return ConditionalWidgets<StreamWidgetStatus>(enable: status, widgets: {
      StreamWidgetStatus.success: (context) => WidgetConstant.checkCircle,
      StreamWidgetStatus.error: (context) =>
          onError?.call(context) ?? WidgetConstant.errorIcon,
      StreamWidgetStatus.progress: (context) =>
          Center(child: APPCircularProgressIndicator(color: color)),
      StreamWidgetStatus.idle: child
    });
  }
}
