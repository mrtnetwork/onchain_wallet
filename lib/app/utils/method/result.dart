import 'dart:async';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_wallet/app/error/exception.dart';
import 'package:on_chain_wallet/app/localization/localization.dart';
import 'utiils.dart';

typedef ONERROR = AppLogData? Function(
  IException exception,
  StackTrace trace,
);

/// A Rust-like IResult type
sealed class IResult<T extends Object?> {
  const IResult();
  static IResult<T> callSync<T>(
    T Function() fn, {
    bool logOnDebug = true,
    ONERROR? onError,
    LoggerMode mode = LoggerMode.danger,
  }) {
    try {
      return ResultOk(fn());
    } catch (e, trace) {
      final exception = IExceptionUtils.findError(e);
      AppLogData? error;
      if (onError != null) {
        error = onError(exception, trace);
        if (error != null) {
          Logging.logData(fn: () => error, mode: mode);
        }
      }
      Logging.error(
        when: () => error == null && logOnDebug,
        fn: () => AppLogData(err: e, trace: trace.toString()),
      );
      return ResultErr<T>.fromException(exception, trace: trace);
    }
  }

  static Future<IResult<T>> call<T>(
    FutureOr<T> Function() t, {
    final Cancelable? cancelable,
    final Duration? delay,
    final Duration? timeout,
    final Duration? waitAtError,
    LoggerMode mode = LoggerMode.danger,
    bool logOnDebug = true,
    ONERROR? onError,
  }) async {
    try {
      FutureOr<T> r;
      if (cancelable == null) {
        if (delay != null) {
          r = Future.delayed(delay, t);
        } else {
          r = t();
        }
      } else {
        final Completer<T> completer = Completer<T>();
        cancelable.setup(completer);
        cancelable.success(() async {
          if (delay != null) await Future.delayed(delay);
          return t();
        });
        r = completer.future;
      }
      if (timeout != null) {
        if (r is Future<T>) {
          r = r.timeout(
            timeout,
            onTimeout: () => throw AppExceptionConst.timeout,
          );
        } else {
          r = Future.value(r).timeout(
            timeout,
            onTimeout: () => throw AppExceptionConst.timeout,
          );
        }
      }
      final result = await r;
      return ResultOk(result);
    } catch (e, trace) {
      final exception = IExceptionUtils.findError(e);
      AppLogData? error;
      if (onError != null) {
        error = onError(exception, trace);
        if (error != null) {
          Logging.logData(fn: () => error, mode: mode);
        }
      }
      Logging.error(
        when: () => error == null && logOnDebug,
        fn: () => AppLogData(err: e, trace: trace.toString()),
      );
      APIErrorConst.timeoutException;
      if (waitAtError != null && e != AppExceptionConst.requestCanceled) {
        await MethodUtils.delayed(duration: waitAtError);
      }
      return ResultErr<T>.fromException(exception, trace: trace);
    }
  }

  static Future<IResult<List<T>>> every<T>(
    List<FutureOr<T>> futures, {
    final Cancelable? cancelable,
    final Duration? delay,
    final Duration? timeout,
    final Duration? waitAtError,
    bool logOnDebug = true,
    ONERROR? onError,
  }) async {
    List<T> results = [];
    for (final i in futures) {
      final result = await IResult.call(() => i);
      if (result.isErr) {
        return result.map((e) => []);
      }
      results.add(result.unwrap());
    }
    return ResultOk(results);
  }

  static Future<IResult<List<T>>> anyError<T>(
    Iterable<FutureOr<IResult<T>>> futures, {
    final Cancelable? cancelable,
    final Duration? delay,
    final Duration? timeout,
    final Duration? waitAtError,
    bool logOnDebug = true,
    ONERROR? onError,
  }) async {
    List<T> results = [];
    for (final i in futures) {
      final result = await i;
      if (result.isErr) {
        return result.map((e) => []);
      }
      results.add(result.unwrap());
    }
    return ResultOk(results);
  }

  static Future<IResult<T>> block<T>(
    FutureOr<IResult<T>> Function() t, {
    final Cancelable? cancelable,
    final Duration? delay,
    final Duration? timeout,
    final Duration? waitAtError,
    bool logOnDebug = true,
    ONERROR? onError,
  }) async {
    final result = await IResult.call<IResult<T>>(t,
        cancelable: cancelable,
        timeout: timeout,
        delay: delay,
        logOnDebug: logOnDebug,
        onError: onError,
        waitAtError: waitAtError);
    return result.fold<IResult<T>>(onErr: (error) => error.cast<T>(), onOk: (v) => v);
  }

  static Future<IResult<T>> wait<T>(
    FutureOr<IResult<T>> Function() t, {
    final OnceCancelable? cancelable,
    final Duration? timeout,
    LoggerMode mode = LoggerMode.danger,
    bool logOnDebug = true,
    ONERROR? onError,
  }) async {
    try {
      FutureOr<IResult<T>> r;
      if (cancelable == null) {
        r = t();
      } else {
        r = cancelable.success<T>(t);
      }
      if (timeout != null) {
        if (r is Future<IResult<T>>) {
          r = r.timeout(
            timeout,
            onTimeout: () => ResultErr.fromException(AppExceptionConst.timeout),
          );
        } else {
          r = Future.value(r).timeout(
            timeout,
            onTimeout: () => ResultErr.fromException(AppExceptionConst.timeout),
          );
        }
      }
      final result = await r;
      return result;
    } catch (e, trace) {
      final exception = IExceptionUtils.findError(e);
      AppLogData? error;
      if (onError != null) {
        error = onError(exception, trace);
        if (error != null) {
          Logging.logData(fn: () => error, mode: mode);
        }
      }
      Logging.error(
        when: () => error == null && logOnDebug,
        fn: () => AppLogData(err: e, trace: trace.toString()),
      );

      return ResultErr<T>.fromException(exception, trace: trace);
    }
  }

  bool get isOk;
  bool get isErr;
  T unwrap();
  ResultErr<T> unwrapErr();
  T unwrapOr(T Function(ResultErr<T> err) f);
  T? ok();
  ResultErr<T>? err();
  IResult<U> cast<U>();

  IResult<U> map<U>(U Function(T value) f);
  IResult<U> mapCatch<U>(U Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error});
  Future<IResult<U>> mapAsync<U>(FutureOr<U> Function(T value) f);
  Future<IResult<U>> mapCatchAsync<U>(FutureOr<U> Function(T value) f);
  IResult<T> mapErr(IException Function(ResultErr<T> error) f);
  IResult<T?> unwrapOrNull();
  Future<IResult<T>> mapErrAsync(FutureOr<IException> Function(ResultErr<T> error) f);
  IResult<U> andThen<U>(IResult<U> Function(T value) f);
  IResult<U> andThenCatch<U>(IResult<U> Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error});
  Future<IResult<U>> andThenAsync<U>(FutureOr<IResult<U>> Function(T value) f);
  Future<IResult<U>> andThenCatchAsync<U>(FutureOr<IResult<U>> Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error});
  IResult<U> and<U>(IResult<U> Function(T? value, IException? error) f);
  Future<IResult<T>> onComplete(FutureOr<void> Function(T? value, ResultErr<T>? error) f);
  Future<IResult<U>> andAsync<U>(
      FutureOr<IResult<U>> Function(T? value, ResultErr<T>? error) f);

  Future<IResult<R>> thenAsync<R extends Object?>({
    required FutureOr<IResult<R>> Function(T value) onOk,
    FutureOr<IResult<R>> Function(ResultErr<T> error)? onErr,
  });
  R fold<R extends Object?>({
    R Function(T value)? onOk,
    R Function(ResultErr<T> error)? onErr,
  });
  void watch<R extends Object?>({
    void Function(T value)? onOk,
    void Function(ResultErr<T> error)? onErr,
  });
  Future<R> foldAsync<R extends Object?>({
    FutureOr<R> Function(T value)? onOk,
    FutureOr<R> Function(ResultErr<T> error)? onErr,
  });
  R foldOne<R extends Object?>(R Function(T? value, IException? error) f);
  Future<R> foldOneAsync<R extends Object?>(
      FutureOr<R> Function(T? value, IException? error) f);
  ResultErr<T> error();
  bool isError(IException exception) => false;

  bool canceled() {
    return isError(AppExceptionConst.requestCanceled);
  }
}

class ResultOk<T extends Object?> extends IResult<T> {
  final T value;

  const ResultOk(this.value);
  static const ResultOk<void> okVoid = ResultOk(null);

  @override
  bool get isOk => true;

  @override
  bool get isErr => false;

  @override
  T unwrap() => value;

  @override
  ResultErr<T> unwrapErr() {
    throw AppInternalError.internalError("ResultOk unwrapErr.");
  }

  @override
  T unwrapOr(T Function(ResultErr<T> err) f) => value;

  @override
  T ok() => value;

  @override
  ResultErr<T>? err() => null;

  @override
  IResult<U> map<U>(U Function(T value) f) {
    return ResultOk<U>(f(value));
  }

  @override
  Future<IResult<U>> mapAsync<U>(FutureOr<U> Function(T value) f) async {
    return ResultOk<U>(await f(value));
  }

  @override
  IResult<T> mapErr(IException Function(ResultErr<T> error) f) {
    return ResultOk<T>(value);
  }

  @override
  Future<IResult<T>> mapErrAsync(
      FutureOr<IException> Function(ResultErr<T> error) f) async {
    return ResultOk<T>(value);
  }

  @override
  IResult<U> andThen<U>(IResult<U> Function(T value) f) {
    return f(value);
  }

  @override
  Future<IResult<U>> andThenAsync<U>(FutureOr<IResult<U>> Function(T value) f) async {
    return await f(value);
  }

  @override
  R fold<R extends Object?>({
    R Function(T value)? onOk,
    R Function(ResultErr<T> error)? onErr,
  }) {
    if (onOk == null) {
      if (null is R) return null as R;
      final value = this.value;
      if (value is R) return value;
      throw AppInternalError.internalError("ResultOk fold.");
    }
    return onOk(value);
  }

  @override
  Future<R> foldAsync<R extends Object?>(
      {FutureOr<R> Function(T value)? onOk,
      FutureOr<R> Function(ResultErr<T> error)? onErr}) async {
    if (onOk == null) {
      if (null is R) return null as R;
      throw AppInternalError.internalError("ResultOk fold.");
    }
    return await onOk(value);
  }

  @override
  R foldOne<R extends Object?>(R Function(T? value, IException? error) f) {
    return f(value, null);
  }

  @override
  Future<R> foldOneAsync<R extends Object?>(
      FutureOr<R> Function(T? value, IException? error) f) async {
    return await f(value, null);
  }

  @override
  IResult<U> and<U>(IResult<U> Function(T? value, IException? error) f) {
    return f(value, null);
  }

  @override
  Future<IResult<U>> andAsync<U>(
      FutureOr<IResult<U>> Function(T value, ResultErr<T>? error) f) async {
    return await f(value, null);
  }

  @override
  String toString() => 'ResultOk($value)';

  @override
  IResult<U> cast<U>() {
    final value = this.value;
    if (value is U) {
      return ResultOk<U>(value);
    }
    return ResultErr.fromException(
        AppInternalError.internalError("Result casting failed."));
  }

  @override
  ResultErr<T> error() {
    throw AppInternalError.internalError("ResultErr unwrap.");
  }

  @override
  Future<IResult<U>> andThenCatchAsync<U>(FutureOr<IResult<U>> Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error}) async {
    try {
      return await f(value);
    } catch (exception, trace) {
      final iException = IExceptionUtils.findError(exception);
      if (logging != null) {
        final logData = logging(iException, trace);
        if (logData != null) {
          Logging.logData(fn: () => logData, mode: loggingMode);
        }
      }
      return ResultErr<U>.fromException(iException, trace: trace);
    }
  }

  @override
  IResult<U> andThenCatch<U>(IResult<U> Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error}) {
    try {
      return f(value);
    } catch (exception, trace) {
      final iException = IExceptionUtils.findError(exception);
      if (logging != null) {
        final logData = logging(iException, trace);
        if (logData != null) {
          Logging.logData(fn: () => logData, mode: loggingMode);
        }
      }
      return ResultErr<U>.fromException(iException, trace: trace);
    }
  }

  @override
  Future<IResult<U>> mapCatchAsync<U>(FutureOr<U> Function(T value) f) async {
    try {
      return ResultOk<U>(await f(value));
    } catch (exception, trace) {
      return ResultErr<U>.fromException(IExceptionUtils.findError(exception),
          trace: trace);
    }
  }

  @override
  IResult<U> mapCatch<U>(U Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error}) {
    try {
      return ResultOk<U>(f(value));
    } catch (exception, trace) {
      final iException = IExceptionUtils.findError(exception);
      if (logging != null) {
        final logData = logging(iException, trace);
        if (logData != null) {
          Logging.logData(fn: () => logData, mode: loggingMode);
        }
      }
      return ResultErr<U>.fromException(iException, trace: trace);
    }
  }

  @override
  IResult<T?> unwrapOrNull() {
    return this;
  }

  @override
  void watch<R extends Object?>(
      {void Function(T value)? onOk, void Function(ResultErr<T> error)? onErr}) {
    if (onOk != null) onOk(value);
  }

  @override
  Future<IResult<R>> thenAsync<R extends Object?>(
      {required FutureOr<IResult<R>> Function(T value) onOk,
      FutureOr<IResult<R>> Function(ResultErr<T> error)? onErr}) async {
    return onOk(value);
  }

  @override
  Future<ResultOk<T>> onComplete(
      FutureOr<dynamic> Function(T? value, ResultErr<T>? error) f) async {
    await f(value, null);
    return this;
  }
}

class ResultErr<T extends Object?> extends IResult<T> {
  final IException exception;
  final String? trace;
  final bool localizedMessage;

  const ResultErr._(this.exception, {this.trace, this.localizedMessage = false});
  factory ResultErr.fromNetSkd(NetResultStatus error, {StackTrace? trace}) {
    return ResultErr.fromException(
        APIError.fromNetSdk(NetSdkException(error), url: null));
  }
  factory ResultErr.from(Object error, {StackTrace? trace}) {
    return ResultErr.fromException(IExceptionUtils.findError(error), trace: trace);
  }
  factory ResultErr.fromException(IException error, {StackTrace? trace}) {
    final traceInfo = trace?.toString();
    return switch (error) {
      BaseAppException appExp => ResultErr._(error,
          trace: trace.toString(), localizedMessage: appExp.localizedMessage),
      OnChainBridgeException _ =>
        ResultErr._(error, trace: traceInfo, localizedMessage: false),
      _ => ResultErr._(error, trace: traceInfo, localizedMessage: true)
    };
  }

  @override
  bool get isOk => false;

  @override
  bool get isErr => true;

  @override
  T unwrap() {
    throw exception;
  }

  @override
  ResultErr<T> unwrapErr() => this;

  @override
  T unwrapOr(T Function(ResultErr<T> err) f) => f(this);

  @override
  T? ok() => null;

  @override
  ResultErr<T>? err() => this;

  @override
  IResult<U> map<U>(U Function(T value) f) {
    return ResultErr<U>._(exception);
  }

  @override
  Future<IResult<U>> mapAsync<U>(FutureOr<U> Function(T value) f) async {
    return ResultErr<U>._(exception);
  }

  @override
  Future<IResult<T>> mapErrAsync(
      FutureOr<IException> Function(ResultErr<T> error) f) async {
    return ResultErr<T>._(await f(this));
  }

  @override
  IResult<T> mapErr(IException Function(ResultErr<T> error) f) {
    return ResultErr<T>._(f(this));
  }

  @override
  IResult<U> andThen<U>(IResult<U> Function(T value) f) {
    return ResultErr<U>._(exception);
  }

  @override
  Future<IResult<U>> andThenAsync<U>(FutureOr<IResult<U>> Function(T value) f) async {
    return ResultErr<U>._(exception);
  }

  @override
  R fold<R extends Object?>({
    R Function(T value)? onOk,
    R Function(ResultErr<T> error)? onErr,
  }) {
    if (onErr == null) {
      if (null is R) return null as R;
      throw AppInternalError.internalError("ResultErr fold.");
    }
    return onErr(this);
  }

  @override
  Future<R> foldAsync<R extends Object?>({
    FutureOr<R> Function(T value)? onOk,
    FutureOr<R> Function(ResultErr<T> error)? onErr,
  }) async {
    if (onErr == null) {
      if (null is R) return null as R;
      throw AppInternalError.internalError("ResultErr fold.");
    }
    return await onErr(this);
  }

  @override
  R foldOne<R extends Object?>(R Function(T? value, IException? error) f) {
    return f(null, exception);
  }

  @override
  Future<R> foldOneAsync<R extends Object?>(
      FutureOr<R> Function(T? value, IException? error) f) async {
    return await f(null, exception);
  }

  @override
  IResult<U> and<U>(IResult<U> Function(T? value, IException? error) f) {
    return f(null, exception);
  }

  @override
  Future<IResult<U>> andAsync<U>(
      FutureOr<IResult<U>> Function(T? value, ResultErr<T> error) f) async {
    return await f(null, this);
  }

  @override
  String toString() => 'ResultErr(${exception.toDebugMessage()})';

  String get localizationError {
    if (localizedMessage) {
      return exception.message;
    }
    return exception.message.find;
  }

  @override
  IResult<U> cast<U>() {
    return ResultErr<U>.fromException(exception);
  }

  @override
  ResultErr<T> error() {
    return this;
  }

  @override
  bool isError(IException exception) => this.exception == exception;

  ERR? tryAs<ERR extends IException>() {
    if (exception is ERR) {
      return exception as ERR;
    }
    if (exception case AppInternalError(:var interalError) when interalError is ERR) {
      return interalError;
    }
    return null;
  }

  @override
  Future<IResult<U>> andThenCatchAsync<U>(FutureOr<IResult<U>> Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error}) async {
    return ResultErr<U>._(exception);
  }

  @override
  IResult<U> andThenCatch<U>(IResult<U> Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error}) {
    return ResultErr<U>._(exception);
  }

  @override
  Future<IResult<U>> mapCatchAsync<U>(FutureOr<U> Function(T value) f) async {
    return ResultErr<U>._(exception);
  }

  @override
  IResult<U> mapCatch<U>(U Function(T value) f,
      {ONERROR? logging, LoggerMode loggingMode = LoggerMode.error}) {
    return ResultErr<U>._(exception);
  }

  @override
  IResult<T?> unwrapOrNull() {
    return ResultOk<T?>(null);
  }

  @override
  void watch<R extends Object?>(
      {void Function(T value)? onOk, void Function(ResultErr<T> error)? onErr}) {
    if (onErr != null) onErr(this);
  }

  @override
  Future<IResult<R>> thenAsync<R extends Object?>(
      {required FutureOr<IResult<R>> Function(T value) onOk,
      FutureOr<IResult<R>> Function(ResultErr<T> error)? onErr}) async {
    if (onErr == null) {
      return cast<R>();
    }
    return onErr(this);
  }

  void logError({
    LoggerMode mode = LoggerMode.error,
    Object? runtime,
    String? function,
    String? msg,
  }) {
    Logging.logData(
      mode: mode,
      fn: () =>
          AppLogData(runtime: runtime, function: function, msg: msg, err: exception),
    );
  }

  @override
  Future<ResultErr<T>> onComplete(
      FutureOr<dynamic> Function(T? value, ResultErr<T>? error) f) async {
    await f(null, this);
    return this;
  }

  ERROR as<ERROR extends IException>() {
    final exception = this.exception;
    if (exception is ERROR) return exception;
    throw AppInternalError.internalError("ResultErr.as",
        details: {"error": exception.runtimeType.toString(), "excpected": "$ERROR"});
  }

  // ERROR? tryAs<ERROR extends IException>() {
  //   final exception = this.exception;
  //   if (exception is ERROR) return exception;
  //   return null;
  // }
}

extension ExtQuickIExceptionResult<T> on Result<T, IException> {
  IResult<T> toResult({IException Function(IException error)? onError}) {
    return fold(
      onOk: (value) => ResultOk(value),
      onErr: (error) => ResultErr<T>._(switch (onError) {
        null => IExceptionUtils.findError(error),
        _ => onError(error)
      }),
    );
  }
}

extension ExtQuickResult<T, E> on Result<T, E> {
  IResult<T> transformError(IException Function(E error) onError) {
    return fold(
      onOk: (value) => ResultOk(value),
      onErr: (error) => ResultErr<T>._(onError(error)),
    );
  }
}
