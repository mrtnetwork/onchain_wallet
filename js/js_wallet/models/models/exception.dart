import 'dart:js_interop';

import 'package:on_chain_wallet/web3/web3/core/messages/models/models/exception.dart';

@JS("Error")
extension type JSError._(JSAny _) implements JSAny {
  external factory JSError({String? message});
  external String? get message;
}

extension type JSWalletError._(JSAny _) implements JSError {
  external factory JSWalletError({String? message, int? code, String? walletCode});
  external factory JSWalletError.withData(
      {String? message, int? code, String? walletCode, String? data});

  external factory JSWalletError.cardano({String? info, int? code, String? walletCode});
}

extension ToWalletError on Web3ExceptionMessage {
  JSWalletError toWalletError() {
    if (data != null) {
      return JSWalletError.withData(
          message: message, code: code, walletCode: errorType.walletCode, data: data);
    }
    final error =
        JSWalletError(message: message, code: code, walletCode: errorType.walletCode);
    return error;
  }
}
