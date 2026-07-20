import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';

class SnackbarController {
  final ScaffoldFeatureController _controller;
  SnackbarController._(ScaffoldFeatureController controller) : _controller = controller;
  static SnackbarController? from(ScaffoldFeatureController? controller) {
    if (controller == null) return null;
    return SnackbarController._(controller);
  }

  bool _close = false;

  Future<IResult<bool>> get closed async {
    if (_close) return ResultOk(false);
    await _controller.closed;
    _close = true;
    return ResultOk(true);
  }

  void close() {
    if (_close) return;
    _close = true;
    _controller.close();
  }
}
