import 'dart:js_interop';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/aptos.dart';
import 'wallet_standard.dart';

class AptosJSConstant {
  static const String version = '1.0.0';
  static final JSArray<JSString> supportedChains = [
    "aptos:devnet".toJS,
    "aptos:mainnet".toJS,
    "aptos:testnet".toJS,
  ].toJS;
  static final JSArray<JSString> aptosDefaultAccountFeatures = [
    "aptos:signAndSubmitTransaction".toJS,
    "aptos:signMessage".toJS,
    "aptos:signTransaction".toJS,
  ].toJS;
  static const String getNetworkRequestName = "aptos_network";
  static const String requestAccountRequestName = "aptos_requestAccounts";
  static const String signTransaction = "aptos_signTransaction";
  static const String signMessageRequestName = "aptos_signMessage";
  static const String secondarySignerAddressesRequiredKeys = "secondarySignerAddresses";
  static const String changeNetworkRequestName = "wallet_switchAptosChain";
}

extension type JSAptosChangeNetworkOutput(JSAny _) implements JSAny {
  external set reason(String? _);
  external set success(bool? _);
}

extension type JSAptosNetworkInfo(JSAny _) implements JSAny {
  external String get name;
  external int? get chainId;
  external String? get url;
  factory JSAptosNetworkInfo.setup(
      {required String name, required int? chainId, String? url}) {
    return JSAptosNetworkInfo(JSObject())
      ..name = name
      ..chainId = chainId
      ..url = url;
  }
  external set name(String _);
  external set chainId(int? _);
  external set url(String? _);
}
@JS()
extension type AptosWalletAdapterFeatures(JSAny _) implements JSAny {
  factory AptosWalletAdapterFeatures.setup() {
    return AptosWalletAdapterFeatures(JSObject());
  }
  @JS("aptos:connect")
  external set connect(AptosWalletAdapterStandardConnectFeature _);
  @JS("aptos:account")
  external set account(AptosWalletAdapterStandardAccountFeature _);
  @JS("aptos:disconnect")
  external set disconnect(AptosWalletAdapterStandardDisconnectFeature _);
  @JS("aptos:network")
  external set network(AptosWalletAdapterStandardGetNetworkFeature _);
  @JS("aptos:onAccountChange")
  external set onAccountChange(AptosWalletAdapterStandardOnAccountChangeFeature _);
  @JS("aptos:onNetworkChange")
  external set onNetworkChange(AptosWalletAdapterStandardOnNetworkChangeFeature _);
  @JS("aptos:signTransaction")
  external set signTransaction(AptosWalletAdapterStandardSignTransactionFeature _);
  @JS("aptos:signMessage")
  external set signMessage(AptosWalletAdapterStandardSignMessageFeature _);
  @JS("aptos:changeNetwork")
  external set changeNetwork(AptosWalletAdapterStandardChangeNetworkFeature _);
}
@JS()
extension type AptosWalletAdapterStandardChangeNetworkFeature(JSAny _) implements JSAny {
  factory AptosWalletAdapterStandardChangeNetworkFeature.setup(
      {required JSFunction changeNetwork, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardChangeNetworkFeature(JSObject())
      ..changeNetwork = changeNetwork
      ..version = version;
  }
  external set version(String version);
  external set changeNetwork(JSFunction _);
}
@JS()
extension type AptosWalletAdapterStandardConnectFeature(JSAny _) implements JSAny {
  factory AptosWalletAdapterStandardConnectFeature.setup(
      {required JSFunction connect, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
@JS()
extension type AptosWalletAdapterStandardDisconnectFeature(JSAny _) implements JSAny {
  factory AptosWalletAdapterStandardDisconnectFeature.setup(
      {required JSFunction disconnect, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardDisconnectFeature(JSObject())
      ..disconnect = disconnect
      ..version = version;
  }
  external set version(String version);
  external set disconnect(JSFunction _);
}
@JS()
extension type AptosWalletAdapterStandardAccountFeature(JSAny _) implements JSAny {
  factory AptosWalletAdapterStandardAccountFeature.setup(
      {required JSFunction account, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardAccountFeature(JSObject())
      ..account = account
      ..version = version;
  }
  external set version(String version);
  external set account(JSFunction _);
}
@JS()
extension type AptosWalletAdapterStandardGetNetworkFeature(JSAny _) implements JSAny {
  factory AptosWalletAdapterStandardGetNetworkFeature.setup(
      {required JSFunction network, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardGetNetworkFeature(JSObject())
      ..network = network
      ..version = version;
  }
  external set version(String version);
  external set network(JSFunction _);
}
@JS()
extension type AptosWalletAdapterStandardOnAccountChangeFeature(JSAny _)
    implements JSAny {
  factory AptosWalletAdapterStandardOnAccountChangeFeature.setup(
      {required JSFunction onAccountChange, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardOnAccountChangeFeature(JSObject())
      ..onAccountChange = onAccountChange
      ..version = version;
  }
  external set version(String version);
  external set onAccountChange(JSFunction _);
}
@JS()
extension type AptosWalletAdapterStandardOnNetworkChangeFeature(JSAny _)
    implements JSAny {
  factory AptosWalletAdapterStandardOnNetworkChangeFeature.setup(
      {required JSFunction onNetworkChange, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardOnNetworkChangeFeature(JSObject())
      ..onNetworkChange = onNetworkChange
      ..version = version;
  }
  external set version(String version);
  external set onNetworkChange(JSFunction _);
}
@JS("aptos:signTransaction")
extension type AptosWalletAdapterStandardSignTransactionFeature(JSAny _)
    implements JSAny {
  factory AptosWalletAdapterStandardSignTransactionFeature.setup(
      {required JSFunction signTransaction, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}
@JS("aptos:signMessage")
extension type AptosWalletAdapterStandardSignMessageFeature(JSAny _) implements JSAny {
  factory AptosWalletAdapterStandardSignMessageFeature.setup(
      {required JSFunction signMessage, String version = AptosJSConstant.version}) {
    return AptosWalletAdapterStandardSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}

extension type JSAptosPublicKey._(JSObject _) implements JSAptosSerializableObject {
  factory JSAptosPublicKey.setup(
      {required List<int> publicKey, required String publicKeyHex}) {
    return JSAptosPublicKey._(JSObject())
      ..data = APPJSUint8Array.fromList(publicKey)
      ..dataHex = publicKeyHex;
  }
}
extension type JSAptosWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSAptosWalletAccount.setup(
      {required String address,
      required JSAptosPublicKey publicKey,
      required int signingScheme,
      required String chain}) {
    return JSAptosWalletAccount._(JSObject())
      ..address = address
      ..publicKey = publicKey
      ..signingScheme = signingScheme
      ..chains = [chain.toJS].toJS
      ..features = AptosJSConstant.aptosDefaultAccountFeatures
      ..ansName = null;
  }
  external set signingScheme(int _);
  external String? get ansName;
  external set ansName(String? _);
  external JSAptosPublicKey get publicKey;
}
extension type JSAptosAccountChanged(JSAny _) implements JSAny {
  factory JSAptosAccountChanged.setup(
      {required List<JSAptosWalletAccount> addresses,
      JSAptosWalletAccount? defaultAddress}) {
    return JSAptosAccountChanged(JSObject())
      ..addresses = addresses.toJS
      ..defaultAddress = defaultAddress;
  }
  external set addresses(JSArray<JSAptosWalletAccount> _);
  external set defaultAddress(JSAptosWalletAccount? _);
  external JSArray<JSAptosWalletAccount> get addresses;
  external JSAptosWalletAccount? get defaultAddress;
  JSArray<JSString> toWalletEvent() {
    return addresses.toDart.map((e) => e.address.toJS).toList().toJS;
  }
}

extension type JSAptosSignTransactionParams(JSAny _) implements JSAny {
  external APPJSUint8Array bcsToBytes();
  external JSAptosSignTransactionParams? get rawTransaction;
  external JSAny? feePayerAddress;
  external JSArray<JSAny>? secondarySignerAddresses;
  JSAptosSignTransactionRequest toRequest() {
    try {
      APPJSUint8Array rawTx;
      final rawStr = rawTransaction?.toString();
      if (rawStr != null) {
        if (StringUtils.isHexBytes(rawStr)) {
          rawTx = APPJSUint8Array.fromList(BytesUtils.fromHexString(rawStr));
        } else {
          rawTx = rawTransaction!.bcsToBytes();
        }
        return JSAptosSignTransactionRequest(
          rawTransaction: rawTx,
          feePayerAddress: feePayerAddress?.toString().toJS,
          secondarySignerAddresses: secondarySignerAddresses?.toDart
              .map((e) => e.toString().toJS)
              .toList()
              .toJS,
        );
      }
    } catch (_) {}
    throw Web3AptosExceptionConstant.invalidTransaction;
  }
}

extension type JSAptosSignTransactionRequest._(JSAny _) implements JSAny {
  external factory JSAptosSignTransactionRequest(
      {APPJSUint8Array rawTransaction,
      JSString? feePayerAddress,
      JSArray<JSString>? secondarySignerAddresses});
  external APPJSUint8Array? get rawTransaction;
  external JSString? get feePayerAddress;
  external JSArray<JSString>? get secondarySignerAddresses;
}

extension type JSAptosSignMessageParams(JSAny _) implements JSAny {
  external bool? get address;
  external bool? get application;
  external bool? get chainId;
  external String get message;
  external String get nonce;
  static List<String> get requiredKey => ["message", "nonce"];
}
extension type JSAptosSignMessageResponse(JSAny _) implements JSAptosSerializableObject {
  factory JSAptosSignMessageResponse.setup(
      {required List<int> signatureBytes,
      required String signatureHex,
      required String message,
      required String nonce,
      required String fullMessage,
      required String prefix,
      required String? address,
      required String? application,
      required int? chainId}) {
    return JSAptosSignMessageResponse(JSObject())
      ..address = address
      ..message = message
      ..nonce = nonce
      ..fullMessage = fullMessage
      ..prefix = prefix
      ..application = application
      ..chainId = chainId
      ..data = APPJSUint8Array.fromList(signatureBytes)
      ..dataHex = signatureHex
      ..signature = signatureHex;
  }
  external String? get address;
  external set address(String? _);
  external String? get application;
  external set application(String? _);
  external int? get chainId;
  external set chainId(int? _);

  external String get message;
  external set message(String _);
  external String get nonce;
  external set nonce(String _);
  external String get fullMessage;
  external set fullMessage(String _);
  external String get prefix;
  external set prefix(String _);
  external set signature(String _);
}

@JS()
extension type JSAptosSerializable(JSAny _) implements JSAny {
  external void serializeFixedBytes(APPJSUint8Array _);
}
extension type JSAptosSerializableObject(JSAny _) implements JSAny {
  factory JSAptosSerializableObject.setup(List<int> bytes) {
    return JSAptosSerializableObject(JSObject());
  }

  external APPJSUint8Array get data;
  external String get dataHex;
  external set data(APPJSUint8Array _);
  external set dataHex(String _);
  external set serialize(JSFunction _);
  external set bcsToBytes(JSFunction _);
  external set bcsToHex(JSFunction _);
  external set toStringWithoutPrefix(JSFunction _);
  @JS("toString")
  external set toSr(JSFunction _);

  String _toString() {
    return dataHex;
  }

  String _toStringWithoutPrefix() {
    return dataHex.substring(2);
  }

  void buildSerializable() {
    bcsToBytes = () {
      return data;
    }.toJS;
    serialize = (JSAptosSerializable serializer) {
      serializer.serializeFixedBytes(data);
    }.toJS;
    bcsToHex = () {
      return dataHex;
    }.toJS;
    toStringWithoutPrefix = _toStringWithoutPrefix.toJS;
    toSr = _toString.toJS;
  }
}

extension type JSAptosSignTransactionResponse(JSAny _)
    implements JSAptosSerializableObject {
  factory JSAptosSignTransactionResponse.setup(
      {required List<int> bytes, required String dataHex}) {
    return JSAptosSignTransactionResponse(JSObject())
      ..data = APPJSUint8Array.fromList(bytes)
      ..dataHex = dataHex;
  }
}

extension type JSAptosSwitchChainResponse(JSAny _) implements JSAny {
  factory JSAptosSwitchChainResponse.success() {
    return JSAptosSwitchChainResponse(JSObject())..success = true;
  }
  factory JSAptosSwitchChainResponse.fail({String? reason}) {
    return JSAptosSwitchChainResponse(JSObject())
      ..success = false
      ..reason = reason;
  }
  external set success(bool _);
  external set reason(String? _);
}

enum JSAptosWalletStandardUserResponseStatus {
  approved("Approved"),
  rejected("Rejected");

  final String name;
  const JSAptosWalletStandardUserResponseStatus(this.name);
  bool get isRejected => this == rejected;
  static JSAptosWalletStandardUserResponseStatus fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw Web3RequestExceptionConst.internalErr(
            "JSAptosWalletStandardUserResponseStatus",
            details: {"name": name}));
  }
}

extension type JSAptosWalletStandardUserResponse<ARGS extends JSAny>(JSAny _)
    implements JSAny {
  factory JSAptosWalletStandardUserResponse.approved(ARGS args) {
    return JSAptosWalletStandardUserResponse(JSObject())
      ..status = JSAptosWalletStandardUserResponseStatus.approved.name
      ..args = args;
  }
  factory JSAptosWalletStandardUserResponse.rejected() {
    return JSAptosWalletStandardUserResponse(JSObject())
      ..status = JSAptosWalletStandardUserResponseStatus.rejected.name;
  }
  external String get status;
  external set status(String _);
  external ARGS get args;
  external set args(ARGS _);
  JSAptosWalletStandardUserResponseStatus get type =>
      JSAptosWalletStandardUserResponseStatus.fromName(status);
}
