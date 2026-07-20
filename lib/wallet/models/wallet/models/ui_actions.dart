import 'dart:async';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

typedef CbUiActionRequest = Future<IResult<T>> Function<T>(WalletUiAction<T>);

abstract class WalletUiAction<T extends Object?> {
  Future<IResult<T>> getResponse();
}

enum WalletUiActionChainRequestTypes { login }

sealed class WalletUiActionChainRequest<T extends Object?> implements WalletUiAction<T> {
  final Duration timeout;
  final Chain chain;
  final Completer<IResult<T>> _completer = Completer();
  final WalletUiActionChainRequestTypes type;
  WalletUiActionChainRequest(
      {required this.type,
      required this.chain,
      this.timeout = const Duration(minutes: 5)});

  @override
  Future<IResult<T>> getResponse() async {
    Future<IResult<T>> futute = _completer.future.timeout(
      timeout,
      onTimeout: () {
        return ResultErr<T>.fromException(AppExceptionConst.loginTimeout);
      },
    );

    return await futute;
  }

  void complete(T result) {
    if (_completer.isCompleted) return;
    _completer.complete(ResultOk(result));
  }

  void error(IException exception) {
    if (_completer.isCompleted) return;
    _completer.complete(ResultErr.fromException(exception));
  }
}

class WalletUiActionChainRequestLogin extends WalletUiActionChainRequest<bool> {
  WalletUiActionChainRequestLogin({required super.chain})
      : super(type: WalletUiActionChainRequestTypes.login);
}
