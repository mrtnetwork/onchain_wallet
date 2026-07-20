import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../js_wallet.dart';
import 'wallet_standard.dart';

class JSCosmosConst {
  static final JSArray<JSString> defaultAccountFeatures = [
    "cosmos:signMessage".toJS,
    "cosmos:signTransactionAmino".toJS,
    "cosmos:signTransactionDirect".toJS,
  ].toJS;
  static const String signTransactionAmino = "cosmos_signTransactionAmino";
  static const String signTransactionDirect = "cosmos_signTransactionDirect";
  static const String requestAccount = "cosmos_requestAccounts";
  static const String addNewChain = "wallet_addCosmosChain";
  static const String signMessage = "cosmos_signMessage";
  static const String signTransaction = "cosmos_signTransaction";
}

@JS("getOfflineSigner")
external set getOfflineSigner(JSFunction _);
@JS("getOfflineSignerOnlyAmino")
external set getOfflineSignerOnlyAmino(JSFunction _);
@JS("getOfflineSignerAuto")
external set getOfflineSignerAuto(JSFunction _);
@JS("cosmos")
external set cosmos(Proxy<CosmosWalletAdapter>? sui);
@JS()
extension type CosmosWalletAdapter(JSObject _) implements JSAny {
  external static set getKeplr(JSFunction? _);
  external set getOfflineSigner(JSFunction _);
  external set getOfflineSignerOnlyAmino(JSFunction _);
  external set getOfflineSignerAuto(JSFunction _);

  factory CosmosWalletAdapter.setup() {
    return CosmosWalletAdapter(JSObject());
  }
}

extension type JSCosmosWalletAccount(JSObject _) implements JSWalletStandardAccount {
  factory JSCosmosWalletAccount.setup(
      {required String address,
      required String algo,
      required String typeUrl,
      required String chain,
      required List<int> publicKey}) {
    return JSCosmosWalletAccount(JSObject())
      ..address = address
      ..algo = algo
      ..publicKey = APPJSUint8Array.fromList(publicKey)
      ..pubkey = APPJSUint8Array.fromList(publicKey)
      ..chains = [chain.toJS].toJS
      ..features = JSTronConst.defaultAccountFeatures
      ..typeUrl = typeUrl;
  }
  external String get address;
  external String get algo;
  external APPJSUint8Array get pubkey;
  external String get typeUrl;

  external set address(String _);
  external set algo(String _);
  external set pubkey(APPJSUint8Array _);
  external set typeUrl(String _);
}
extension type JSCosmosCoin(JSAny _) implements JSAny {
  external String get denom;
  external String get amount;
}
extension type JSCosmosStdFee(JSAny _) implements JSAny {
  external JSArray<JSCosmosCoin> get amount;
  external String get gas;
  external String? get payer;
  external String? get granter;
  external String? get feePayer;
}
extension type JSCosmosMSG(JSAny _) implements JSAny {
  external String get type;
  external JSAny? get value;
}

extension type JSCosmosStdSignDoc(JSAny _) implements JSAny {
  @JS("chain_id")
  external String get chainId;
  @JS("account_number")
  external String get accountNumber;
  external String get sequence;
  @JS("timeout_height")
  external String get timeoutHeight;
  external JSArray<JSCosmosMSG> get msgs;
  external String get memo;
}
extension type JSCosmosPubKey(JSAny _) implements JSAny {
  external String get type;
  external String get value;
  external set type(String _);
  external set value(String _);
  factory JSCosmosPubKey.setup({required String type, required String value}) {
    return JSCosmosPubKey(JSObject())
      ..type = type
      ..value = value;
  }
}
extension type JSCosmosSignOption(JSAny _) implements JSAny {
  external bool? get preferNoSetFee;
  external bool? get preferNoSetMemo;
  external bool? get disableBalanceCheck;
}
extension type JSCosmosStdSignature(JSAny _) implements JSAny {
  @JS("pub_key")
  external JSCosmosPubKey get pubKey;
  external String get signature;
  @JS("pub_key")
  external set pubKey(JSCosmosPubKey _);
  external set signature(String _);
  factory JSCosmosStdSignature.setup(
      {required JSCosmosPubKey pubKey, required String signature}) {
    return JSCosmosStdSignature(JSObject())
      ..pubKey = pubKey
      ..signature = signature;
  }
}
extension type JSCosmosAminoSignResponse(JSAny _) implements JSAny {
  external JSCosmosStdSignDoc get signed;
  external set signed(JSCosmosStdSignDoc _);
  external JSCosmosStdSignature get signature;
  external set signature(JSCosmosStdSignature _);
  factory JSCosmosAminoSignResponse.setup({
    required Map<String, dynamic> tx,
    required JSCosmosStdSignature signature,
  }) {
    return JSCosmosAminoSignResponse(JSObject())
      ..signed = JSCosmosStdSignDoc(tx.jsify() ?? JSObject())
      ..signature = signature;
  }
}
extension type JSCosmosSignDoc(JSAny _) implements JSAny {
  factory JSCosmosSignDoc.setup(
      {required List<int> bodyBytes,
      required List<int> authInfoBytes,
      required String chainId,
      required BigInt accountNumber}) {
    return JSCosmosSignDoc(JSObject())
      ..bodyBytes = APPJSUint8Array.fromList(bodyBytes)
      ..authInfoBytes = APPJSUint8Array.fromList(authInfoBytes)
      ..chainId = chainId;
  }
  external APPJSUint8Array? get bodyBytes;
  external set bodyBytes(APPJSUint8Array? _);

  external APPJSUint8Array? get authInfoBytes;
  external set authInfoBytes(APPJSUint8Array? _);
  external String? get chainId;
  external set chainId(String? _);
  external JSAny? get accountNumber;
  external set accountNumber(JSAny? _);
}

extension type JSCosmosDirectSignResponse(JSAny _) implements JSAny {
  factory JSCosmosDirectSignResponse.setup(
      {required JSCosmosStdSignature signature, required JSCosmosSignDoc signed}) {
    return JSCosmosDirectSignResponse(JSObject())
      ..signature = signature
      ..signed = signed;
  }
  external JSCosmosSignDoc get signed;
  external set signed(JSCosmosSignDoc _);
  external JSCosmosStdSignature get signature;
  external set signature(JSCosmosStdSignature _);
}
extension type JSCosmosOfflineDirectSigner(JSAny _) implements JSAny {
  factory JSCosmosOfflineDirectSigner.setup({
    required JSFunction getAccounts,
    required JSFunction signDirect,
    required String chainId,
  }) {
    return JSCosmosOfflineDirectSigner(JSObject())
      ..getAccounts = getAccounts
      ..signDirect = signDirect;
  }
  external set getAccounts(JSFunction _);
  external set signDirect(JSFunction _);
  external set chainId(String _);
  external String get chainId;
}

extension type JSCosmosOfflineAminoSigner(JSAny _) implements JSAny {
  factory JSCosmosOfflineAminoSigner.setup({
    required JSFunction getAccounts,
    required JSFunction signAmino,
    required String chainId,
  }) {
    return JSCosmosOfflineAminoSigner(JSObject())
      ..getAccounts = getAccounts
      ..signAmino = signAmino;
  }
  external set getAccounts(JSFunction _);
  external set signAmino(JSFunction _);
  external set chainId(String _);
  external String get chainId;
}

extension type JSCosmosSigner(JSAny _) implements JSAny {
  factory JSCosmosSigner.setup({
    required Proxy<JSCosmosOfflineDirectSigner> direct,
    required Proxy<JSCosmosOfflineAminoSigner> amino,
    required String chainId,
  }) {
    return JSCosmosSigner(JSObject())
      ..amino = amino
      ..direct = direct;
  }
  external set amino(Proxy<JSCosmosOfflineAminoSigner> _);
  external set direct(Proxy<JSCosmosOfflineDirectSigner> _);
  external set chainId(String _);
  external String get chainId;
}

extension type JSCosmosSignDirectRequest(JSAny _) implements JSAny {
  factory JSCosmosSignDirectRequest.setup(
      {required JSCosmosSignDoc signDoc,
      required String signerAddress,
      required String chainId,
      required JSCosmosSignOption? signOption}) {
    return JSCosmosSignDirectRequest(JSObject())
      ..signDoc = signDoc
      ..signerAddress = signerAddress
      ..chainId = chainId
      ..signOption = signOption;
  }
  external set signerAddress(String _);
  external String get signerAddress;
  external set signDoc(JSCosmosSignDoc _);
  external JSCosmosSignDoc get signDoc;
  external set chainId(String? _);
  external String? get chainId;
  external JSCosmosSignOption? get signOption;
  external set signOption(JSCosmosSignOption? _);
  static const List<String> properties = ['signerAddress', 'chainId', 'signDoc'];
}

extension type JSCosmosSignAminoRequest(JSAny _) implements JSAny {
  factory JSCosmosSignAminoRequest.setup(
      {required String signDoc,
      required String signerAddress,
      required String? chainId,
      required JSCosmosSignOption? signOption}) {
    return JSCosmosSignAminoRequest(JSObject())
      ..signDoc = signDoc
      ..signerAddress = signerAddress
      ..chainId = chainId
      ..signOption = signOption;
  }
  static const List<String> properties = ['signerAddress', 'chainId', 'signDoc'];
  external set signerAddress(String _);
  external String get signerAddress;
  external set signDoc(String _);
  external String get signDoc;
  external set chainId(String? _);
  external String? get chainId;
  external JSCosmosSignOption? get signOption;
  external set signOption(JSCosmosSignOption? _);
}
@JS()
extension type CosmosWalletAdapterConnectFeature(JSAny _) implements JSAny {
  factory CosmosWalletAdapterConnectFeature.setup(
      {required JSFunction connect,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
extension type JSCosmosWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSCosmosWalletStandardConnect.setup(List<JSCosmosWalletAccount> accounts) {
    return JSCosmosWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSCosmosWalletAccount> get accounts;
  external set accounts(JSArray<JSCosmosWalletAccount> _);
}

@JS()
extension type CosmosWalletAdapterSignerFeature(JSAny _) implements JSAny {
  factory CosmosWalletAdapterSignerFeature.setup(
      {required JSFunction signer,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterSignerFeature(JSObject())
      ..signer = signer
      ..version = version;
  }
  external set version(String version);
  external set signer(JSFunction _);
}
@JS()
extension type CosmosAddNewChainTokenParams(JSAny _) implements JSAny {
  external String? get name;
  external String? get symbol;
  external String? get denom;
  external int? get decimals;
  external String? get coingeckoId;
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "symbol": symbol,
      "denom": denom,
      "decimals": decimals,
      "coingeckoId": coingeckoId
    };
  }
}
extension type CosmosAddNewChainFeeTokenParams(JSAny _)
    implements CosmosAddNewChainTokenParams {
  external JSNumber? get low;
  external JSNumber? get average;
  external JSNumber? get high;
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "symbol": symbol,
      "denom": denom,
      "decimals": decimals,
      "coingeckoId": coingeckoId,
      "low": low?.toDartDouble,
      "average": average?.toDartDouble,
      "high": high?.toDartDouble
    };
  }
}
@JS()
extension type CosmosAddNewChainParams(JSAny _) implements JSAny {
  external String? get rpc;
  external String? get chainId;
  external String? get name;
  external String? get hrp;
  external JSArray<JSString>? get keyAlgos;
  external CosmosAddNewChainTokenParams? get nativeToken;
  external JSArray<CosmosAddNewChainFeeTokenParams>? get feeTokens;
  static const List<String> properties = ['rpc', 'chainId'];
  Map<String, dynamic> toJson() {
    return {
      "rpc": rpc,
      "chainId": chainId,
      "name": name,
      "hrp": hrp,
      "keyAlgos": keyAlgos,
      "nativeToken": nativeToken?.toJson(),
      "feeTokens": feeTokens?.toDart.map((e) => e.toJson()).toList(),
    };
  }
}
@JS()
extension type CosmosWalletAdapterAddNewChainFeature(JSAny _) implements JSAny {
  factory CosmosWalletAdapterAddNewChainFeature.setup(
      {required JSFunction addNewChain,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterAddNewChainFeature(JSObject())
      ..addNewChain = addNewChain
      ..version = version;
  }
  external set version(String version);
  external set addNewChain(JSFunction _);
}
extension type JSCosmosSignMessageParams(JSAny _) implements JSAny {
  external APPJSUint8Array get message;
  external JSCosmosWalletAccount get account;
  static List<String> properties = ['message', 'account'];
}
extension type JSCosmosSignMessageResponse(JSAny _) implements JSAny {
  factory JSCosmosSignMessageResponse.setup(
      {required List<int> signedMessage, required List<int> signature}) {
    return JSCosmosSignMessageResponse(JSObject())
      ..signedMessage = APPJSUint8Array.fromList(signedMessage)
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external set signedMessage(APPJSUint8Array _);
  external set signature(APPJSUint8Array _);
}
@JS()
extension type CosmosWalletAdapterStandardSignMessageFeature(JSAny _) implements JSAny {
  factory CosmosWalletAdapterStandardSignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterStandardSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}

@JS()
extension type CosmosWalletAdapterStandardSignTransactionDirectFeature(JSAny _)
    implements JSAny {
  factory CosmosWalletAdapterStandardSignTransactionDirectFeature.setup(
      {required JSFunction signTransactionDirect,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterStandardSignTransactionDirectFeature(JSObject())
      ..signTransactionDirect = signTransactionDirect
      ..version = version;
  }
  external set version(String version);
  external set signTransactionDirect(JSFunction _);
}
@JS()
extension type CosmosWalletAdapterStandardSignTransactionAminoFeature(JSAny _)
    implements JSAny {
  factory CosmosWalletAdapterStandardSignTransactionAminoFeature.setup(
      {required JSFunction signTransactionAmino,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterStandardSignTransactionAminoFeature(JSObject())
      ..signTransactionAmino = signTransactionAmino
      ..version = version;
  }
  external set version(String version);
  external set signTransactionAmino(JSFunction _);
}

@JS()
extension type CosmosWalletAdapterStandardSignTransactionFeature(JSAny _)
    implements JSAny {
  factory CosmosWalletAdapterStandardSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return CosmosWalletAdapterStandardSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
extension type JSCosmosSendOrSignTransactionParams(JSAny _) implements JSAny {
  external APPJSUint8Array get transaction;
  external JSArray<JSString>? get signatures;
  external JSCosmosWalletAccount? account;
  static const List<String> properties = ['account', 'transaction'];
}
