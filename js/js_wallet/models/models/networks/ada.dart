import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils.dart';
import '../base.dart';
import 'wallet_standard.dart';

@JS("cardano")
external JSWalletCardanoInjected? get cardanoNullable;
@JS("cardano")
external JSWalletCardanoInjected get cardano;
@JS("cardano")
external set cardano(JSWalletCardanoInjected _);

class ADAJSConst {
  static const String cardanoExtensionVersion = "1";
  static const String sendTransaction = "cardano_sendTransaction";
  static const String signTransaction = "cardano_signTransaction";
  static const String signAndSendTransaction = "cardano_signAndSendTransaction";
  static const String requestAccounts = "cardano_requestAccounts";
  static const String signMessage = "cardano_signMessage";
  static const String getNetworkId = "cardano_getNetworkId";
  static const String getUtxos = "cardano_getUtxos";
  static const String getAddressUtxos = "cardano_getAddressUtxos";
  static const String getBalance = "cardano_getBalance";
  static const String getUsedAddresses = "cardano_getUsedAddresses";
  static const String getUnusedAddresses = "cardano_getUnusedAddresses";
  static const String getChangeAddress = "cardano_getChangeAddress";
  static const String getRewardAddresses = "cardano_getRewardAddresses";
  static const String getCollateral = "cardano_getCollateral";

  static const String signData = "cardano_signData";
  static const String signTx = "cardano_signTx";
  static const String submitTx = "cardano_submitTx";
  static const String isEnabled = "cardano_isEnabled";
  static const String getExtensions = "cardano_getExtensions";

  ///
  static const String signTxs = "cardano_signTxs";
  static const String submitTxs = "cardano_submitTxs";

  ///
  static const String getAccountPub = "cardano_getAccountPub";

  ///
  static const String getScriptRequirements = "cardano_getScriptRequirements";
  static const String getScript = "cardano_getScript";
  static const String submitUnsignedTx = "cardano_submitUnsignedTx";
  static const String getCompletedTx = "cardano_getCompletedTx";

  static JSArray<JSString> defaultAccountFeatures(List<int>? publicKey, bool isReward) =>
      [
        if (!isReward) ...[
          if (publicKey == null) "cardano:getScript".toJS,
          if (publicKey == null) "cardano:getScriptRequirements".toJS,
          if (publicKey == null) "submitUnsignedTx".toJS,
          "cardano:signTransaction".toJS,
          "cardano:signAndSendTransaction".toJS,
          if (publicKey != null) "cardano:signMessage".toJS,
          "cardano:getUtxos".toJS,
          "cardano:signTx".toJS,
          if (publicKey != null) "cardano:signData".toJS,
        ]
      ].toJS;
}

@JS("cardano")
extension type JSWalletCardanoInjected(JSAny _) implements JSAny {
  external set onChain(Proxy<JSWalletCardanoExtension> _);
  @JS("onChain")
  external JSWalletCardanoExtension get onChain_;
}
@JS()
extension type JSWalletCardanoExtension(JSAny _) implements JSAny {
  external set isEnabled(JSFunction _);
  external set apiVersion(JSString _);
  // external set supportedExtensions(JSFunction _);
  external set name(JSString _);
  external JSString get icon;
  external set icon(JSString _);
  external set enable(JSFunction _);
  factory JSWalletCardanoExtension.setup(
      {required JSFunction isEnabled,
      required JSString apiVersion,
      required JSString name,
      required JSString icon,
      required JSFunction enable}) {
    return JSWalletCardanoExtension(JSObject())
      ..isEnabled = isEnabled
      ..apiVersion = apiVersion
      ..name = name
      ..icon = icon
      ..enable = enable;
  }
}

@JS()
extension type JSWalletCardanoCIP30Extension(JSAny _) implements JSAny {
  external set getExtensions(JSFunction _);
  external set getNetworkId(JSFunction _);
  external set getUtxos(JSFunction _);
  external set getCollateral(JSFunction _);
  external set getBalance(JSFunction _);
  external set getUsedAddresses(JSFunction _);
  external set getUnusedAddresses(JSFunction _);
  external set getChangeAddress(JSFunction _);
  external set getRewardAddresses(JSFunction _);
  external set signTx(JSFunction _);
  external set signData(JSFunction _);
  external set submitTx(JSFunction _);
  external set cip103(JSWalletCardanoCIP103Extension _);
  external set cip104(JSWalletCardanoCIP104Extension _);
  external set cip106(JSWalletCardanoCIP106Extension _);
  factory JSWalletCardanoCIP30Extension.setup({
    required JSFunction getExtensions,
    required JSFunction getNetworkId,
    required JSFunction getUtxos,
    required JSFunction getCollateral,
    required JSFunction getBalance,
    required JSFunction getUsedAddresses,
    required JSFunction getUnusedAddresses,
    required JSFunction getChangeAddress,
    required JSFunction getRewardAddresses,
    required JSFunction signTx,
    required JSFunction signData,
    required JSFunction submitTx,
    required JSWalletCardanoCIP103Extension cip103,
    required JSWalletCardanoCIP104Extension cip104,
    required JSWalletCardanoCIP106Extension cip106,
  }) {
    return JSWalletCardanoCIP30Extension(JSObject())
      ..getExtensions = getExtensions
      ..getNetworkId = getNetworkId
      ..getCollateral = getCollateral
      ..getBalance = getBalance
      ..getUsedAddresses = getUsedAddresses
      ..getUnusedAddresses = getUnusedAddresses
      ..getChangeAddress = getChangeAddress
      ..getRewardAddresses = getRewardAddresses
      ..signTx = signTx
      ..signData = signData
      ..submitTx = submitTx
      ..getUtxos = getUtxos
      ..cip103 = cip103
      ..cip104 = cip104
      ..cip106 = cip106;
  }
}

@JS()
extension type JSWalletCardanoCIP103Extension(JSAny _) implements JSAny {
  external set signTxs(JSFunction _);
  external set submitTxs(JSFunction _);
  factory JSWalletCardanoCIP103Extension.setup(
      {required JSFunction signTxs, required JSFunction submitTxs}) {
    return JSWalletCardanoCIP103Extension(JSObject())
      ..signTxs = signTxs
      ..submitTxs = submitTxs;
  }
}
@JS()
extension type JSWalletCardanoCIP104Extension(JSAny _) implements JSAny {
  external set getAccountPub(JSFunction _);
  factory JSWalletCardanoCIP104Extension.setup({
    required JSFunction getAccountPub,
  }) {
    return JSWalletCardanoCIP104Extension(JSObject())..getAccountPub = getAccountPub;
  }
}

@JS()
extension type JSWalletCardanoCIP106Extension(JSAny _) implements JSAny {
  external set getScriptRequirements(JSFunction _);
  external set getScript(JSFunction _);
  external set submitUnsignedTx(JSFunction _);
  external set getCompletedTx(JSFunction _);
  external set getCollateral(JSFunction _);
  factory JSWalletCardanoCIP106Extension.setup({
    required JSFunction getScriptRequirements,
    required JSFunction getScript,
    required JSFunction submitUnsignedTx,
    required JSFunction getCompletedTx,
    required JSFunction getCollateral,
  }) {
    return JSWalletCardanoCIP106Extension(JSObject())
      ..getScriptRequirements = getScriptRequirements
      ..getScript = getScript
      ..submitUnsignedTx = submitUnsignedTx
      ..getCompletedTx = getCompletedTx
      ..getCollateral = getCollateral;
  }
}

@JS()
extension type JSADAWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSADAWalletAccount.setup(
      {required String address,
      required List<int>? publicKey,
      required bool isRewardAddress,
      required String chain}) {
    return JSADAWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features = ADAJSConst.defaultAccountFeatures(publicKey, isRewardAddress).freez
      ..publicKey = publicKey == null ? null : APPJSUint8Array.fromList(publicKey);
  }
}

@JS()
extension type JSADAPaginate._(JSObject _) implements JSAny {
  external JSNumber get limit;
  external JSNumber get page;
}

@JS()
extension type JSWalletStandardADAGetNetworkIdFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetNetworkIdFeature.setup(
      {required JSFunction getNetworkId,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetNetworkIdFeature(JSObject())
      ..getNetwork = getNetworkId
      ..version = version;
  }
  external set version(String version);
  external set getNetwork(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetBalanceFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetBalanceFeature.setup(
      {required JSFunction getBalance,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetBalanceFeature(JSObject())
      ..getBalance = getBalance
      ..version = version;
  }
  external set version(String version);
  external set getBalance(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetUtxosFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetUtxosFeature.setup(
      {required JSFunction getUtxos,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetUtxosFeature(JSObject())
      ..getUtxos = getUtxos
      ..version = version;
  }
  external set version(String version);
  external set getUtxos(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetAddressUtxosFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetAddressUtxosFeature.setup(
      {required JSFunction getAddressUtxos,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetAddressUtxosFeature(JSObject())
      ..getAddressUtxos = getAddressUtxos
      ..version = version;
  }
  external set version(String version);
  external set getAddressUtxos(JSFunction _);
}

@JS()
extension type JSWalletStandardADAGetCollateralFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetCollateralFeature.setup(
      {required JSFunction getCollateral,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetCollateralFeature(JSObject())
      ..getCollateral = getCollateral
      ..version = version;
  }
  external set version(String version);
  external set getCollateral(JSFunction _);
}

@JS()
extension type JSWalletStandardADAGetUsedAddressesFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetUsedAddressesFeature.setup(
      {required JSFunction getUsedAddresses,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetUsedAddressesFeature(JSObject())
      ..getUsedAddresses = getUsedAddresses
      ..version = version;
  }
  external set version(String version);
  external set getUsedAddresses(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetUnusedAddressesFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetUnusedAddressesFeature.setup(
      {required JSFunction getUnusedAddresses,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetUnusedAddressesFeature(JSObject())
      ..getUnusedAddresses = getUnusedAddresses
      ..version = version;
  }
  external set version(String version);
  external set getUnusedAddresses(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetChangeAddressFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetChangeAddressFeature.setup(
      {required JSFunction getChangeAddress,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetChangeAddressFeature(JSObject())
      ..getChangeAddress = getChangeAddress
      ..version = version;
  }
  external set version(String version);
  external set getChangeAddress(JSFunction _);
}

@JS()
extension type JSWalletStandardADAGetRewardAddressesFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetRewardAddressesFeature.setup(
      {required JSFunction getRewardAddresses,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetRewardAddressesFeature(JSObject())
      ..getRewardAddresses = getRewardAddresses
      ..version = version;
  }
  external set version(String version);
  external set getRewardAddresses(JSFunction _);
}

@JS()
extension type JSWalletStandardADASignTxFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASignTxFeature.setup(
      {required JSFunction signTx,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASignTxFeature(JSObject())
      ..signTx = signTx
      ..version = version;
  }
  external set version(String version);
  external set signTx(JSFunction _);
}
@JS()
extension type JSWalletStandardADASignTxsFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASignTxsFeature.setup(
      {required JSFunction signTxs,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASignTxsFeature(JSObject())
      ..signTxs = signTxs
      ..version = version;
  }
  external set version(String version);
  external set signTxs(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetAccountPubFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetAccountPubFeature.setup(
      {required JSFunction getAccountPub,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetAccountPubFeature(JSObject())
      ..getAccountPub = getAccountPub
      ..version = version;
  }
  external set version(String version);
  external set getAccountPub(JSFunction _);
}
@JS()
extension type JSWalletStandardADAGetScriptRequirementsFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetScriptRequirementsFeature.setup(
      {required JSFunction getScriptRequirements,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetScriptRequirementsFeature(JSObject())
      ..getScriptRequirements = getScriptRequirements
      ..version = version;
  }
  external set version(String version);
  external set getScriptRequirements(JSFunction _);
}
@JS()
extension type JSWalletStandardADASubmitUnsignedTxFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASubmitUnsignedTxFeature.setup(
      {required JSFunction submitUnsignedTx,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASubmitUnsignedTxFeature(JSObject())
      ..submitUnsignedTx = submitUnsignedTx
      ..version = version;
  }
  external set version(String version);
  external set submitUnsignedTx(JSFunction _);
}
@JS()
extension type JSWalletStandardADASignDataFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASignDataFeature.setup(
      {required JSFunction signData,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASignDataFeature(JSObject())
      ..signData = signData
      ..version = version;
  }
  external set version(String version);
  external set signData(JSFunction _);
}
@JS()
extension type JSWalletStandardADASignMessageFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASignMessageFeature.setup(
      {required JSFunction signMessage,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS()
extension type JSWalletStandardADAIsEnabledFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAIsEnabledFeature.setup(
      {required JSFunction isEnabled,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAIsEnabledFeature(JSObject())
      ..isEnabled = isEnabled
      ..version = version;
  }
  external set version(String version);
  external set isEnabled(JSFunction _);
}
@JS()
extension type JSWalletStandardADASubmitTxFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASubmitTxFeature.setup(
      {required JSFunction submitTx,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASubmitTxFeature(JSObject())
      ..submitTx = submitTx
      ..version = version;
  }
  external set version(String version);
  external set submitTx(JSFunction _);
}
@JS()
extension type JSWalletStandardADASubmitTxsFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASubmitTxsFeature.setup(
      {required JSFunction submitTxs,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASubmitTxsFeature(JSObject())
      ..submitTxs = submitTxs
      ..version = version;
  }
  external set version(String version);
  external set submitTxs(JSFunction _);
}
@JS()
extension type JSWalletStandardADASignTransactionFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADASignTransactionFeature.setup(
      {required JSFunction signTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}

@JS()
extension type JSWalletStandardADASignAndSendTransactionFeature(JSAny _)
    implements JSAny {
  factory JSWalletStandardADASignAndSendTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADASignAndSendTransactionFeature(JSObject())
      ..signAndSendTransaction = signAndSendTransaction
      ..version = version;
  }
  external set version(String version);
  external set signAndSendTransaction(JSFunction _);
}

@JS()
extension type JSWalletStandardADAGetScriptFeature(JSAny _) implements JSAny {
  factory JSWalletStandardADAGetScriptFeature.setup(
      {required JSFunction getScript,
      String version = JSWalletStandardConst.defaultVersion}) {
    return JSWalletStandardADAGetScriptFeature(JSObject())
      ..getScript = getScript
      ..version = version;
  }
  external set version(String version);
  external set getScript(JSFunction _);
}

@JS()
extension type JSADASignMessageResponse(JSAny _) implements JSAny {
  factory JSADASignMessageResponse.setup(List<int> signature) {
    return JSADASignMessageResponse(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
@JS()
extension type JSADASignMessageParams._(JSObject _) implements JSAny {
  external JSADAWalletAccount? account;
  external APPJSUint8Array get message;
  static const List<String> properties = ['message'];
}

@JS()
extension type JSADAExtension._(JSObject _) implements JSAny {
  external JSNumber get cip;
  external set cip(JSNumber _);
  factory JSADAExtension.setup(int cip) {
    return JSADAExtension._(JSObject())..cip = cip.toJS;
  }
}

@JS()
extension type JSADASignOrSubmitTxesParams._(JSObject _) implements JSAny {
  external String get cbor;
  external bool? get partialSign;
}
@JS()
extension type JSADAGetCollateralParams._(JSObject _) implements JSAny {
  external String? amount;
}

@JS()
extension type JSADAGetAddressUtxosParams._(JSObject _) implements JSAny {
  external JSADAWalletAccount get account;
}

@JS()
extension type JSADAGetScriptParams._(JSObject _) implements JSAny {
  external JSADAWalletAccount get account;
}

@JS()
extension type JSADAGetAccountPubParams._(JSObject _) implements JSAny {
  external JSADAWalletAccount get account;
}
@JS()
extension type JSADASignDataResponse._(JSObject _) implements JSAny {
  external JSString get signature;
  external set signature(JSString _);
  external JSString get key;
  external set key(JSString _);
  external JSString get pubKey;
  external set pubKey(JSString _);
  factory JSADASignDataResponse.setup(
      {required String signature, required String key, required String pubKey}) {
    return JSADASignDataResponse._(JSObject())
      ..signature = signature.toJS
      ..key = key.toJS
      ..pubKey = pubKey.toJS;
  }
}
@JS()
extension type JSADAScriptRequirement._(JSObject _) implements JSAny {
  external JSNumber get code;
  external set code(JSNumber _);
  external JSString get value;
  external set value(JSString _);
  factory JSADAScriptRequirement.setup({
    required String value,
    int code = 3,
  }) {
    return JSADAScriptRequirement._(JSObject())
      ..value = value.toJS
      ..code = code.toJS;
  }
}
