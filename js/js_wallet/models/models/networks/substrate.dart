import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils/extensions.dart';
import '../../models.dart';
import 'wallet_standard.dart';

@JS("substrate")
external set substrate(Proxy? substrate);
@JS("injectedWeb3")
external JSInjectedWeb3 get injectedWeb3;
@JS("injectedWeb3")
external JSInjectedWeb3? get injectedWeb3Nullable;
@JS("injectedWeb3")
external set injectedWeb3(JSInjectedWeb3 _);

class SubstrateJSConst {
  static final JSArray<JSString> defaultAccountFeatures = [
    "substrate:signTransaction".toJS,
    "substrate:signMessage".toJS,
  ].toJS;
}

@JS()
extension type JSPolkadotJSWalletAdapter(JSAny _) implements JSWalletAdapter {
  external set signer(Proxy<JSSubstrateWalletAdapterSigner> _);
  external set metadata(Proxy<JSSubstrateWalletAdapterMetadata> _);
  external set accounts(Proxy<JSSubstrateWalletAdapterAccounts> _);
  external set connect(JSFunction f);
  external set enable(JSFunction f);
}

extension type JSSubstrateWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSSubstrateWalletAccount.setup(
      {required String address,
      required String genesisHash,
      required List<int> publicKey,
      required String chain}) {
    return JSSubstrateWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..genesisHash = genesisHash
      ..features = SubstrateJSConst.defaultAccountFeatures.freez
      ..publicKey = APPJSUint8Array.fromList(publicKey);
  }
  external set genesisHash(String? _);
  external String? get genesisHash;
}
@JS()
extension type JSSubstrateWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSSubstrateWalletStandardConnect.setup(
      List<JSSubstrateWalletAccount> accounts) {
    return JSSubstrateWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSSubstrateWalletAccount> get accounts;
  external set accounts(JSArray<JSSubstrateWalletAccount> _);
}

@JS()
extension type SubstrateWalletAdapterSubstrateSignTransactionFeature(JSAny _)
    implements JSAny {
  factory SubstrateWalletAdapterSubstrateSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return SubstrateWalletAdapterSubstrateSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
@JS()
extension type SubstrateWalletAdapterSubstrateAddNewChainFeature(JSAny _)
    implements JSAny {
  factory SubstrateWalletAdapterSubstrateAddNewChainFeature.setup(
      {required JSFunction addNewChain,
      String version = JSWalletStandardConst.defaultVersion}) {
    return SubstrateWalletAdapterSubstrateAddNewChainFeature(JSObject())
      ..addNewChain = addNewChain
      ..version = version;
  }
  external set version(String version);
  external set addNewChain(JSFunction _);
}

@JS()
extension type SubstrateWalletAdapterSubstrateSignMessageFeature(JSAny _)
    implements JSAny {
  factory SubstrateWalletAdapterSubstrateSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return SubstrateWalletAdapterSubstrateSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}

extension type JSSubstrateWalletAdapterMetadata(JSObject _) implements JSAny {
  external set get(JSFunction _);
  external set provide(JSFunction _);
}
extension type JSSubstrateWalletAdapterAccounts(JSObject _) implements JSAny {
  @JS("get")
  external set get(JSFunction _);
  @JS("subscribe")
  external set subscribe(JSFunction _);
}

@JS("injectedWeb3")
extension type JSInjectedWeb3(JSObject _) implements JSAny {
  @JS("onChain/1")
  external set onChain(Proxy? _);
}
extension type JSSubstrateWalletAdapterSigner(JSObject _) implements JSAny {
  @JS("signPayload")
  external set signPayload(JSFunction _);
  @JS("signRaw")
  external set signRaw(JSFunction _);
  @JS("update")
  external set update(JSFunction _);
}
@JS()
extension type JSSubstrateTransaction._(JSObject _) implements JSAny {
  external factory JSSubstrateTransaction(
      {required String address,
      required String? assetId,
      required String blockHash,
      required String blockNumber,
      required String era,
      required String genesisHash,
      required String? metadataHash,
      required String method,
      required int? mode,
      required String nonce,
      required String specVersion,
      required String tip,
      required String transactionVersion,
      required JSArray<JSString> signedExtensions,
      required int version,
      required bool? withSignedTransaction});
  JSSubstrateTransaction clone() {
    return JSSubstrateTransaction(
        address: address,
        assetId: assetId,
        blockHash: blockHash,
        blockNumber: blockNumber,
        era: era,
        genesisHash: genesisHash,
        metadataHash: metadataHash,
        method: method,
        mode: mode,
        nonce: nonce,
        specVersion: specVersion,
        tip: tip,
        transactionVersion: transactionVersion,
        signedExtensions: signedExtensions,
        version: version,
        withSignedTransaction: withSignedTransaction);
  }

  external String get address;
  external String? get assetId;
  external String get blockHash;
  external String get blockNumber;
  external String get era;
  external String get genesisHash;
  external String? get metadataHash;
  external String get method;
  external int? get mode;
  external String get nonce;
  external String get specVersion;
  external String get tip;
  external String get transactionVersion;
  external JSArray<JSString> get signedExtensions;
  external int version;
  external bool? withSignedTransaction;
  static List<String> properties = [
    "address",
    "blockHash",
    "blockNumber",
    "era",
    "genesisHash",
    "method",
    "nonce",
    "specVersion",
    "tip",
    "transactionVersion",
    "signedExtensions",
    "version"
  ];
  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "assetId": assetId,
      "blockHash": blockHash,
      "blockNumber": blockNumber,
      "era": era,
      "genesisHash": genesisHash,
      "metadataHash": metadataHash,
      "method": method,
      "mode": mode,
      "nonce": nonce,
      "specVersion": specVersion,
      "transactionVersion": transactionVersion,
      "tip": tip,
      "signedExtensions": signedExtensions.toDart.map((e) => e.toDart).toList(),
      "version": version,
      "withSignedTransaction": withSignedTransaction
    };
  }
}
extension type JSSubstrateTxResponse._(JSObject _) implements JSAny {
  external factory JSSubstrateTxResponse(
      {int id, String signature, String? signedTransaction});
}
extension type JSSubstrateSign(JSObject _) implements JSAny {
  external String get address;
  external String? get type;
  external String get data;
  static const List<String> properties = ["address", "data"];
}
@JS()
extension type JSSubstrateMetadataProvide._(JSObject _) implements JSAny {
  external factory JSSubstrateMetadataProvide({
    String chain,
    String genesisHash,
    int ss58Format,
    String? chainType,
    int specVersion,
    int tokenDecimals,
    String tokenSymbol,
    String? rawMetadata,
  });
  JSSubstrateMetadataProvide clone() {
    return JSSubstrateMetadataProvide(
        chain: chain,
        genesisHash: genesisHash,
        ss58Format: ss58Format,
        chainType: chainType,
        specVersion: specVersion,
        tokenDecimals: tokenDecimals,
        tokenSymbol: tokenSymbol,
        rawMetadata: rawMetadata);
  }

  external String get chain;
  external String get genesisHash;
  external int get ss58Format;
  external String? get chainType;
  external int get specVersion;
  external int get tokenDecimals;
  external String get tokenSymbol;
  external String? get rawMetadata;
  static const List<String> properties = [
    "chain",
    "genesisHash",
    "ss58Format",
    "specVersion",
    "tokenDecimals",
    "tokenSymbol"
  ];
  Map<String, dynamic> toJson() {
    return {
      "chain": chain,
      "genesisHash": genesisHash,
      "ss58Format": ss58Format,
      "chainType": chainType,
      "specVersion": specVersion,
      "tokenDecimals": tokenDecimals,
      "tokenSymbol": tokenSymbol,
      "rawMetadata": rawMetadata
    };
  }
}

extension type JSSubstrateKnownMetadata._(JSObject _) implements JSAny {
  external factory JSSubstrateKnownMetadata(
      {String genesisHash, int specVersion, String identifier});
  external String get genesisHash;
  external int get specVersion;
  external String get identifier;
}
@JS()
extension type JSSubstrateWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSSubstrateWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSSubstrateWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
