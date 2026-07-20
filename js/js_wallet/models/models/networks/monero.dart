import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils.dart';
import '../../models.dart';
import 'wallet_standard.dart';

class MoneroJSConst {
  static final JSArray<JSString> solanaDefaultAccountFeatures = [
    "monero:signAndSendTransaction".toJS,
    "monero:signMessage".toJS,
  ].toJS;

  static const String sendTransaction = "monero_signAndSendTransaction";
  static const String signMessage = "monero_signMessage";
  static const String requestAccounts = "monero_requestAccounts";
}

extension type JSMoneroWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSMoneroWalletAccount.setup(
      {required String address, required List<int>? publicKey, required String chain}) {
    return JSMoneroWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features = MoneroJSConst.solanaDefaultAccountFeatures.freez
      ..publicKey = publicKey == null ? null : APPJSUint8Array.fromList(publicKey);
  }
}

extension type JSMoneroWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSMoneroWalletStandardConnect.setup(List<JSMoneroWalletAccount> accounts) {
    return JSMoneroWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSMoneroWalletAccount> get accounts;
  external set accounts(JSArray<JSMoneroWalletAccount> _);
}
extension type JSMoneroWalletConnectResponse._(JSObject _) implements JSAny {
  factory JSMoneroWalletConnectResponse.setup(List<JSMoneroWalletAccount> accounts) {
    return JSMoneroWalletConnectResponse._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSMoneroWalletAccount> get accounts;
  external set accounts(JSArray<JSMoneroWalletAccount> _);
}
@JS()
extension type MoneroWalletAdapterMoneroSignAndSendTransactionFeature(JSAny _)
    implements JSAny {
  factory MoneroWalletAdapterMoneroSignAndSendTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return MoneroWalletAdapterMoneroSignAndSendTransactionFeature(JSObject())
      ..signAndSendTransaction = signAndSendTransaction
      ..version = version;
  }
  external set version(String version);
  external set signAndSendTransaction(JSFunction _);
}

@JS()
extension type MoneroWalletAdapterMoneroSignMessageFeature(JSAny _) implements JSAny {
  factory MoneroWalletAdapterMoneroSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return MoneroWalletAdapterMoneroSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type JSMoneroWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSMoneroWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSMoneroWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
extension type JSMoneroSendOrSignTransactionDestinationParams(JSAny _) implements JSAny {
  external String get amount;
  external String get address;
  static const List<String> properties = ['address', 'amount'];
}

extension type JSMoneroSendOrSignTransactionParams(JSAny _) implements JSAny {
  external JSArray<JSMoneroSendOrSignTransactionDestinationParams> get destinations;
  external JSMoneroWalletAccount? account;
  external JSArray<JSMoneroWalletAccount>? accounts;
  static const List<String> properties = ['transaction'];
}

extension type JSMoneroSendTransactionProofResponse(JSAny _) implements JSAny {
  factory JSMoneroSendTransactionProofResponse.setup(
      {required String address, required String proof}) {
    return JSMoneroSendTransactionProofResponse(JSObject())
      ..address = address
      ..proof = proof;
  }
  external String get address;
  external set address(String _);
  external String get proof;
  external set proof(String _);
}
extension type JSMoneroSendTransactionResponse(JSAny _) implements JSAny {
  factory JSMoneroSendTransactionResponse.setup(
      {required List<JSMoneroSendTransactionProofResponse> proofs,
      required String txId}) {
    return JSMoneroSendTransactionResponse(JSObject())
      ..proofs = proofs.toJS
      ..txId = txId;
  }
  external JSArray<JSMoneroSendTransactionProofResponse> get proofs;
  external set proofs(JSArray<JSMoneroSendTransactionProofResponse> _);
  external String get txId;
  external set txId(String _);
}

@JS()
extension type JSMoneroSignMessageResponse(JSAny _) implements JSAny {
  factory JSMoneroSignMessageResponse.setup(List<int> signature) {
    return JSMoneroSignMessageResponse(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
@JS()
extension type JSMoneroSignMessageParams._(JSObject _) implements JSAny {
  external JSMoneroWalletAccount? account;
  external APPJSUint8Array get message;
  static const List<String> properties = ['message'];
}
