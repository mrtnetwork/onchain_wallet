import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils.dart';
import '../../models.dart';
import 'wallet_standard.dart';

class StellarJSConst {
  static final JSArray<JSString> solanaDefaultAccountFeatures = [
    "stellar:signTransaction".toJS,
    "stellar:signAndSendTransaction".toJS,
    "stellar:signMessage".toJS,
  ].toJS;

  static const String sendTransaction = "stellar_sendTransaction";
  static const String signTransaction = "stellar_signTransaction";
  static const String requestAccounts = "stellar_requestAccounts";
  static const String signMessage = "stellar_signMessage";
}

extension type JSStellarWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSStellarWalletAccount.setup(
      {required String address, required List<int> publicKey, required String chain}) {
    return JSStellarWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features = StellarJSConst.solanaDefaultAccountFeatures.freez
      ..publicKey = APPJSUint8Array.fromList(publicKey);
  }
}

extension type JSStellarWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSStellarWalletStandardConnect.setup(List<JSStellarWalletAccount> accounts) {
    return JSStellarWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSStellarWalletAccount> get accounts;
  external set accounts(JSArray<JSStellarWalletAccount> _);
}
extension type JSStellarWalletConnectResponse._(JSObject _) implements JSAny {
  factory JSStellarWalletConnectResponse.setup(List<JSStellarWalletAccount> accounts) {
    return JSStellarWalletConnectResponse._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSStellarWalletAccount> get accounts;
  external set accounts(JSArray<JSStellarWalletAccount> _);
}
@JS()
extension type StellarWalletAdapterStellarSignAndSendTransactionFeature(JSAny _)
    implements JSAny {
  factory StellarWalletAdapterStellarSignAndSendTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return StellarWalletAdapterStellarSignAndSendTransactionFeature(JSObject())
      ..signAndSendTransaction = signAndSendTransaction
      ..version = version;
  }
  external set version(String version);
  external set signAndSendTransaction(JSFunction _);
}
@JS()
extension type StellarWalletAdapterStellarSignTransactionFeature(JSAny _)
    implements JSAny {
  factory StellarWalletAdapterStellarSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return StellarWalletAdapterStellarSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
@JS()
extension type StellarWalletAdapterStellarSignMessageFeature(JSAny _) implements JSAny {
  factory StellarWalletAdapterStellarSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return StellarWalletAdapterStellarSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type JSStellarWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSStellarWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSStellarWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}

extension type JSStellarSendOrSignTransactionParams(JSAny _) implements JSAny {
  external String get transaction;
  external JSStellarWalletAccount? account;
  static const List<String> properties = ['account', 'transaction'];
}
extension type JSStellarSignTransactionResponse(JSAny _) implements JSAny {
  factory JSStellarSignTransactionResponse.setup(String envlope) {
    return JSStellarSignTransactionResponse(JSObject())..envlope = envlope;
  }
  external String get envlope;
  external set envlope(String _);
}
extension type JSStellarSendTransactionResponse(JSAny _) implements JSAny {
  factory JSStellarSendTransactionResponse.setup(
      {required String envlope, required String txId}) {
    return JSStellarSendTransactionResponse(JSObject())
      ..envlope = envlope
      ..txId = txId;
  }
  external String get envlope;
  external set envlope(String _);
  external String get txId;
  external set txId(String _);
}
@JS()
extension type JSStellarSignMessageResponse(JSAny _) implements JSAny {
  factory JSStellarSignMessageResponse.setup(List<int> signature) {
    return JSStellarSignMessageResponse(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
@JS()
extension type JSStellarSignMessageParams._(JSObject _) implements JSAny {
  external JSStellarWalletAccount? account;
  external APPJSUint8Array get message;
  static const List<String> properties = ['message'];
}
@JS()
extension type JSADAWalletStandardSignTransactionParams(JSAny _) implements JSAny {
  external APPJSUint8Array get transaction;
  external JSStellarWalletAccount? account;
}
@JS()
extension type JSADASignTransactionResponse(JSAny _) implements JSAny {
  factory JSADASignTransactionResponse.setup(List<List<int>> witnesses) {
    return JSADASignTransactionResponse(JSObject())
      ..witness = witnesses.map((e) => APPJSUint8Array.fromList(e)).toList().toJS;
  }
  external JSArray<APPJSUint8Array> get witnesses;
  external set witness(JSArray<APPJSUint8Array> _);
}
@JS()
extension type JSStellarSignTransactionParams._(JSObject _) implements JSAny {
  external JSStellarWalletAccount? account;
  external APPJSUint8Array get transaction;
  external JSBoolean? get partialSign;
  static const List<String> properties = ['transaction'];
}
