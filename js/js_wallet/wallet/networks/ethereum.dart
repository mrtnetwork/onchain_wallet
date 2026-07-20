import 'dart:js_interop';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'dart:async';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import '../../models/models.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../utils/utils/ethreum_js_provider.dart';
import '../core/network_handler.dart';

class EthereumWeb3JSStateAddress extends Web3JSStateAddress<ETHAddress,
    Web3EthereumChainAccount, JSSEthereumWalletAccount, Web3EthereumChainIdnetifier> {
  const EthereumWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class EthereumWeb3JSStateAccount extends Web3JSStateAccount<
    ETHAddress,
    Web3EthereumChainAccount,
    JSSEthereumWalletAccount,
    Web3EthereumChainIdnetifier,
    EthereumWeb3JSStateAddress> {
  final JSEthereumClient? client;

  bool chainExist(BigInt chainId) {
    return chains.any((e) => e.chainId == chainId);
  }

  Web3EthereumChainIdnetifier getChainFromChainId(BigInt chainId) {
    return chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
  }

  EthereumWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    this.client,
    super.defaultAccount,
    super.defaultChain,
  });
  factory EthereumWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return EthereumWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory EthereumWeb3JSStateAccount(
      Web3EthereumChainAuthenticated? authenticated, AppContext? context) {
    if (authenticated == null) {
      return EthereumWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3EthereumChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return EthereumWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSSEthereumWalletAccount.setup(
              address: e.addressStr, publicKey: e.publicKey, chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    final provider = authenticated.serviceIdentifier;
    return EthereumWeb3JSStateAccount._(
        accounts: accounts.whereType<EthereumWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        client: provider == null || context == null
            ? null
            : JSEthereumClient(provider: provider, context: context),
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : EthereumWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSSEthereumWalletAccount.setup(
                    publicKey: defaultAddress.publicKey,
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class EthereumWeb3JSStateHandler extends Web3JSStateHandler<
        ETHAddress,
        Web3EthereumChainAccount,
        JSSEthereumWalletAccount,
        Web3EthereumChainIdnetifier,
        EthereumWeb3JSStateAddress,
        EthereumWeb3JSStateAccount>
    with
        EthereumWeb3StateHandler<
            JSSEthereumWalletAccount,
            EthereumWeb3JSStateAddress,
            EthereumWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  EthereumWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  void _onSubscribe(Map<String, dynamic> result) {
    final event = JSWalletNetworkEvent(
        events: [JSNetworkEventType.message], message: result.jsify());
    sendMessageToClient(WalletMessageEvent.build(data: event),
        JSClientType.fromNetworkName(networkType.name));
  }

  @override
  JSWalletNetworkEvent createStateEvent(
      {required EthereumWeb3JSStateAccount previousState,
      required EthereumWeb3JSStateAccount currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool networksChanged,
      required bool accountsChanged}) {
    final event = super.createStateEvent(
        previousState: previousState,
        currentState: currentState,
        networksChanged: networksChanged,
        networkAccountsChanged: networkAccountsChanged,
        networkChanged: networkChanged,
        accountsChanged: accountsChanged);
    if (networkChanged) {
      previousState.client?.close();
      final chain = currentState.defaultChain;
      currentState.client?.addSubscriptionListener(_onSubscribe);
      if (chain != null) {
        event.chainChanged = JSEthereumEIPChainChanged(
            chainId: chain.chainId.toRadix16, netVersion: chain.chainId.toString());
      }
      if (chain == null || currentState.client == null) {
        final error = Web3RequestExceptionConst.disconnectProvider;
        event.disconnect =
            JSEthereumEIPProviderRpcError(message: error.message, code: error.code);
      }
    }
    return event;
  }

  @override
  Future<JSWalletNetworkEvent?> createEvent(Web3NetworkEvent event) async {
    final state = await getState();
    switch (event) {
      case Web3NetworkEvent.chainChanged:
      case Web3NetworkEvent.connect:
        final event =
            JSWalletNetworkEvent(events: [JSNetworkEventType.defaultChainChanged]);
        final chain = state.defaultChain;
        if (chain != null) {
          event.chainChanged = JSEthereumEIPChainChanged(
              chainId: chain.chainId.toRadix16, netVersion: chain.chainId.toString());
        }
        if (chain == null || state.client == null) {
          final error = Web3RequestExceptionConst.disconnectProvider;
          event.disconnect =
              JSEthereumEIPProviderRpcError(message: error.message, code: error.code);
        }
        return event;
      default:
        return super.createEvent(event);
    }
  }

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3EthereumChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3EthereumRequestMethods.fromName(params.request.method);
    if (method == null) return _rpcCall(params.request, state);
    switch (method) {
      case Web3EthereumRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3EthereumRequestMethods.switchEthereumChain:
        return toSwitchNetworkRequest(params: params, state: state, method: method);
      case Web3EthereumRequestMethods.persoalSign:
      case Web3EthereumRequestMethods.ethSign:
        return toPersonalSignRequest(
            params: params,
            state: state,
            method: method,
            network: params.request.isWalletStandard ? null : state.defaultChain);
      case Web3EthereumRequestMethods.addEthereumChain:
        return toAddNewChainRequest(params: params, state: state, method: method);
      case Web3EthereumRequestMethods.typedData:
        return toSignTypedDataRequest(params: params, state: state, method: method);
      case Web3EthereumRequestMethods.sendTransaction:
        return toTransactionRequest(
            params: params,
            state: state,
            network: params.request.isWalletStandard ? null : state.defaultChain,
            method: method);
      case Web3EthereumRequestMethods.ethAccounts:
        return createResponse(state.defaultAccountsAddresses);
      case Web3EthereumRequestMethods.ethChainId:
        return createResponse(state.defaultChainOrThrow.chainId.toRadix16);
      default:
        throw super.request(params, network: network);
    }
  }

  Future<Web3MessageCore> _rpcCall(
      PageMessageRequest params, EthereumWeb3JSStateAccount state) async {
    try {
      final client = state.client;
      if (client == null) {
        throw Web3RequestExceptionConst.disconnectProvider;
      }
      final method = EthereumMethods.fromName(params.method);
      if (method == null) {
        throw Web3RequestExceptionConst.methodDoesNotExist;
      }
      final result = await client.call(params.method, params.dartParams);
      return createResponse(result);
    } on APIError catch (e) {
      throw Web3RequestExceptionConst.fromException(e);
    }
  }

  @override
  void onRequestDone(Web3JsClientRequest message) {}

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3EthereumRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3EthereumRequestMethods.sendTransaction:
      case Web3EthereumRequestMethods.typedData:
      case Web3EthereumRequestMethods.persoalSign:
      case Web3EthereumRequestMethods.ethSign:
        final signature = response.resultAsString();
        return WalletMessageResponse.success(signature.toJS);
      case Web3EthereumRequestMethods.requestAccounts:
        return onConnectResponse(message);
      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  EthereumWeb3JSStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return EthereumWeb3JSStateAccount.init();
    }
    return EthereumWeb3JSStateAccount(authenticated.getAuth(networkType), context);
  }
}
