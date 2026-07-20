import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils.dart';
import '../../models.dart';
import 'wallet_standard.dart';

class TonJSConst {
  static const String sendTransaction = "ton_sendTransaction";
  static const String signTransaction = "ton_signTransaction";
  static const String requestAccounts = "ton_requestAccounts";
  static const String signMessage = "ton_signMessage";
  static final JSArray<JSString> defaultAccountFeatures = [
    "ton:signTransaction".toJS,
    "ton:signAndSendTransaction".toJS,
    "ton:signMessage".toJS,
  ].toJS;
}

@JS()
extension type JSTonSendOrSignTransactionMessageParams._(JSObject _) implements JSAny {
  external String? get address;
  external String? get amount;
  external String? stateInit;
  external String? payload;
  static const List<String> properties = ['address', 'amount'];
}
@JS()
extension type JSTonSendOrSignTransactionParams._(JSObject _) implements JSAny {
  external JSTonWalletAccount account;
  external int get validUntil;
  external JSArray<JSTonSendOrSignTransactionMessageParams> get messages;
  static const List<String> properties = ['account', 'validUntil', 'messages'];
}
@JS()
extension type JSTonSignMessageParams._(JSObject _) implements JSAny {
  external JSTonWalletAccount? account;
  external APPJSUint8Array get message;
  static const List<String> properties = ['message'];
}

@JS()
extension type JSTonWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSTonWalletAccount.setup(
      {required String address,
      required List<int> publicKey,
      required List<int> walletStateInit,
      required String chain}) {
    return JSTonWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features = TonJSConst.defaultAccountFeatures.freez
      ..publicKey = APPJSUint8Array.fromList(publicKey)
      ..walletStateInit = APPJSUint8Array.fromList(walletStateInit);
  }
  external set walletStateInit(APPJSUint8Array _);
}
@JS()
extension type JSTonWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSTonWalletStandardConnect.setup(List<JSTonWalletAccount> accounts) {
    return JSTonWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSTonWalletAccount> get accounts;
  external set accounts(JSArray<JSTonWalletAccount> _);
}

@JS()
extension type TonWalletAdapterTonSignAndSendTransactionFeature(JSAny _)
    implements JSAny {
  factory TonWalletAdapterTonSignAndSendTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return TonWalletAdapterTonSignAndSendTransactionFeature(JSObject())
      ..signAndSendTransaction = signAndSendTransaction
      ..version = version;
  }
  external set version(String version);
  external set signAndSendTransaction(JSFunction _);
}

@JS()
extension type TonWalletAdapterTonSignTransactionFeature(JSAny _) implements JSAny {
  factory TonWalletAdapterTonSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return TonWalletAdapterTonSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
@JS()
extension type TonWalletAdapterTonSignMessageFeature(JSAny _) implements JSAny {
  factory TonWalletAdapterTonSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return TonWalletAdapterTonSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type JSTonWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSTonWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSTonWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}

@JS()
extension type JSTonSendTransactionResponse(JSAny _) implements JSAny {
  factory JSTonSendTransactionResponse.setup(
      {required String boc, required String txId}) {
    return JSTonSendTransactionResponse(JSObject())
      ..boc = boc
      ..txId = txId;
  }
  external String get boc;
  external set boc(String _);
  external String get txId;
  external set txId(String _);
}
@JS()
extension type JSTonSignTransactionResponse(JSAny _) implements JSAny {
  factory JSTonSignTransactionResponse.setup(String externalMessage) {
    return JSTonSignTransactionResponse(JSObject())..externalMessage = externalMessage;
  }
  external String get externalMessage;
  external set externalMessage(String _);
}
@JS()
extension type JSTonSignMessageResponse(JSAny _) implements JSAny {
  factory JSTonSignMessageResponse.setup(List<int> signature) {
    return JSTonSignMessageResponse(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
