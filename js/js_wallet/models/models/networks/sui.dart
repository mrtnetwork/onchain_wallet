import 'dart:js_interop';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/web.dart';
import '../../models.dart';
import 'wallet_standard.dart';

class SuiJSConstant {
  static const String version = '1.0.0';
  static const String signAndExecuteTransactionVersion = '2.0.0';
  static final JSArray<JSString> supportedChains = [
    "sui:devnet".toJS,
    "sui:mainnet".toJS,
    "sui:testnet".toJS,
  ].toJS;
  static final JSArray<JSString> suiDefaultAccountFeatures = [
    "sui:signPersonalMessage".toJS,
    "sui:signMessage".toJS,
    "sui:signTransaction".toJS,
    "sui:signTransactionBlock".toJS,
    "sui:signAndExecuteTransaction".toJS,
    "sui:signAndExecuteTransactionBlock".toJS
  ].toJS;
  static const String requestAccountRequestName = "sui_requestAccounts";
  static const String signTransactionRequestName = "sui_signTransaction";
  static const String signAndExecuteTransaction = "sui_signAndExecuteTransaction";
  static const String signTransactionBlockRequestName = "sui_signTransactionBlock";
  static const String signAndExecuteTransactionBlock =
      "sui_signAndExecuteTransactionBlock";
  static const String signMessageRequestName = "sui_signMessage";
  static const String signPersonalMessageRequestName = "sui_signPersonalMessage";
  static final JSError invalidTransaction = JSError(
      message:
          "Invalid Sui transaction. The transaction must include transactionBlock with the blockData property for v1, or transaction with the toJSON property for v2.");
}

extension type JSSuiNetworkInfo(JSAny _) implements JSAny {
  factory JSSuiNetworkInfo.setup({required String name}) {
    return JSSuiNetworkInfo(JSObject())..chains = [name.toJS].toJS;
  }
  external JSArray<JSString>? get chains;
  external set chains(JSArray<JSString>? _);
}
@JS()
extension type SuiWalletAdapterFeatures(JSAny _) implements JSAny {
  factory SuiWalletAdapterFeatures.setup() {
    return SuiWalletAdapterFeatures(JSObject());
  }
  @JS("standard:connect")
  external set connect(SuiWalletAdapterStandardConnectFeature _);

  @JS("standard:events")
  external set events(SuiWalletAdapterStandardEventsFeature _);

  @JS("sui:disconnect")
  external set disconnect(SuiWalletAdapterStandardDisconnectFeature _);
  @JS("sui:reportTransactionEffects")
  external set reportTransactionEffects(
      SuiWalletAdapterStandardReportTransactionEffectskFeature _);
  @JS("sui:signAndExecuteTransaction")
  external set signAndExecuteTransaction(
      SuiWalletAdapterStandardSignAndExecuteTransactionFeature _);
  @JS("sui:signAndExecuteTransactionBlock")
  external set signAndExecuteTransactionBlock(
      SuiWalletAdapterStandardSignAndExecuteTransactionBlockFeature _);
  @JS("sui:signTransaction")
  external set signTransaction(SuiWalletAdapterStandardSignTransactionFeature _);
  @JS("sui:signTransactionBlock")
  external set signTransactionBlock(
      SuiWalletAdapterStandardSignTransactionBlockFeature _);
  @JS("sui:signPersonalMessage")
  external set signPersonalMessage(SuiWalletAdapterStandardSignPersonalMessageFeature _);
  @JS("sui:signMessage")
  external set signMessage(SuiWalletAdapterStandardSignMessageFeature _);
}

@JS()
extension type SuiWalletAdapterStandardConnectFeature(JSAny _) implements JSAny {
  factory SuiWalletAdapterStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return SuiWalletAdapterStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
@JS()
extension type SuiWalletAdapterStandardEventsFeature(JSAny _) implements JSAny {
  factory SuiWalletAdapterStandardEventsFeature.setup(
      {required JSFunction on, String version = SolanaJSConstant.version}) {
    return SuiWalletAdapterStandardEventsFeature(JSObject())
      ..on = on
      ..version = version;
  }
  external set version(String version);
  external set on(JSFunction _);
}

@JS()
extension type SuiWalletAdapterStandardDisconnectFeature(JSAny _) implements JSAny {
  factory SuiWalletAdapterStandardDisconnectFeature.setup(
      {required JSFunction disconnect, String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardDisconnectFeature(JSObject())
      ..disconnect = disconnect
      ..version = version;
  }
  external set version(String version);
  external set disconnect(JSFunction _);
}

@JS()
extension type SuiWalletAdapterStandardReportTransactionEffectskFeature(JSAny _)
    implements JSAny {
  factory SuiWalletAdapterStandardReportTransactionEffectskFeature.setup(
      {required JSFunction reportTransactionEffects,
      String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardReportTransactionEffectskFeature(JSObject())
      ..reportTransactionEffects = reportTransactionEffects
      ..version = version;
  }
  external set version(String version);
  external set reportTransactionEffects(JSFunction _);
}

@JS()
extension type SuiWalletAdapterStandardSignAndExecuteTransactionFeature(JSAny _)
    implements JSAny {
  factory SuiWalletAdapterStandardSignAndExecuteTransactionFeature.setup(
      {required JSFunction signAndExecuteTransaction,
      String version = SuiJSConstant.signAndExecuteTransactionVersion}) {
    return SuiWalletAdapterStandardSignAndExecuteTransactionFeature(JSObject())
      ..signAndExecuteTransaction = signAndExecuteTransaction
      ..version = version;
  }
  external set version(String version);
  external set signAndExecuteTransaction(JSFunction _);
}
@JS()
extension type SuiWalletAdapterStandardSignAndExecuteTransactionBlockFeature(JSAny _)
    implements JSAny {
  factory SuiWalletAdapterStandardSignAndExecuteTransactionBlockFeature.setup(
      {required JSFunction signAndExecuteTransactionBlock,
      String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardSignAndExecuteTransactionBlockFeature(JSObject())
      ..signAndExecuteTransactionBlock = signAndExecuteTransactionBlock
      ..version = version;
  }
  external set version(String version);
  external set signAndExecuteTransactionBlock(JSFunction _);
}
@JS("sui:signTransactionBlock")
extension type SuiWalletAdapterStandardSignTransactionBlockFeature(JSAny _)
    implements JSAny {
  factory SuiWalletAdapterStandardSignTransactionBlockFeature.setup(
      {required JSFunction signTransactionBlock,
      String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardSignTransactionBlockFeature(JSObject())
      ..signTransactionBlock = signTransactionBlock
      ..version = version;
  }
  external set version(String version);
  external set signTransactionBlock(JSFunction _);
}
@JS()
extension type SuiWalletAdapterStandardSignTransactionFeature(JSAny _) implements JSAny {
  factory SuiWalletAdapterStandardSignTransactionFeature.setup(
      {required JSFunction signTransaction, String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version;
  }
  external set version(String version);
  external set signTransaction(JSFunction _);
}

@JS("sui:signMessage")
extension type SuiWalletAdapterStandardSignMessageFeature(JSAny _) implements JSAny {
  factory SuiWalletAdapterStandardSignMessageFeature.setup(
      {required JSFunction signMessage, String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}
@JS("sui:signPersonalMessage")
extension type SuiWalletAdapterStandardSignPersonalMessageFeature(JSAny _)
    implements JSAny {
  factory SuiWalletAdapterStandardSignPersonalMessageFeature.setup(
      {required JSFunction signPersonalMessage, String version = SuiJSConstant.version}) {
    return SuiWalletAdapterStandardSignPersonalMessageFeature(JSObject())
      ..signPersonalMessage = signPersonalMessage
      ..version = version;
  }
  external set version(String version);
  external set signPersonalMessage(JSFunction _);
}

extension type JSSuiWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSSuiWalletAccount.setup(
      {required String address,
      required List<int> publicKey,
      required int signingScheme,
      required String chain}) {
    return JSSuiWalletAccount._(JSObject())
      ..address = address
      ..publicKey = APPJSUint8Array.fromList(publicKey)
      ..signingScheme = signingScheme
      ..chains = [chain.toJS].toJS
      ..features = SuiJSConstant.suiDefaultAccountFeatures;
  }
  external set signingScheme(int _);
}
extension type JSSuiWalletConnectResponse._(JSObject _) implements JSAny {
  factory JSSuiWalletConnectResponse.setup(List<JSSuiWalletAccount> accounts) {
    return JSSuiWalletConnectResponse._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSSuiWalletAccount> get accounts;
  external set accounts(JSArray<JSSuiWalletAccount> _);
}

extension type JSSuiAccountChanged(JSAny _) implements JSAny {
  factory JSSuiAccountChanged.setup(
      {required List<JSSuiWalletAccount> accounts, JSSuiWalletAccount? defaultAddress}) {
    return JSSuiAccountChanged(JSObject())
      ..accounts = accounts.toJS
      ..defaultAddress = defaultAddress;
  }
  external set accounts(JSArray<JSSuiWalletAccount> _);
  external set defaultAddress(JSSuiWalletAccount? _);
  external JSArray<JSSuiWalletAccount> get accounts;
  external JSSuiWalletAccount? get defaultAddress;
  JSArray<JSString> toWalletEvent() {
    return accounts.toDart.map((e) => e.address.toJS).toList().toJS;
  }
}

extension type JSSuiSignTransactionV1(JSAny _) implements JSAny {
  @JS("blockData")
  external JSAny get blockData;
}
extension type JSSuiSignTransactionV2(JSAny _) implements JSAny {
  external JSPromise<JSString> toJSON();
}
extension type JSSuiTransactionBlockResponseParams(JSAny _) implements JSAny {
  external bool? get showBalanceChanges;
  external set showBalanceChanges(bool? _);
  external bool? get showEffects;
  external set showEffects(bool? _);
  external bool? get showEvents;
  external set showEvents(bool? _);
  external bool? get showInput;
  external set showInput(bool? _);
  external bool? get showObjectChanges;
  external set showObjectChanges(bool? _);
  external bool? get showRawEffects;
  external set showRawEffects(bool? _);
  external bool? get showRawInput;
  external set showRawInput(bool? _);

  JSSuiTransactionBlockResponseParams clone() {
    return JSSuiTransactionBlockResponseParams(JSObject())
      ..showBalanceChanges = showBalanceChanges
      ..showEffects = showEffects
      ..showEvents = showEvents
      ..showInput = showInput
      ..showObjectChanges = showObjectChanges
      ..showRawEffects = showRawEffects
      ..showRawInput = showRawInput;
  }
}
extension type JSSuiSignOrExcuteTransactionParams(JSAny _) implements JSAny {
  external String? get chain;
  external JSAny? get account;
  external JSAny? get address;
  external JSSuiSignTransactionV2? get transaction;
  external JSSuiSignTransactionV1? get transactionBlock;
  external String? get requestType;
  external JSSuiTransactionBlockResponseParams? get options;

  Future<JSSuiSignTransactionWalletRequest> toRequest() async {
    try {
      if (transaction != null) {
        JSString transactionJson;
        if (transaction.isA<JSString>()) {
          transactionJson = transaction as JSString;
        } else {
          final json = (await transaction!.toJSON().toDart).toDart;
          transactionJson = StringUtils.decode(StringUtils.encode(json),
                  encoding: StringEncoding.base64)
              .toJS;
        }
        return JSSuiSignTransactionWalletRequest(JSObject())
          ..chain = chain
          ..account = account ?? address
          ..transaction = transactionJson
          ..requestType = requestType
          ..options = options?.clone();
      }
      if (transactionBlock != null) {
        JSString? transactionJson;
        if (transactionBlock.isA<JSString>()) {
          transactionJson = transactionBlock as JSString;
        } else if (transactionBlock?.blockData.isA<JSString>() ?? false) {
          transactionJson = transactionBlock!.blockData as JSString;
        } else {
          transactionJson = StringUtils.decode(
                  StringUtils.encode(jsJson.stringify(transactionBlock!.blockData)),
                  encoding: StringEncoding.base64)
              .toJS;
        }

        return JSSuiSignTransactionWalletRequest(JSObject())
          ..chain = chain
          ..account = account ?? address
          ..transaction = transactionJson
          ..requestType = requestType
          ..options = options?.clone();
      }
    } catch (_) {}
    throw SuiJSConstant.invalidTransaction;
  }
}
extension type JSSuiSignTransactionWalletRequest(JSAny _) implements JSAny {
  external String? get chain;
  external set chain(String? _);
  external JSAny? get account;
  external set account(JSAny? _);
  external JSString get transaction;
  external set transaction(JSString _);
  external String? get requestType;
  external set requestType(String? _);
  external JSSuiTransactionBlockResponseParams? get options;
  external set options(JSSuiTransactionBlockResponseParams? _);
  static const List<String> properties = ["chain", "account", "transaction"];
}

extension type JSSuiSignTransactionResponse(JSAny _) implements JSAny {
  factory JSSuiSignTransactionResponse.setup(
      {required String bytes, required String signature}) {
    return JSSuiSignTransactionResponse(JSObject())
      ..bytes = bytes
      ..signature = signature;
  }
  external set bytes(String _);
  external set signature(String _);
}
extension type JSSuiSignTransactionBlockResponse(JSAny _) implements JSAny {
  factory JSSuiSignTransactionBlockResponse.setup(
      {required String transactionBlockBytes, required String signature}) {
    return JSSuiSignTransactionBlockResponse(JSObject())
      ..transactionBlockBytes = transactionBlockBytes
      ..signature = signature;
  }
  external set transactionBlockBytes(String _);
  external set signature(String _);
}
extension type JSSuiSignAndExecuteTransactionResponse(JSAny _) implements JSAny {
  factory JSSuiSignAndExecuteTransactionResponse.setup(
      {required String digest, required String effects}) {
    return JSSuiSignAndExecuteTransactionResponse(JSObject())
      ..digest = digest
      ..effects = effects;
  }
  external set digest(String _);
  external set effects(String _);
}
extension type JSSuiSignAndExecuteTransactionBlockResponse(JSAny _) implements JSAny {
  factory JSSuiSignAndExecuteTransactionBlockResponse.setup(
      {required String digest, required String effects}) {
    return JSSuiSignAndExecuteTransactionBlockResponse(JSObject())..digest = digest;
  }
  external set digest(String _);
}
extension type JSSuiSignMessageParams(JSAny _) implements JSAny {
  external APPJSUint8Array get message;
  external JSSuiWalletAccount get account;
  static List<String> properties = ['message', 'account'];
}
extension type JSSuiSignMessageResponse(JSAny _) implements JSAny {
  factory JSSuiSignMessageResponse.setup(
      {required String messageBytes, required String signature}) {
    return JSSuiSignMessageResponse(JSObject())
      ..messageBytes = messageBytes
      ..signature = signature;
  }
  external set messageBytes(String _);
  external set signature(String _);
}
extension type JSSuiSignPrsonalMessageResponse(JSAny _) implements JSAny {
  factory JSSuiSignPrsonalMessageResponse.setup(
      {required String bytes, required String signature}) {
    return JSSuiSignPrsonalMessageResponse(JSObject())
      ..bytes = bytes
      ..signature = signature;
  }
  external set bytes(String _);
  external set signature(String _);
}
@JS()
extension type JSSuiWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSSuiWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSSuiWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
