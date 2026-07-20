import 'dart:async';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

class WorkerMessageCompleter {
  final int id;
  WorkerMessageCompleter(this.id);
  final Completer<IResult<CborMessageResponseArgs>> _messageCompleter = Completer();

  void complete(CborMessageResponseArgs message) {
    if (_messageCompleter.isCompleted) return;
    switch (message) {
      case MessageArgsException(:final message):
        _messageCompleter.complete(ResultErr.fromException(message));
        break;
      default:
        _messageCompleter.complete(ResultOk(message));
        break;
    }
  }

  void close() {
    if (_messageCompleter.isCompleted) return;
    _messageCompleter.complete(
        ResultErr.fromException(AppCryptoExceptionConst.failedToConnectToCryptoService));
  }

  void cancel() {
    if (_messageCompleter.isCompleted) return;
    _messageCompleter.complete(
        ResultErr.fromException(AppCryptoExceptionConst.cryptoOperationWasCanceled));
  }

  Future<IResult<T>> getResult<T extends CborMessageResponseArgs>(
      Duration timeout) async {
    final completer = _messageCompleter;
    final result = await completer.future.timeout(
      timeout,
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete(ResultErr.fromException(
              AppCryptoExceptionConst.cryptoServiceRequestTimeout));
        }
        return ResultErr.fromException(
            AppCryptoExceptionConst.cryptoServiceRequestTimeout);
      },
    );
    return result.andThen<T>((e) {
      if (e is T) {
        return ResultOk(e);
      }
      return ResultErr.fromException(AppInternalError.internalError(
          "WorkerMessageCompleter.getResult",
          reason: "Invalid response type. ${e.runtimeType}/$T"));
    });
  }
}
