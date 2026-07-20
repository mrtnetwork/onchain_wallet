import 'package:on_chain/ethereum/src/address/evm_address.dart';
import 'package:on_chain/ethereum/src/rpc/core/methods.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ethereum/client/ethereum.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/etherum.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class EthereumWalletConnectAddress extends WalletConnectAddress {
  EthereumWalletConnectAddress(
      {required super.address, required super.chain, required super.publicKey});
}

class WalletConnectEthereumEIPChainChanged extends WalletConnectEvent {
  final String chainId;
  final String netVersion;
  const WalletConnectEthereumEIPChainChanged(
      {required this.chainId, required this.netVersion, required super.chainIds});

  @override
  List<WCActionSessionEvent> buildEvent() {
    final param = WCSessionEvent(name: Web3NetworkEvent.chainChanged.name, data: chainId);
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class WalletConnectEthereumEIPAccountChanged extends WalletConnectEvent {
  final List<String> addresses;

  const WalletConnectEthereumEIPAccountChanged(
      {required this.addresses, required super.chainIds});
  @override
  List<WCActionSessionEvent> buildEvent() {
    final param =
        WCSessionEvent(name: Web3NetworkEvent.accountsChanged.name, data: addresses);
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class WalletConnectEthereumEIPProviderRpcError extends WalletConnectEvent {
  final String message;
  final int? code;
  final dynamic data;
  const WalletConnectEthereumEIPProviderRpcError(
      {required this.message, required this.code, this.data, required super.chainIds});
  @override
  List<WCActionSessionEvent> buildEvent() {
    final param = WCSessionEvent(name: Web3NetworkEvent.disconnect.name, data: {
      "message": message,
      if (code != null) "code": code,
      if (data != null) "data": data
    });
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class EthereumWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    ETHAddress,
    Web3EthereumChainAccount,
    EthereumWalletConnectAddress,
    Web3EthereumChainIdnetifier> {
  const EthereumWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class EthereumWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    ETHAddress,
    Web3EthereumChainAccount,
    EthereumWalletConnectAddress,
    Web3EthereumChainIdnetifier,
    EthereumWeb3WalletConnectStateAddress> {
  final EthereumClient? client;

  bool chainExist(BigInt chainId) {
    return chains.any((e) => e.chainId == chainId);
  }

  Web3EthereumChainIdnetifier getChainFromChainId(BigInt chainId) {
    return chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
  }

  EthereumWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    this.client,
    super.defaultAccount,
    super.defaultChain,
  });
  factory EthereumWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return EthereumWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory EthereumWeb3WalletConnectStateAccount(
      Web3EthereumChainAuthenticated? authenticated, AppContext? context) {
    if (authenticated == null) {
      return EthereumWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3EthereumChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return EthereumWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: EthereumWalletConnectAddress(
              address: e.addressStr, publicKey: e.publicKey, chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    final provider = authenticated.serviceIdentifier;
    return EthereumWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<EthereumWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        client: provider == null || context == null
            ? null
            : EthereumClient.fromProviders(provider: provider, netApi: context.netApi),
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : EthereumWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: EthereumWalletConnectAddress(
                    publicKey: defaultAddress.publicKey,
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.caip2)));
  }
}

class EthereumWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        ETHAddress,
        Web3EthereumChainAccount,
        EthereumWalletConnectAddress,
        Web3EthereumChainIdnetifier,
        EthereumWeb3WalletConnectStateAddress,
        EthereumWeb3WalletConnectStateAccount>
    with
        EthereumWeb3StateHandler<
            EthereumWalletConnectAddress,
            EthereumWeb3WalletConnectStateAddress,
            EthereumWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  EthereumWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  EthereumWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return EthereumWeb3WalletConnectStateAccount.init();
    }
    return EthereumWeb3WalletConnectStateAccount(
        authenticated.getAuth(networkType), context);
  }

  @override
  WalletConnectClientEvent createStateEvent(
      {required EthereumWeb3WalletConnectStateAccount previousState,
      required EthereumWeb3WalletConnectStateAccount currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool accountsChanged,
      required bool networksChanged}) {
    final event = super.createStateEvent(
        previousState: previousState,
        currentState: currentState,
        networksChanged: networksChanged,
        networkAccountsChanged: networkAccountsChanged,
        networkChanged: networkChanged,
        accountsChanged: accountsChanged);
    List<WalletConnectEvent> events = [...event.events];
    if (networkAccountsChanged) {
      final chain = currentState.defaultChain;
      final networkAccounts = WalletConnectEthereumEIPAccountChanged(
          addresses:
              currentState.networkAccounts.map((e) => e.jsAccount.address).toList(),
          chainIds: [if (chain != null) chain]);
      events.add(networkAccounts);
    }
    if (networkChanged) {
      previousState.client?.dispose();
      final chain = currentState.defaultChain;
      if (chain != null) {
        final chainChanged = WalletConnectEthereumEIPChainChanged(
            chainId: chain.chainId.toRadix16,
            netVersion: chain.chainId.toString(),
            chainIds: [chain]);
        events.add(chainChanged);
      }
      if (chain == null || currentState.client == null) {
        final error = Web3RequestExceptionConst.disconnectProvider;
        final disconnect = WalletConnectEthereumEIPProviderRpcError(
            message: error.message,
            code: error.type.code,
            chainIds: [
              if (previousState.defaultChain != null) previousState.defaultChain!
            ]);
        events.add(disconnect);
      }
    }
    return WalletConnectClientEvent(network: networkType, events: events);
  }

  Future<Web3MessageCore> rpcCall(
      {required WalletConnectNetworkRequest params,
      required EthereumWeb3WalletConnectStateAccount state,
      Web3EthereumChainIdnetifier? network}) async {
    if (!state.hasAccount || network == null || network != state.defaultChain) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final client = state.client;
    if (client == null) {
      throw Web3RequestExceptionConst.disconnectProvider;
    }
    final method = EthereumMethods.fromName(params.method);
    if (method == null || method == EthereumMethods.subscribe) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    final result =
        await client.dynamicCall(method: params.method, params: params.requestParams);
    return createResponse(result);
  }

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3EthereumChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    final method = Web3EthereumRequestMethods.fromName(message.method);
    if (method == null) {
      return rpcCall(params: message, state: state, network: network);
    }
    return super.request(message, network: network);
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3EthereumRequestMethods.fromName(message.method);
    switch (method) {
      case Web3EthereumRequestMethods.sendTransaction:
      case Web3EthereumRequestMethods.typedData:
      case Web3EthereumRequestMethods.persoalSign:
      case Web3EthereumRequestMethods.ethSign:
        final signature = response.resultAsString();
        return WalletConnectWalletMessageResponse.success(data: signature);
      case Web3EthereumRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.address).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
