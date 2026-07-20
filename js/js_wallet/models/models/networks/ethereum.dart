import 'dart:js_interop';

import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/web.dart';

import '../../../constant/constant.dart';
import 'wallet_standard.dart';

class JSEthereumConst {
  static final JSArray<JSString> defaultAccountFeatures =
      ["ethereum:personalSign".toJS, "ethereum:sendTransaction".toJS].toJS;

  static const String sendTransaction = "eth_sendTransaction";
  static const String personalSign = "personal_sign";
  static const String ethSign = "eth_sign";
  static const String requestAccounts = "eth_requestAccounts";
  static const String typedData = "eth_signTypedData";
  static const String typedDataV3 = "eth_signTypedData_v3";
  static const String typedDataV4 = "eth_signTypedData_v4";
  static const String addChain = "wallet_addEthereumChain";
  static const String eip6963Request = "eip6963:requestProvider";
  static const String eip6963AnnounceProvider = "eip6963:announceProvider";
}

extension type EIP1193(JSObject _) implements JSAny {
  external set request(JSFunction f);
  @JS("request")
  external JSPromise<JSAny?> requestPromis(EthereumRequestParams params);
  external set on(JSFunction f);
  external set removeListener(JSFunction f);
  // external set autoRefreshOnNetworkChange(JSFunction f);
  external set disconnect(JSFunction f);
  external set enable(JSFunction f);
  external set connect(JSFunction f);
  @JS("chainId")
  external set chainId(String? _);
  @JS("chainId")
  external String? get chainId;
  @JS("networkVersion")
  external set networkVersion(String? _);
  @JS("networkVersion")
  external String? get networkVersion;
  @JS("selectedAddress")
  external set selectedAddress(String? _);
  @JS("selectedAddress")
  external String? get selectedAddress;

  external JSAny? get autoRefreshOnNetworkChange;

  @JS("isOnChain")
  external set isOnChain(bool? _);

  static EIP1193 setup(
      {required JSFunction request,
      required JSFunction on,
      required JSFunction removeListener,
      required JSFunction disconnect,
      required JSFunction enable}) {
    final eip = EIP1193(JSObject());
    eip.request = request;
    eip.on = on;
    eip.removeListener = removeListener;
    eip.disconnect = disconnect;
    eip.enable = enable;
    eip.connect = enable;
    eip.isOnChain = true;
    return eip;
  }
}
@JS()
extension type EIP6963ProviderInfo._(JSObject _) implements JSOBJ {
  external factory EIP6963ProviderInfo(
      {required String uuid, required String name, required String icon, String? rdns});
  external String get uuid;
  external String get name;
  external String get icon;
  external String get rdns;
  static final providerInfo = EIP6963ProviderInfo(
      uuid: JSWalletConstant.uuid,
      name: JSWalletConstant.name,
      icon: JSWalletConstant.appPngImage,
      rdns: JSWalletConstant.rdns);
}
@JS()
extension type EIP6963._(JSObject _) implements JSOBJ {
  external factory EIP6963({required EIP6963ProviderInfo info, required JSAny? provider});
  external EIP6963ProviderInfo get info;
  external EIP1193 get provider;

  static void setup(JSAny? ethereum) {
    final event = CustomEvent(
        JSEthereumConst.eip6963AnnounceProvider,
        EventInit(
            bubbles: true,
            cancelable: false,
            detail: JSOBJ.freeze(
                EIP6963(info: EIP6963ProviderInfo.providerInfo, provider: ethereum))));
    void onRequestProvider(CustomEvent r) {
      jsWindow.dispatchEvent(event);
      jsWindow.removeEventListener(
          JSEthereumConst.eip6963Request, onRequestProvider.toJS);
    }

    jsWindow.addEventListener(JSEthereumConst.eip6963Request, onRequestProvider.toJS);
    jsWindow.dispatchEvent(event);
  }
}

@JS()
extension type EthereumRequestParams._(JSObject o) implements JSAny {
  external factory EthereumRequestParams({String? method, JSAny? params, int? id});
  external String get method;
  external set method(String? method);
  external JSAny? get params;
}

@JS()
extension type JSEthereumEIPChainChanged._(JSObject o) implements JSAny {
  external String get chainId;
  external String get netVersion;
  external factory JSEthereumEIPChainChanged(
      {required String chainId, required String netVersion});
}

@JS()
extension type JSEthereumEIPProviderRpcError._(JSObject o) implements JSAny {
  external String get message;
  external int get code;
  external JSAny? get data;
  external factory JSEthereumEIPProviderRpcError(
      {required String message, required int code, JSAny? data});
}

@JS()
extension type JSEthereumTransactionAccessListParams._(JSObject o) implements JSAny {
  external String? get address;
  external JSArray<JSString>? get storageKeys;
}

@JS()
extension type JSEthereumTransactionParams._(JSObject o) implements JSAny {
  external String? get nonce;
  external String? get gasLimit;
  external String? get maxPriorityFeePerGas;
  external String? get maxFeePerGas;
  external String? get gasPrice;
  external String? get from;
  external String? get to;
  external String? get value;
  external String? get data;
  external String? get chainId;
  external String? get type;
  external JSArray<JSEthereumTransactionAccessListParams>? get accessList;
}
@JS()
extension type JSEthereumWalletStandardTransactionParams._(JSObject o) implements JSAny {
  external JSSEthereumWalletAccount? get account;
  external JSEthereumTransactionParams? get transaction;
  static const List<String> properties = ['account', 'transaction'];
}
@JS()
extension type JSEthereumSwitchChainParams._(JSObject o) implements JSAny {
  external String get chainId;
}

@JS()
extension type JSEthereumNativeCurrencyParams._(JSObject o) implements JSAny {
  external int? get decimals;
  external String? get name;
  external String? get symbol;
}
@JS()
extension type JSEthereumAddNewChainParams._(JSObject o) implements JSAny {
  external String? get chainId;
  external String? get chainName;
  external JSArray<JSString>? get rpcUrls;
  external JSArray<JSString>? get iconUrls;
  external JSArray<JSString>? get blockExplorerUrls;
  external JSEthereumNativeCurrencyParams? get nativeCurrency;
}
@JS()
extension type JSSEthereumWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSSEthereumWalletAccount.setup(
      {required String address, required List<int>? publicKey, required String chain}) {
    return JSSEthereumWalletAccount._(JSObject())
      ..address = address
      ..publicKey = publicKey == null ? null : APPJSUint8Array.fromList(publicKey)
      ..chains = [chain.toJS].toJS
      ..features = JSEthereumConst.defaultAccountFeatures;
  }
}
@JS()
extension type JSEthereumWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSEthereumWalletStandardConnect.setup(List<JSSEthereumWalletAccount> accounts) {
    return JSEthereumWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSSEthereumWalletAccount> get accounts;
  external set accounts(JSArray<JSSEthereumWalletAccount> _);
}

@JS()
extension type EthereumWalletAdapterConnectFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterConnectFeature.setup(
      {required JSFunction connect,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterPersonalSignFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterPersonalSignFeature.setup(
      {required JSFunction personalSign,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterPersonalSignFeature(JSObject())
      ..personalSign = personalSign
      ..version = version;
  }
  external set version(String version);
  external set personalSign(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterEthSignFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterEthSignFeature.setup(
      {required JSFunction ethSign,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterEthSignFeature(JSObject())
      ..ethSign = ethSign
      ..version = version;
  }
  external set version(String version);
  external set ethSign(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterSendTransactionFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterSendTransactionFeature.setup(
      {required JSFunction sendTransaction,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterSendTransactionFeature(JSObject())
      ..sendTransaction = sendTransaction
      ..version = version;
  }
  external set version(String version);
  external set sendTransaction(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterSignTypedDataFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterSignTypedDataFeature.setup(
      {required JSFunction signTypedData,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterSignTypedDataFeature(JSObject())
      ..signTypedData = signTypedData
      ..version = version;
  }
  external set version(String version);
  external set signTypedData(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterSignTypedDataV4Feature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterSignTypedDataV4Feature.setup(
      {required JSFunction signTypedDataV4,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterSignTypedDataV4Feature(JSObject())
      ..signTypedDataV4 = signTypedDataV4
      ..version = version;
  }
  external set version(String version);
  external set signTypedDataV4(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterSignTypedDataV3Feature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterSignTypedDataV3Feature.setup(
      {required JSFunction signTypedDataV3,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterSignTypedDataV3Feature(JSObject())
      ..signTypedDataV3 = signTypedDataV3
      ..version = version;
  }
  external set version(String version);
  external set signTypedDataV3(JSFunction _);
}
@JS()
extension type EthereumWalletAdapterAddNewChainFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapterAddNewChainFeature.setup(
      {required JSFunction addNewChain,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapterAddNewChainFeature(JSObject())
      ..addNewChain = addNewChain
      ..version = version;
  }
  external set version(String version);
  external set addNewChain(JSFunction _);
}
@JS()
extension type EthereumWalletAdapteRequestFeature(JSAny _) implements JSAny {
  factory EthereumWalletAdapteRequestFeature.setup(
      {required JSFunction request,
      String version = JSWalletStandardConst.defaultVersion}) {
    return EthereumWalletAdapteRequestFeature(JSObject())
      ..request = request
      ..version = version;
  }
  external set version(String version);
  external set request(JSFunction _);
}
@JS()
extension type JSEthereumSignTypedDataParams._(JSObject o) implements JSAny {
  external JSSEthereumWalletAccount? get account;
  external JSAny? get typedData;
  static const List<String> peroperties = ['account', 'typedData'];
}
@JS()
extension type JSEthereumSignMessageParams._(JSObject o) implements JSAny {
  external JSSEthereumWalletAccount? get account;
  external APPJSUint8Array? get message;
  static const List<String> peroperties = ['account', 'message'];
}
@JS()
extension type JSEthereumSignatureResponse._(JSObject o) implements JSAny {
  factory JSEthereumSignatureResponse.setup(List<int> signature) {
    return JSEthereumSignatureResponse._(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}
@JS()
extension type JSEthereumSendTransactionResponse._(JSObject o) implements JSAny {
  factory JSEthereumSendTransactionResponse.setup(String txId) {
    return JSEthereumSendTransactionResponse._(JSObject())..txId = txId;
  }
  external String get txId;
  external set txId(String _);
}
@JS()
extension type JSEthereumSwitchChainResponse._(JSObject o) implements JSAny {
  factory JSEthereumSwitchChainResponse.setup(String chainId) {
    return JSEthereumSwitchChainResponse._(JSObject())..chainId = chainId;
  }
  external String get chainId;
  external set chainId(String _);
}
