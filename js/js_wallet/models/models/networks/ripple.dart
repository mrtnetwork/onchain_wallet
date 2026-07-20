import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils/extensions.dart';
import 'solana.dart';
import 'wallet_standard.dart';

class RippleJSConst {
  static const String sendTransaction = "xrpl_signAndSendTransaction";
  static const String signMessage = "xrpl_signMessage";
  static const String signTransaction = "xrpl_signTransaction";
  static const String requestAccounts = "xrpl_requestAccounts";
  static const String version = '1.0.0';
  static JSArray<JSString> rippleDefaultAccountFeatures({bool allowSignMessage = true}) =>
      [
        "xrpl:signAndSendTransaction".toJS,
        "xrpl:signTransaction".toJS,
        if (allowSignMessage) "xrpl:signMessage".toJS,
      ].toJS;
}

extension type JSRippleWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSRippleWalletAccount.setup(
      {required String address, required List<int>? publicKey, required String chain}) {
    return JSRippleWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features =
          RippleJSConst.rippleDefaultAccountFeatures(allowSignMessage: publicKey != null)
              .freez
      ..publicKey = publicKey == null ? null : APPJSUint8Array.fromList(publicKey);
  }
}
extension type JSRippleWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSRippleWalletStandardConnect.setup(List<JSRippleWalletAccount> accounts) {
    return JSRippleWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSRippleWalletAccount> get accounts;
  external set accounts(JSArray<JSRippleWalletAccount> _);
}
extension type JSRippleWalletConnectResponse._(JSObject _) implements JSAny {
  factory JSRippleWalletConnectResponse.setup(List<JSRippleWalletAccount> accounts) {
    return JSRippleWalletConnectResponse._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSRippleWalletAccount> get accounts;
  external set accounts(JSArray<JSRippleWalletAccount> _);
}
@JS()
extension type RippleWalletAdapterRippleSignAndSendTransactionFeature(JSAny _)
    implements JSAny {
  factory RippleWalletAdapterRippleSignAndSendTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return RippleWalletAdapterRippleSignAndSendTransactionFeature(JSObject())
      ..signAndSendTransaction = signAndSendTransaction
      ..version = version;
  }
  external set version(String version);
  external set signAndSendTransaction(JSFunction _);
}
@JS()
extension type RippleWalletAdapterRippleSignTransactionFeature(JSAny _) implements JSAny {
  factory RippleWalletAdapterRippleSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return RippleWalletAdapterRippleSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
@JS()
extension type RippleWalletAdapterRippleSignMessageFeature(JSAny _) implements JSAny {
  factory RippleWalletAdapterRippleSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return RippleWalletAdapterRippleSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type JSRippleWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSRippleWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSRippleWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
extension type JSRippleTransactionXRPL(JSAny _) implements JSAny {
  @JS("Account")
  external String get account;
  @JS("TransactionType")
  external String get transactionType;
}
extension type JSRippleSendOrSignTransactionParams(JSAny _) implements JSAny {
  external JSRippleTransactionXRPL? get transaction;
  external APPJSUint8Array? get transactionBlob;
  external JSRippleWalletAccount? account;
  static const List<String> properties = ['account', 'transaction'];
}
extension type JSRippleSignTransactionResponse(JSAny _) implements JSAny {
  factory JSRippleSignTransactionResponse.setup(String envlope) {
    return JSRippleSignTransactionResponse(JSObject())..envlope = envlope;
  }
  external String get envlope;
  external set envlope(String _);
}
extension type JSRippleSendTransactionResponse(JSAny _) implements JSAny {
  factory JSRippleSendTransactionResponse.setup(
      {required String envlope, required String txId}) {
    return JSRippleSendTransactionResponse(JSObject())
      ..envlope = envlope
      ..txId = txId;
  }
  external String get envlope;
  external set envlope(String _);
  external String get txId;
  external set txId(String _);
}
@JS()
extension type JSRippleSignMessageResponse(JSAny _) implements JSAny {
  factory JSRippleSignMessageResponse.setup(
      {required List<int> signature, required List<int> publicKey}) {
    return JSRippleSignMessageResponse(JSObject())
      ..signature = APPJSUint8Array.fromList(signature)
      ..publicKey = APPJSUint8Array.fromList(publicKey);
  }
  external APPJSUint8Array get signature;
  external APPJSUint8Array get publicKey;
  external set signature(APPJSUint8Array _);
  external set publicKey(APPJSUint8Array _);
}
@JS()
extension type JSRippleSignMessageParams._(JSObject _) implements JSAny {
  external JSRippleWalletAccount? account;
  external APPJSUint8Array get message;
  static const List<String> properties = ['message'];
}
