import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils.dart';
import '../../models.dart';
import 'wallet_standard.dart';

class ZcashJSConst {
  static final JSArray<JSString> features = [
    "zcash:signAndSendTransaction".toJS,
    "zcash:signMessage".toJS,
  ].toJS;

  static const String sendTransaction = "zcash_payment";
  static const String signMessage = "zcash_signMessage";
  static const String requestAccounts = "zcash_requestAccounts";
}

extension type JSZcashWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSZcashWalletAccount.setup({required String address, required String chain}) {
    return JSZcashWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features = ZcashJSConst.features.freez;
  }
}

extension type JSZcashWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSZcashWalletStandardConnect.setup(List<JSZcashWalletAccount> accounts) {
    return JSZcashWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSZcashWalletAccount> get accounts;
  external set accounts(JSArray<JSZcashWalletAccount> _);
}
extension type JSZcashWalletConnectResponse._(JSObject _) implements JSAny {
  factory JSZcashWalletConnectResponse.setup(List<JSZcashWalletAccount> accounts) {
    return JSZcashWalletConnectResponse._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSZcashWalletAccount> get accounts;
  external set accounts(JSArray<JSZcashWalletAccount> _);
}
@JS()
extension type ZcashWalletAdapterZcashPaymentFeature(JSAny _) implements JSAny {
  factory ZcashWalletAdapterZcashPaymentFeature.setup(
      {required JSFunction payment,
      String version = JSWalletStandardConst.defaultVersion}) {
    return ZcashWalletAdapterZcashPaymentFeature(JSObject())
      ..payment = payment
      ..version = version;
  }
  external set version(String version);
  external set payment(JSFunction _);
}

@JS()
extension type ZcashWalletAdapterZcashSignMessageFeature(JSAny _) implements JSAny {
  factory ZcashWalletAdapterZcashSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return ZcashWalletAdapterZcashSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type JSZcashWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSZcashWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSZcashWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
extension type JSZcashSendOrSignTransactionRecipients(JSAny _) implements JSAny {
  external String get amount;
  external String get address;
  external String? get protocol;
  external String? get memo;
  static const List<String> properties = ['address', 'amount'];
}

extension type JSZcashSendOrSignTransactionParams(JSAny _) implements JSAny {
  external JSArray<JSZcashSendOrSignTransactionRecipients> get recipients;
  external JSZcashWalletAccount? account;
  external JSArray<JSZcashWalletAccount>? accounts;
  external JSArray<JSString>? get memos;
  external String? get privacy;
  static const List<String> properties = ['transaction'];
}

extension type JSZcashSendTransactionResponse(JSAny _) implements JSAny {
  factory JSZcashSendTransactionResponse.setup({required String txId}) {
    return JSZcashSendTransactionResponse(JSObject())..txId = txId;
  }
  external String get txId;
  external set txId(String _);
}

@JS()
extension type JSZcashSignMessageResponse(JSAny _) implements JSAny {
  factory JSZcashSignMessageResponse.setup(List<int> signature) {
    return JSZcashSignMessageResponse(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
@JS()
extension type JSZcashSignMessageParams._(JSObject _) implements JSAny {
  external JSZcashWalletAccount? account;
  external APPJSUint8Array get message;
  static const List<String> properties = ['message'];
}
