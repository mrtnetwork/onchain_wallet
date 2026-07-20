import 'dart:async';

import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/error/exception/wallet_ex.dart';
import 'package:on_chain_wallet/app/error/extension/extension.dart';
import 'package:on_chain_wallet/app/models/models/typedef.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';

class SafeStreamController<T extends Object?> {
  final StreamController<T> _controller;
  final String? name;
  SafeStreamController({StreamController<T>? controller, required String this.name})
      : _controller = controller ?? StreamController();

  bool get isClosed => _controller.isClosed;
  bool get hasListener => _controller.hasListener;

  SafeStreamController.broadcast({required String this.name, bool sync = false})
      : _controller = StreamController<T>.broadcast(sync: sync);

  void onCancelListener(DynamicVoid? cb) => _controller.onCancel = cb;
  void onListenListener(DynamicVoid? cb) => _controller.onListen = cb;
  Stream<T> stream() {
    Logging.error(
      when: () => isClosed,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "stream",
          msg:
              "Cannot listen to stream '${name ?? 'unnamed'}': the stream controller is already closed."),
    );
    if (isClosed) return Stream.empty();
    return _controller.stream;
  }

  IResult<void> _add(T object, bool listenerRequired) {
    Logging.error(
      when: () => isClosed,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "add",
          msg:
              "Cannot add event to stream '${name ?? 'unnamed'}': the stream controller is already closed"),
    );
    if (_controller.isClosed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    if (listenerRequired && !hasListener) return ResultOk(null);
    _controller.add(object);
    return ResultOk(null);
  }

  IResult<void> _addError(Object object, bool listenerRequired) {
    Logging.error(
      when: () => isClosed,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "addError",
          msg:
              "Cannot add error event to stream '${name ?? 'unnamed'}': the stream controller is already closed"),
    );
    if (_controller.isClosed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    if (listenerRequired && !hasListener) return ResultOk(null);
    _controller.addError(object);
    return ResultOk(null);
  }

  IResult<void> add(T object) {
    return _add(object, false);
  }

  IResult<void> addError(Object object) {
    return _addError(object, false);
  }

  IResult<void> close() {
    Logging.info(
      when: () => isClosed,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "close",
          msg:
              "Cannot close stream '${name ?? 'unnamed'}': the stream controller is already closed."),
    );
    if (_controller.isClosed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    _controller.close();
    return ResultOk(null);
  }

  IResult<void> addIfListener(T object) {
    return _add(object, true);
  }

  IResult<void> addErrorIfListener(Object object) {
    return _addError(object, true);
  }
}
