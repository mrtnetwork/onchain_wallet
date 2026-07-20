import 'dart:js_interop';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import '../../models/models/exception.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../models/models/requests.dart';
import '../../utils/utils.dart';
import 'wallet.dart';

abstract class Web3JSStateAddress<
        NETWORKADDRESS extends IAddress,
        CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
        JSACCOUNT extends JSWalletStandardAccount,
        CHAIN extends Web3ChainIdnetifier>
    extends Web3StateAddress<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN> {
  const Web3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
  @override
  String get addressStr => jsAccount.address;
}

abstract class Web3JSStateAccount<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    JSACCOUNT extends JSWalletStandardAccount,
    CHAIN extends Web3ChainIdnetifier,
    STATEADDRESS extends Web3JSStateAddress<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT,
        CHAIN>> extends Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN,
    STATEADDRESS> {
  Web3JSStateAccount(
      {required super.state,
      required super.accounts,
      required super.chains,
      required super.defaultAccount,
      required super.defaultChain});

  bool jsAccountHasPermission(JSACCOUNT address) {
    return accounts.any((e) => e.jsAccount.address == address.address);
  }

  CHAINACCOUNT getJsAddressChainAccountOrThrow(JSAny? address, {CHAIN? network}) {
    if (address != null) {
      final jsAccount =
          JSOBJ.as<JSWalletStandardAccount>(object: address, keys: ['address']);
      String? addr = jsAccount?.address;
      if (jsAccount != null) {
        final chain = jsAccount.chain;
        if (chain == null) {
          throw Web3RequestExceptionConst.invalidRequestStateAccount;
        }
        if (network != null && chain != network) {
          throw Web3RequestExceptionConst.missingPermission;
        }
        final account = accounts
            .firstWhere(
                (e) =>
                    e.chainaccount.addressStr == jsAccount.address &&
                    e.networkIdentifier.isChain(chain),
                orElse: () => throw Web3RequestExceptionConst.missingPermission)
            .chainaccount;

        return account;
      } else {
        if (address.isA<JSString>()) {
          addr = (address as JSString).toDart;
        }
      }
      Iterable<STATEADDRESS> existsAccount =
          accounts.where((e) => e.chainaccount.addressStr == addr);
      if (network != null) {
        existsAccount = existsAccount.where((e) => e.networkIdentifier.id == network.id);
      }
      if (existsAccount.length == 1) {
        return existsAccount.first.chainaccount;
      }
    }
    throw Web3RequestExceptionConst.missingPermission;
  }

  @override
  Web3StateProtocol get protocol => Web3StateProtocol.web;
}

abstract class Web3JSStateHandler<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    JSACCOUNT extends JSWalletStandardAccount,
    CHAIN extends Web3ChainIdnetifier,
    STATEADDRESS extends Web3JSStateAddress<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT,
        CHAIN>,
    STATE extends Web3JSStateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN,
        STATEADDRESS>> extends Web3StateHandler<
    NETWORKADDRESS,
    CHAINACCOUNT,
    JSACCOUNT,
    CHAIN,
    STATEADDRESS,
    STATE,
    WalletMessageResponse,
    Web3JsClientRequest,
    JSWalletNetworkEvent> {
  late STATE _state = createState(null, null);
  final SendMessageToClient sendMessageToClient;
  Web3JSStateHandler(
      {required this.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<WalletMessageResponse> onConnectResponse(Web3JsClientRequest? message) async {
    Web3ChainIdnetifier? chain;
    final state = await getState();
    final error =
        Web3RequestExceptionConst.rejectedByUser.toResponseMessage().toWalletError();
    if (message != null) {
      final chainId = message.requestParams.elementAtOrNull(0);
      if (chainId != null) {
        chain = state.chains.firstWhereOrNull((e) => e.isChain(chainId.toString()));
      }
    }
    switch (message?.source) {
      case null:
      case Web3RequestSource.walletStandard:
        List<Web3JSStateAddress> accounts = state.accounts;
        if (chain != null) {
          accounts = accounts.where((e) => e.networkIdentifier == chain).toList();
        }
        if (accounts.isEmpty) {
          return WalletMessageResponse.fail(error);
        }
        return WalletMessageResponse.success(
            JSWalletStandardConnect.setup(accounts.map((e) => e.jsAccount).toList()));

      case Web3RequestSource.injected:
        List<Web3JSStateAddress> accounts = state.networkAccounts;
        if (!state.hasChainAccount) {
          return WalletMessageResponse.fail(error);
        }
        if (chain == null || chain == state.defaultChain) {
          return WalletMessageResponse.success(
              accounts.map((e) => e.addressStr).toList().toJS);
        }
        return WalletMessageResponse.fail(error);

      case Web3RequestSource.walletConnect:
        return WalletMessageResponse.fail(
            Web3RequestExceptionConst.internalErr("onConnectResponse")
                .toResponseMessage()
                .toWalletError());
    }
  }

  @override
  JSWalletNetworkEvent createStateEvent(
      {required STATE previousState,
      required STATE currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool accountsChanged,
      required bool networksChanged}) {
    List<JSNetworkEventType> events = [
      if (networksChanged || accountsChanged) JSNetworkEventType.change,
      if (networkChanged) JSNetworkEventType.defaultChainChanged,
      if (networkAccountsChanged) ...[
        JSNetworkEventType.defaultAccountChanged,
        JSNetworkEventType.networkAccountsChanged,
      ],
    ];
    return JSWalletNetworkEvent(
        events: events,
        change: JSWalletStandardChange.setup(
            accounts: accountsChanged ? currentState.stateAccounts : null,
            chains: networksChanged
                ? currentState.chains.map((e) => e.wsIdentifier).toList()
                : null),
        networkAccounts: networkAccountsChanged
            ? JSWalletConnectEvent.setup(currentState.defaultStateAccounts)
            : null,
        account: networkAccountsChanged ? currentState.defaultAccount?.jsAccount : null);
  }

  JSWalletNetworkEvent _createStateEvent(STATE other, STATE currentState) {
    final stateChanged = currentState.stateChanged(other);
    return createStateEvent(
        previousState: other,
        currentState: currentState,
        networksChanged: stateChanged || currentState.networksChanged(other),
        networkAccountsChanged: stateChanged || currentState.networkAccountChanged(other),
        networkChanged: stateChanged || currentState.networkChanged(other),
        accountsChanged: stateChanged || currentState.accountsChanged(other));
  }

  @override
  Future<STATE> getState() async {
    return await lock.run(() {
      return _state;
    });
  }

  @override
  Future<WalletMessageResponse> finalizeError(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3ExceptionMessage error}) async {
    return WalletMessageResponse.fail(error.toWalletError());
  }

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    return WalletMessageResponse.success(response.result.jsify());
  }

  @override
  Future<JSWalletNetworkEvent> initChain(
      Web3APPData? authenticated, AppContext? context) async {
    return await lock.run(() async {
      final currentState = _state;
      final state = createState(authenticated, context);
      final event = _createStateEvent(currentState, state);
      _state = state;
      return event;
    });
  }

  @override
  Future<JSWalletNetworkEvent?> createEvent(Web3NetworkEvent event) async {
    final state = await getState();
    switch (event) {
      case Web3NetworkEvent.change:
        return JSWalletNetworkEvent(
          events: [JSNetworkEventType.change],
          change: JSWalletStandardChange.setup(
              accounts: state.stateAccounts,
              chains: state.chains.map((e) => e.wsIdentifier).toList()),
        );
      case Web3NetworkEvent.accountsChanged:
        return JSWalletNetworkEvent(
            events: [
              JSNetworkEventType.defaultAccountChanged,
              JSNetworkEventType.networkAccountsChanged
            ],
            account: state.defaultAccount?.jsAccount,
            networkAccounts: JSWalletConnectEvent.setup(state.defaultStateAccounts));
      default:
        break;
    }
    return null;
  }

  @override
  Future<void> event(Web3NetworkEvent event) async {
    final e = await createEvent(event);
    if (e == null) return;
    sendMessageToClient(WalletMessageEvent.build(data: e), jsNetworkType);
  }

  late final JSClientType jsNetworkType = JSClientType.fromNetworkName(networkType.name);
}

class Web3JsClientRequest extends Web3ClientRequest {
  final PageMessageRequest request;
  const Web3JsClientRequest._({required this.request, required this.requestParams});
  factory Web3JsClientRequest(PageMessageRequest request) {
    final params = request.dartParams.cast<Object?>();
    return Web3JsClientRequest._(request: request, requestParams: params);
  }
  @override
  final List<Object?> requestParams;

  @override
  String get method => request.method;

  @override
  Map<String, dynamic> paramsAsMap(
      {Web3RequestMethods? method, List<String> keys = const []}) {
    return Web3ValidatorUtils.parseParams2(() {
      final param = tryObjectAsMap(request.elementAs(0));
      if (param == null) return null;
      for (final i in keys) {
        if (!param.containsKey(i)) return null;
      }
      return param;
    }, error: Web3RequestExceptionConst.invalidMapParameters(keys: keys));
  }

  @override
  List<int> objectAsBytes({
    required Object? object,
    required String name,
    Web3RequestException? error,
    required List<StringEncoding> encoding,
  }) {
    // ignore: invalid_runtime_check_with_js_interop_types
    if (object is JSAny) {
      final List<int>? bytes = Web3ValidatorUtils.parseParams2(() {
        final param = JSOBJ.as<APPJSUint8Array>(object: object, keys: ["slice"]);
        if (param != null) {
          return param.toBytes();
        }
        return null;
      },
          errorOnNull: false,
          error: error ??
              Web3RequestExceptionConst.invalidBytesArgrument2(
                  arg: name, encoding: encoding));
      if (bytes != null) return bytes;
      return super.objectAsBytes(
          object: object.dartify(), name: name, error: error, encoding: encoding);
    }
    return super
        .objectAsBytes(object: object, name: name, error: error, encoding: encoding);
  }

  @override
  Map<String, dynamic> objectAsMap(
      {required Object? object,
      required String name,
      Web3RequestException? error,
      List<String> keys = const []}) {
    // ignore: invalid_runtime_check_with_js_interop_types
    if (object is JSAny) {
      final result = JsUtils.toDartMap(object);
      if (result == null || !keys.every((e) => result.containsKey(e))) {
        throw error ??
            Web3RequestExceptionConst.invalidMapArguments(name: name, keys: keys);
      }
      return result;
    }

    return super.objectAsMap(object: object, name: name, error: error, keys: keys);
  }

  @override
  List<Map<String, dynamic>> objectAsListOfMap(
      {required Object? object, required String name, Web3RequestException? error}) {
    // ignore: invalid_runtime_check_with_js_interop_types
    if (object is JSAny) {
      final result = JsUtils.toListOfMap(object);
      if (result == null) {
        throw error ?? Web3RequestExceptionConst.invalidListArgument(name);
      }
      return result;
    }
    return super.objectAsListOfMap(object: object, name: name, error: error);
  }

  @override
  Web3RequestSource get source {
    if (request.isWalletStandard) return Web3RequestSource.walletStandard;
    return Web3RequestSource.injected;
  }

  @override
  String? tryElementAsString(int index) {
    try {
      final elem = request.params?[index];
      if (elem.isA<JSString>()) {
        return (elem as JSString).toDart;
      }
    } catch (_) {}
    return null;
  }
}
