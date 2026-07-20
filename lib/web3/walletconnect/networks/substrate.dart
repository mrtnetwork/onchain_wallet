import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/substrate.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class SubstrateWalletConnectKnownMetadata {
  final String genesisHash;
  final int specVersion;
  final String identifier;
  const SubstrateWalletConnectKnownMetadata(
      {required this.genesisHash, required this.specVersion, required this.identifier});
  Map<String, dynamic> toWalletConnectJson() {
    return {
      "genesisHash": genesisHash,
      "specVersion": specVersion,
      "identifier": identifier
    };
  }
}

class SubstrateWalletConnectAddress extends WalletConnectAddress {
  final String genesisHash;
  SubstrateWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required this.genesisHash});

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "genesisHash": genesisHash,
    }.withoutNullValue;
  }
}

class SubstrateWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    BaseSubstrateAddress,
    Web3SubstrateChainAccount,
    SubstrateWalletConnectAddress,
    Web3SubstrateChainIdnetifier> {
  const SubstrateWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class SubstrateWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    BaseSubstrateAddress,
    Web3SubstrateChainAccount,
    SubstrateWalletConnectAddress,
    Web3SubstrateChainIdnetifier,
    SubstrateWeb3WalletConnectStateAddress> {
  List<SubstrateWalletConnectKnownMetadata> get knownMetadatas => chains
      .map((e) => SubstrateWalletConnectKnownMetadata(
          genesisHash: e.genesisHash,
          identifier: e.wsIdentifier,
          specVersion: e.specVersion))
      .toList();

  SubstrateWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory SubstrateWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return SubstrateWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory SubstrateWeb3WalletConnectStateAccount(
      Web3SubstrateChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return SubstrateWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3SubstrateChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return SubstrateWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: SubstrateWalletConnectAddress(
              address: e.addressStr,
              publicKey: e.publicKey,
              genesisHash: network.genesisHash,
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return SubstrateWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<SubstrateWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : SubstrateWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: SubstrateWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    genesisHash: networks[defaultAddress.id]!.genesisHash,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class SubstrateWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        BaseSubstrateAddress,
        Web3SubstrateChainAccount,
        SubstrateWalletConnectAddress,
        Web3SubstrateChainIdnetifier,
        SubstrateWeb3WalletConnectStateAddress,
        SubstrateWeb3WalletConnectStateAccount>
    with
        SubstrateWeb3StateHandler<
            SubstrateWalletConnectAddress,
            SubstrateWeb3WalletConnectStateAddress,
            SubstrateWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  SubstrateWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3SubstrateChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  SubstrateWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return SubstrateWeb3WalletConnectStateAccount.init();
    }
    return SubstrateWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3SubstrateRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3SubstrateRequestMethods.addSubstrateChain:
        return WalletConnectWalletMessageResponse.success(data: true);
      case Web3SubstrateRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3SubstrateRequestMethods.knownMetadata:
        return WalletConnectWalletMessageResponse.success(
            data: state.knownMetadatas.map((e) => e.toWalletConnectJson()).toList());
      case Web3SubstrateRequestMethods.signMessage:
      case Web3SubstrateRequestMethods.signTransaction:
        final msg = response.resultAs<Web3SubstrateSendTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: msg.toWalletConnectJson());
      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
