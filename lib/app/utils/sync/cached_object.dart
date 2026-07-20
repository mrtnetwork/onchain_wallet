import 'dart:async';

import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/app/error/exception/wallet_ex.dart';
import 'package:on_chain_wallet/app/stream/live.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/app/utils/method/utiils.dart';
import 'package:on_chain_wallet/app/utils/sync/fetch_object.dart';

typedef ONFETCHCACHEDOBJECT<T extends Object?> = Future<T> Function();
typedef ONFETCHCACHEDOBJECTRESULT<T extends Object?> = Future<IResult<T>> Function();
typedef ONFETCHEDCACHEDOBJECT<T extends Object?> = T Function();
typedef ONFETCHEDCACHEDOBJECTRESULT<T extends Object?> = IResult<T> Function();

class CachedObject<T extends Object?> with Equality {
  final _lock = SafeAtomicLock();
  final Duration interval;
  T? _value;
  T? get value => _value;
  DateTime? _update;
  CachedObject({this.interval = const Duration(minutes: 10)});

  bool _shouldFetch({Duration? interval}) {
    interval ??= this.interval;
    final update = _update;
    if (update == null) return true;
    final expire = update.add(interval);
    if (expire.isBefore(DateTime.now())) {
      return true;
    }
    return false;
  }

  Future<T> get({required ONFETCHCACHEDOBJECT<T> onFetch, Duration? cachedTimeout}) {
    return _lock.run(() async {
      final fetch = _shouldFetch(interval: cachedTimeout);
      if (!fetch) return _value as T;
      _value = null;
      _value = await onFetch();
      _update = DateTime.now();
      return _value as T;
    });
  }

  @override
  List get variables => [interval, value];
}

class OnceRunner<T extends Object?> {
  final SafeAtomicLock _lock = SafeAtomicLock();
  bool _isReady = false;
  DateTime? _lastestUpdate;
  OnceRunner();

  Future<T> get(
      {required ONFETCHCACHEDOBJECT<T> onFetch,
      required ONFETCHEDCACHEDOBJECT<T> onFetched,
      Duration? cachedTimeout}) async {
    if (_isReady) {
      if (cachedTimeout == null) return onFetched();
      final latestUpdate = _lastestUpdate;
      if (latestUpdate == null) return onFetched();
      final expire = latestUpdate.add(cachedTimeout);
      if (expire.isBefore(DateTime.now())) {
        _isReady = false;
      }
    }
    return await _lock.run(() async {
      final fetch = _isReady;
      if (fetch) return onFetched();
      final result = await onFetch();
      _isReady = true;
      _lastestUpdate = DateTime.now();
      return result;
    });
  }

  void reset() => _isReady = false;
}

class OnceRunnerResult<T extends Object?> {
  final SafeAtomicLock _lock = SafeAtomicLock();
  bool _isReady = false;
  DateTime? _lastestUpdate;
  OnceRunnerResult();

  bool get isReady => _isReady;

  Future<IResult<T>> get(
      {required ONFETCHCACHEDOBJECTRESULT<T> onFetch,
      required ONFETCHEDCACHEDOBJECTRESULT<T> onFetched,
      Duration? cachedTimeout,
      bool readyOnError = false}) async {
    if (_isReady) {
      if (cachedTimeout == null) return onFetched();
      final latestUpdate = _lastestUpdate;
      if (latestUpdate == null) return onFetched();
      final expire = latestUpdate.add(cachedTimeout);
      if (expire.isBefore(DateTime.now())) {
        _isReady = false;
      }
    }
    return await _lock.run(() async {
      final fetch = _isReady;
      if (fetch) return onFetched();
      final result = await onFetch();
      return result.map((e) {
        _isReady = true;
        _lastestUpdate = DateTime.now();
        return e;
      }).mapErr((e) {
        if (readyOnError) {
          _isReady = true;
          _lastestUpdate = DateTime.now();
        }
        return e.exception;
      });
    });
  }

  void reset() => _isReady = false;
}

class PeriodicRunner<T extends Object?> with DisposableMixin, StreamStateController {
  final Duration periodic;
  final Cancelable _cancelable = Cancelable();
  late final StreamSubscription<dynamic> _prediocStream;
  PeriodicRunner(
      {required this.onFetch,
      required this.periodic,
      FetchObjectStatus status = FetchObjectStatus.idle})
      : _status = status {
    _prediocStream = Stream.periodic(periodic).listen(_periodic);
  }

  final ONFETCHCACHEDOBJECT<T> onFetch;
  final _lock = SafeAtomicLock();
  T? _value;
  T get value => _value!;

  bool get hasValue => status.isSuccess;
  FetchObjectStatus _status;
  FetchObjectStatus get status => _status;
  IException? _error;
  String? _errorMessage;
  IException? get error => _error;
  String? get errorMessage => _errorMessage;
  Future<void> _periodic(void _) {
    assert(!closed, "stream already closed");
    return _lock.run(() async {
      _status = FetchObjectStatus.pending;
      _error = null;
      _errorMessage = null;
      notify();
      final result = await IResult.call(() async {
        return await onFetch();
      }, cancelable: _cancelable);
      if (result.err()?.canceled() ?? false) return;
      result.fold(
        onErr: (error) {
          _error = error.exception;
          _errorMessage = error.localizationError;
          _status = FetchObjectStatus.failed;
        },
        onOk: (value) {
          _value = value;
          _status = FetchObjectStatus.success;
        },
      );
      notify();
    });
  }

  Future<T> get({bool silent = true}) {
    return _lock.run(() async {
      if (_status.isSuccess) return _value as T;
      _status = FetchObjectStatus.pending;
      final result = await IResult.call<T>(() async {
        return onFetch();
      });
      try {
        return result.fold<T>(
          onErr: (error) {
            _error = error.exception;
            _errorMessage = result.unwrapErr().localizationError;
            _status = FetchObjectStatus.failed;
            return error.unwrap();
          },
          onOk: (value) {
            _value = value;
            _status = FetchObjectStatus.success;
            return value;
          },
        );
      } finally {
        if (!silent) notify();
      }
    });
  }

  void update() {
    _periodic(null);
  }

  @override
  void dispose() {
    _cancelable.cancel();
    _prediocStream.cancel();
    _value = null;
    super.dispose();
  }
}

class OnceRunnerWithData<T extends Object?> {
  final SafeAtomicLock _lock = SafeAtomicLock();
  bool _isReady = false;
  bool _dispose = false;
  OnceRunnerWithData();

  bool get isReady => _isReady;

  IResult<T>? _result;
  T? _data;
  IException? _error;

  Future<IResult<T>> get({
    required ONFETCHCACHEDOBJECTRESULT<T> onFetch,
  }) async {
    return await _lock.run(() async {
      if (_dispose) {
        return ResultErr.fromException(AppExceptionConst.requestCanceled);
      }
      final fetch = _isReady;
      {
        final data = _result;
        if (fetch && data != null) return data;
      }
      final result = _result = await IResult.block(() async => await onFetch());
      result.watch(
          onErr: (error) => _error = error.exception, onOk: (value) => _data = value);
      _isReady = true;
      return result;
    });
  }

  void _clearState() {
    _isReady = false;
    _data = null;
    _error = null;
  }

  Future<void> clear() async {
    await _lock.run(() async {
      _clearState();
    });
  }

  Future<void> dispose() async {
    await _lock.run(() async {
      _clearState();
      _dispose = true;
    });
  }

  bool get isErr => isReady && _error != null;
  T? get data => _data;

  T getDataOr(T Function() fn) {
    final data = _data;
    assert(isReady && !isErr, isErr ? "context has error." : "context not initialized.");
    if (isReady && !isErr) {
      return data as T;
    }
    return fn();
  }

  void setOk(T data) {
    _error = null;
    _result = ResultOk<T>(data);
    _data = data;
    _isReady = true;
  }

  void setErr(IException exception) {
    _data = null;
    _error = exception;
    _result = ResultErr.fromException(exception);
    _isReady = true;
  }
}
