import 'dart:async';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/error/exception/wallet_ex.dart';
import 'package:on_chain_wallet/app/models/models/typedef.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';

class MethodUtils {
  static Future<void> delayed(
      {Duration duration = const Duration(milliseconds: 1000)}) async {
    return await Future.delayed(duration);
  }

  static Future<T> executeAfterDelay<T>(Future<T> Function() t,
      {Duration duration = Duration.zero}) async {
    return await Future.delayed(duration, t);
  }

  static T? fallbackOnException<T>(T? Function() t,
      {T? defaultValue,
      ONERROR? onError,
      bool logOnDebug = true,
      LoggerMode mode = LoggerMode.debug}) {
    final result =
        IResult.callSync(t, onError: onError, logOnDebug: logOnDebug, mode: mode);
    return result.ok() ?? defaultValue;
  }
}

typedef CompleterResult = Completer Function();

class Cancelable<T> {
  Completer<T>? _completer;
  bool get isPending => _completer != null;
  void cancel() {
    final c = _completer;
    if (c == null || c.isCompleted) return;
    _completer = null;
    MethodUtils.fallbackOnException(
        () => c.completeError(AppExceptionConst.requestCanceled));
  }

  void success(FutureOr<T> Function() func) async {
    final c = _completer;
    if (c == null) return;

    try {
      final result = await func();
      if (!c.isCompleted) c.complete(result);
    } catch (e, st) {
      if (!c.isCompleted) c.completeError(e, st);
    } finally {
      _completer = null;
    }
  }

  void setup(Completer<T> completer) {
    assert(_completer == null, "please first complete or cancel");
    _completer = completer;
  }

  void dispose() {
    _completer = null;
  }
}

class CancelableListener {
  final Set<DynamicVoid> _listeners = {};

  void _emitListeners({DynamicVoid? listener}) {
    if (!_canceled) return;
    if (listener != null) {
      listener();
      return;
    }
    for (final i in [..._listeners]) {
      i();
    }
  }

  bool _canceled = false;
  void addListener(DynamicVoid listener) {
    _listeners.add(listener);
    _emitListeners(listener: listener);
  }

  void removeListener(DynamicVoid listener) {
    _listeners.remove(listener);
  }

  void cancel() {
    if (_canceled) return;
    _canceled = true;
    _emitListeners();
  }

  void close() {
    _listeners.clear();
  }

  void reset() {
    _listeners.clear();
    _canceled = false;
  }
}

class OnceCancelable {
  bool _canceled = false;
  final Completer<IResult> _completer = Completer<IResult>();
  Completer<IResult> get complete => _completer;
  bool get isCompleted => _completer.isCompleted;
  bool get isCanceled => _canceled;

  // Future<IResult> get future => _completer.future;

  void cancel() {
    if (_completer.isCompleted || _canceled) return;
    _canceled = true;
    _completer.complete(ResultErr.fromException(AppExceptionConst.requestCanceled));
  }

  Future<IResult<T>> success<T extends Object?>(
      FutureOr<IResult<T>> Function() func) async {
    final c = _completer;
    if (_canceled) {
      return ResultErr.fromException(AppExceptionConst.requestCanceled);
    }
    assert(!c.isCompleted, "Already completed.");
    final future = _completer.future;
    if (c.isCompleted) return (await future).cast<T>();
    Future<void> call() async {
      try {
        final r = func();

        final result = r is Future<IResult<T>> ? await r : r;
        if (!_canceled) {
          c.complete(result);
        }
      } catch (e, trace) {
        if (!_canceled) {
          c.complete(ResultErr.from(e, trace: trace));
        }
      }
    }

    call();
    return (await future).cast<T>();
  }
}

class OnceCancelableTemplate<T extends Object?> {
  bool _canceled = false;
  final Completer<IResult<T>> completer = Completer<IResult<T>>();
  bool get isCompleted => completer.isCompleted;
  bool get isCanceled => _canceled;

  // Future<IResult> get future => _completer.future;

  void cancel() {
    if (completer.isCompleted || _canceled) return;
    _canceled = true;
    completer.complete(ResultErr.fromException(AppExceptionConst.requestCanceled));
  }

  Future<IResult<T>> success(FutureOr<IResult<T>> Function() func) async {
    final c = completer;
    if (_canceled) {
      return ResultErr.fromException(AppExceptionConst.requestCanceled);
    }
    assert(!c.isCompleted, "Already completed.");
    final future = completer.future;
    if (c.isCompleted) return await future;
    Future<void> call() async {
      try {
        final r = func();
        final result = r is Future<IResult<T>> ? await r : r;
        if (!_canceled) {
          c.complete(result);
        }
      } catch (e, trace) {
        if (!_canceled) {
          c.complete(ResultErr.from(e, trace: trace));
        }
      }
    }

    call();
    return (await future).cast<T>();
  }
}
