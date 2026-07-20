import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/web.dart';

import '../base.dart';
import 'ethereum.dart';
import 'wallet_standard.dart';

class JSTronConst {
  static const String defaultTronWebEndpoint = 'https://api.shasta.trongrid.io';
  static final JSArray<JSString> defaultAccountFeatures =
      ["tron:signMessage".toJS, "tron:signTransaction".toJS].toJS;
}

@JS("tron")
external set tron(Proxy<TIP1193>? tron);
@JS("tronWeb")
external set tronWeb_(Proxy<TronWeb>? tronWeb);
@JS("tronLink")
external set tronLink(Proxy<TIP1193>? tronLink);

@JS()
extension type TronLinkParams(JSAny _) implements JSAny {
  external set dappIcon(String _);
  external set dappName(String _);
  external set openUrlWhenWalletNotFound(bool _);
  external set openTronLinkAppOnMobile(bool _);
}
extension type TronWebOptions._(JSAny _) implements JSAny {
  external factory TronWebOptions(
      {String? fullNode, String? solidityNode, String? privateKey});
}

@JS("TronWeb")
extension type TronWeb._(JSAny _) implements JSAny {
  external factory TronWeb(String? solidityNode, String? eventServer, String? privateKey);
  static TronWeb defaultTronWeb() {
    final tronWeb = TronWeb(JSTronConst.defaultTronWebEndpoint,
        JSTronConst.defaultTronWebEndpoint, JSTronConst.defaultTronWebEndpoint);
    return tronWeb;
  }

  external bool isAddress(JSAny _);
  @JS("trx")
  external TronWebTRX get trx;
  @JS("trx")
  external set trx_(Proxy<TronWebTRX> trx);

  external set setSolidityNode(JSFunction setAddress);
  external set setFullNode(JSFunction setPrivateKey);
  external set setAddress(JSFunction setAddress);
  external set setPrivateKey(JSFunction setPrivateKey);
  external set defaultPrivateKey(String s);
  external set solidityNode(HttpProvider? solidityNode);
  external set fullNode(HttpProvider? fullNode);
  external void setEventServer(HttpProvider? fullNode);
  external set setHeader(JSFunction setHeader);
  external set setFullNodeHeader(JSAny? setFullNodeHeader);
  external set setDefaultBlock(JSAny? fullNodsetDefaultBlocke);

  external HttpProvider get solidityNode;
  external HttpProvider get fullNode;
  external Proxy<JSTronAddress> get defaultAddress;
  external set defaultAddress(Proxy<JSTronAddress> defaultAddress);
}

@JS("TronWeb.providers.HttpProvider")
extension type HttpProvider._(JSAny _) implements JSAny {
  external factory HttpProvider(String host);
  external String get host;
  external String get statusPage;
  external set statusPage(String _);
}

@JS("TronWeb.types.DefaultAddress")
extension type JSTronAddress._(JSAny _) implements JSAny {
  external factory JSTronAddress({required JSAny base58, required JSAny hex});
  @JS("base58")
  external set base58(JSAny _);
  external JSAny get base58;
  external JSAny get hex;
  @JS("hex")
  external set hex(JSAny _);

  void setAddress(JSSTronWalletAccount? address) {
    base58 = address?.address.toJS ?? false.toJS;
    hex = address?.hex.toJS ?? false.toJS;
  }
}

@JS("TIP-1193")
extension type TIP1193(JSObject _) implements EIP1193 {
  @JS("tronWeb")
  external set tronWeb(Proxy tronWeb);
  @JS("ready")
  external set ready(bool ready);
  external set config(TronLinkParams _);
  external set disconnect(JSFunction _);
  static TIP1193 setup(
      {required JSFunction request,
      required JSFunction on,
      required JSFunction removeListener,
      required JSFunction disconnect,
      required Proxy tronWeb,
      required JSFunction enable,
      required TronLinkParams params}) {
    final tip = TIP1193(JSObject());
    tip.config = params;
    tip.request = request;
    tip.on = on;
    tip.removeListener = removeListener;
    tip.tronWeb = tronWeb;
    tip.enable = enable;
    tip.connect = enable;
    tip.ready = true;
    tip.disconnect = disconnect;
    final eth = JSOBJ.freeze(tip);
    return eth;
  }
}

@JS()
extension type TronWebTRX(JSObject _) implements JSOBJ {
  @JS("sign")
  external set signTx(JSFunction f);

  @JS("multiSign")
  external set multiSignTransaction(JSFunction f);

  @JS("signMessageV2")
  external set signMsg(JSFunction f);
}

@JS()
extension type JSTronTIPChainChanged._(JSObject o) implements JSAny {
  external String get chain;
  external String get chainId;
  external String get netVersion;
  external String get solidityNode;
  external String get fullNode;
  external String get eventServer;
  external factory JSTronTIPChainChanged(
      {required String chainId,
      required String netVersion,
      required String solidityNode,
      required String fullNode,
      required String eventServer,
      required String chain});
}

extension type JSSTronWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSSTronWalletAccount.setup(
      {required String address,
      required List<int>? publicKey,
      required String chain,
      required String hex}) {
    return JSSTronWalletAccount._(JSObject())
      ..address = address
      ..publicKey = publicKey == null ? null : APPJSUint8Array.fromList(publicKey)
      ..chains = [chain.toJS].toJS
      ..features = JSTronConst.defaultAccountFeatures
      ..hex = hex;
  }
  external String get hex;
  external set hex(String _);
}

@JS()
extension type TronWalletAdapterSignTransactionFeature(JSAny _) implements JSAny {
  factory TronWalletAdapterSignTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return TronWalletAdapterSignTransactionFeature(JSObject())
      ..signTransaction = signAndSendTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}

@JS()
extension type TronWalletAdapterSignMessageFeature(JSAny _) implements JSAny {
  factory TronWalletAdapterSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return TronWalletAdapterSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type TronWalletAdapterConnectFeature(JSAny _) implements JSAny {
  factory TronWalletAdapterConnectFeature.setup(
      {required JSFunction connect,
      String version = JSWalletStandardConst.defaultVersion}) {
    return TronWalletAdapterConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
@JS()
extension type JSTronWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSTronWalletStandardConnect.setup(List<JSSTronWalletAccount> accounts) {
    return JSTronWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSSTronWalletAccount> get accounts;
  external set accounts(JSArray<JSSTronWalletAccount> _);
}
@JS()
extension type JSTronSignMessageParams._(JSObject o) implements JSAny {
  external JSSTronWalletAccount? get account;
  external APPJSUint8Array? get message;
  static const List<String> peroperties = ['account', 'message'];
}
@JS()
extension type JSTronSignatureResponse._(JSObject o) implements JSAny {
  factory JSTronSignatureResponse.setup(List<int> signature) {
    return JSTronSignatureResponse._(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
@JS()
extension type JSTronWalletStandardTransactionParams._(JSObject o) implements JSAny {
  external JSSTronWalletAccount get account;
  external APPJSUint8Array get transaction;
  static const List<String> properties = ['account', 'transaction'];
}
@JS()
extension type JSTronWalletStandardTransactionResponse._(JSObject o) implements JSAny {
  factory JSTronWalletStandardTransactionResponse.setup(List<int> signedTransaction) {
    return JSTronWalletStandardTransactionResponse._(JSObject())
      ..signedTransaction = APPJSUint8Array.fromList(signedTransaction);
  }
  external APPJSUint8Array get signedTransaction;
  external set signedTransaction(APPJSUint8Array _);
}
