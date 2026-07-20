import 'package:blockchain_utils/networks/types/address.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';

abstract class Web3WalletConnectStateAddress<
        NETWORKADDRESS extends IAddress,
        CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
        WCADDRESS extends WalletConnectAddress,
        NETWORK extends Web3ChainIdnetifier>
    extends Web3StateAddress<NETWORKADDRESS, CHAINACCOUNT, WCADDRESS, NETWORK> {
  const Web3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});

  String get caip10 => "${networkIdentifier.caip2}:${jsAccount.address}";

  @override
  String get addressStr => jsAccount.address;
}

abstract class Web3WalletConnectStateAccount<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    WCADDRESS extends WalletConnectAddress,
    CHAIN extends Web3ChainIdnetifier,
    STATEADDRESS extends Web3WalletConnectStateAddress<NETWORKADDRESS, CHAINACCOUNT,
        WCADDRESS, CHAIN>> extends Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT,
    WCADDRESS, CHAIN, STATEADDRESS> {
  Web3WalletConnectStateAccount(
      {required super.state,
      required super.accounts,
      required super.chains,
      required super.defaultAccount,
      required super.defaultChain});
  @override
  Web3StateProtocol get protocol => Web3StateProtocol.walletConnect;
}

abstract class Web3WalletConnectStateHandler<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    WCADDRESS extends WalletConnectAddress,
    CHAIN extends Web3ChainIdnetifier,
    STATEADDRESS extends Web3WalletConnectStateAddress<NETWORKADDRESS, CHAINACCOUNT,
        WCADDRESS, CHAIN>,
    STATE extends Web3WalletConnectStateAccount<NETWORKADDRESS, CHAINACCOUNT, WCADDRESS,
        CHAIN, STATEADDRESS>> extends Web3StateHandler<
    NETWORKADDRESS,
    CHAINACCOUNT,
    WCADDRESS,
    CHAIN,
    STATEADDRESS,
    STATE,
    WalletConnectWalletMessageResponse,
    WalletConnectNetworkRequest,
    WalletConnectClientEvent> {
  Web3WalletConnectStateHandler({required super.sendInternalMessage});

  late STATE _state = createState(null, null);

  Future<List<WCChainNamespace>> generateNamespace() async {
    final state = await getState();
    final namespace = WCChainNamespace(
        identifier: networkType.caip2,
        namespace: WCNamespace(
            chains: state.chains.map((e) => e.caip2).toList(),
            accounts: state.accounts.map((e) => e.caip10).toList(),
            methods: methods.expand((e) => e.walletConnectMethodNames).toList(),
            events: events.map((e) => e.name).toList()));
    return [namespace];
  }

  @override
  Future<WalletConnectWalletMessageResponse> onConnectResponse(
      WalletConnectNetworkRequest? message) {
    throw UnimplementedError();
  }

  @override
  Future<STATE> getState() async {
    return await lock.run(() {
      return _state;
    });
  }

  @override
  WalletConnectClientEvent createStateEvent(
      {required STATE previousState,
      required STATE currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool accountsChanged,
      required bool networksChanged}) {
    return WalletConnectClientEvent(
      network: networkType,
      events: [
        if (accountsChanged || networkAccountsChanged)
          WalletConnectStateChanges(
              accounts: accountsChanged ? currentState.accounts : null,
              chains: networksChanged ? currentState.chains : null,
              chainIds: currentState.chains
                  .where((e) => currentState.chainHasActiveAccount(e))
                  .toList()),
      ],
      // change: ChangeEvent(
      //     accounts: accountsChanged ? currentState.accounts : null,
      //     chain: networksChanged
      //         ? currentState.chains.map((e) => e.caip2).toList()
      //         : null),
      // networkAccounts: networkAccountsChanged
      //     ? WalletConnectNetworkAccountChange(currentState.networkAccounts)
      //     : null,
      // account: networkAccountsChanged ? currentState.defaultAccount : null,
    );
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeError(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3ExceptionMessage error}) async {
    return WalletConnectWalletMessageResponse.fail(error);
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    return WalletConnectWalletMessageResponse.success(data: response.result);
  }

  @override
  Future<WalletConnectClientEvent> initChain(
      Web3APPData authenticated, AppContext? context) async {
    return await lock.run(() async {
      final currentState = _state;
      final state = createState(authenticated, context);
      final event = _createStateEvent(currentState, state);
      _state = state;
      return event;
    });
  }

  WalletConnectClientEvent _createStateEvent(STATE other, STATE currentState) {
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
  Future<WalletConnectClientEvent?> createEvent(Web3NetworkEvent event) {
    throw WalletConnectClientEvent(network: networkType);
  }

  @override
  Future<void> event(Web3NetworkEvent event) {
    throw UnimplementedError();
  }
}

enum WalletConnectWalletMessageResponseType {
  success,
  failed;

  static WalletConnectWalletMessageResponseType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw Web3RequestExceptionConst.internalErr(
            "WalletConnectWalletMessageResponseType",
            details: {"name": name}));
  }
}

class WalletConnectWalletMessageResponse {
  final WalletConnectWalletMessageResponseType type;
  final Object? data;
  const WalletConnectWalletMessageResponse._({required this.type, required this.data});
  factory WalletConnectWalletMessageResponse.success({Object? data}) {
    return WalletConnectWalletMessageResponse._(
        type: WalletConnectWalletMessageResponseType.success, data: data);
  }
  factory WalletConnectWalletMessageResponse.fail(Web3ExceptionMessage error) {
    return WalletConnectWalletMessageResponse._(
        type: WalletConnectWalletMessageResponseType.failed, data: error);
  }
  @override
  String toString() {
    return "WalletConnectWalletMessageResponse {type: $type, data: $data}";
  }
}

class WalletConnectClientRequestParams {
  final BridgeEventWeb3SessionRequest request;
  final NetworkType network;
  String get chainId => request.request.chainId;
  String get method => request.request.request.method;
  dynamic get params => request.request.request.params;
  const WalletConnectClientRequestParams._(this.request, this.network);
  factory WalletConnectClientRequestParams(BridgeEventWeb3SessionRequest request) {
    final caip2 = request.request.chainId.split(":").first;
    final network = NetworkType.values.firstWhere((e) => e.caip2 == caip2,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return WalletConnectClientRequestParams._(request, network);
  }
}

class WalletConnectNetworkRequest extends Web3ClientRequest {
  @override
  final String method;
  final WalletConnectClientRequestParams? request;
  final String? wcRequestId;
  const WalletConnectNetworkRequest._(
      {required this.method,
      this.request,
      required this.requestParams,
      this.wcRequestId});
  factory WalletConnectNetworkRequest.network(
      {required WalletConnectClientRequestParams request, required String method}) {
    final param = request.params;
    List<Object?> params = [];
    if (param is List) {
      params = param.cast();
    } else if (param != null) {
      params = [param];
    }
    return WalletConnectNetworkRequest._(
        method: method,
        request: request,
        requestParams: params,
        wcRequestId: request.request.id.toString());
  }
  factory WalletConnectNetworkRequest.global(
      {required String method, List<String> chains = const [], String? wcRequestId}) {
    return WalletConnectNetworkRequest._(
        method: method,
        request: null,
        requestParams: [
          {"chains": chains}
        ],
        wcRequestId: wcRequestId);
  }
  @override
  final List<Object?> requestParams;

  @override
  Web3RequestSource get source => Web3RequestSource.walletConnect;
}

abstract class WalletConnectEvent {
  final List<Web3ChainIdnetifier> chainIds;
  const WalletConnectEvent({required this.chainIds});
  List<WCActionSessionEvent> buildEvent();
}

class WalletConnectStateChanges extends WalletConnectEvent {
  final List<Web3ChainIdnetifier>? chains;
  final List<Web3WalletConnectStateAddress>? accounts;
  const WalletConnectStateChanges(
      {required this.accounts, required this.chains, required super.chainIds});

  @override
  List<WCActionSessionEvent> buildEvent() {
    final param = WCSessionEvent(name: Web3NetworkEvent.change.name, data: {
      if (accounts != null) "accounts": accounts?.map((e) => e.caip10).toList(),
      if (chains != null) "chains": chains?.map((e) => e.caip2).toList()
    });
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class WalletConnectClientEvent {
  final NetworkType network;
  final List<WalletConnectEvent> events;
  WalletConnectClientEvent({this.events = const [], required this.network});

  List<WCActionSessionEvent> generateEvents() {
    return events.expand((e) => e.buildEvent()).toList();
  }
}
