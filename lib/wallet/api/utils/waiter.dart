import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';

typedef CbOnRetryRequest<T extends Object?> = FutureOr<IResult<T>> Function(int count);
// typedef RETRYWHENCALLBACK<T extends Object?> = bool Function(ResultErr<T> error);

class ApiRequestTimingGuard {
  final _lock = SafeAtomicLock();
  final Duration timeout;
  ApiRequestTimingGuard(this.timeout);

  Future<void>? _idle;
  Future<void> wait() async {
    await _lock.run(() async {
      await _idle;
      _idle = Future.delayed(timeout);
    });
  }
}

class SocketRetryConnection {
  final _lock = SafeAtomicLock();
  // final _cancelable = Cancelable();
  final Duration rate;
  final int maxRetry;
  Duration _timeout = Duration.zero;
  int _retry = 0;
  bool _closed = false;
  SocketRetryConnection({this.rate = const Duration(seconds: 1), this.maxRetry = 30});

  Future<IResult<T>> wait<T extends Object?>(
      {required CbOnRetryRequest<T> onTimeout}) async {
    return await _lock.run(() async {
      while (!_closed) {
        final result =
            await IResult.block(() async => await onTimeout(_retry), delay: _timeout);
        if (result.isOk) {
          _retry = 0;
          return result;
        }
        if (_retry < maxRetry) {
          _retry++;
          _timeout += rate;
        }
      }
      return ResultErr.from(AppExceptionConst.requestCanceled);
    });
  }

  void reset() {
    _retry = 0;
    _timeout = Duration.zero;
  }

  void close() {
    _closed = true;
  }
}
