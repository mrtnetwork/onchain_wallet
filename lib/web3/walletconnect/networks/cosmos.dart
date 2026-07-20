import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/cosmos.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class CosmosWalletConnectAddress extends WalletConnectAddress {
  final String typeUrl;
  final String algo;
  CosmosWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required this.typeUrl,
      required this.algo});

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "typeUrl": typeUrl,
      "algo": algo,
      "pubkey": BytesUtils.tryToHexString(publicKey, prefix: "0x"),
    }.withoutNullValue;
  }
}

class CosmosWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    CosmosBaseAddress,
    Web3CosmosChainAccount,
    CosmosWalletConnectAddress,
    Web3CosmoshainIdnetifier> {
  const CosmosWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class CosmosWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    CosmosBaseAddress,
    Web3CosmosChainAccount,
    CosmosWalletConnectAddress,
    Web3CosmoshainIdnetifier,
    CosmosWeb3WalletConnectStateAddress> {
  CosmosWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });

  bool chainExist(String chainId) {
    return chains.any((e) => e.chainId == chainId);
  }

  List<CosmosWalletConnectAddress> getChainIdJsAccounts(String chainId) {
    final network = chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return accounts
        .where((e) => e.networkIdentifier == network)
        .map((e) => e.jsAccount)
        .toList();
  }

  factory CosmosWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return CosmosWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory CosmosWeb3WalletConnectStateAccount(
      Web3CosmosChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return CosmosWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3CosmoshainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return CosmosWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: CosmosWalletConnectAddress(
              address: e.addressStr,
              publicKey: e.publicKey,
              algo: e.algo.name,
              typeUrl: e.algo.getPublicKeyTypeUrl(),
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return CosmosWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<CosmosWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : CosmosWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: CosmosWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    typeUrl: defaultAddress.algo.getPublicKeyTypeUrl(),
                    algo: defaultAddress.algo.name,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class CosmosWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        CosmosBaseAddress,
        Web3CosmosChainAccount,
        CosmosWalletConnectAddress,
        Web3CosmoshainIdnetifier,
        CosmosWeb3WalletConnectStateAddress,
        CosmosWeb3WalletConnectStateAccount>
    with
        CosmosWeb3StateHandler<
            CosmosWalletConnectAddress,
            CosmosWeb3WalletConnectStateAddress,
            CosmosWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  CosmosWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3CosmoshainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  CosmosWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return CosmosWeb3WalletConnectStateAccount.init();
    }
    return CosmosWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3CosmosRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3CosmosRequestMethods.signMessage:
        final signature = response.resultAs<Web3CosmosSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: signature.toWalletConnectJson());
      case Web3CosmosRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());

      case Web3CosmosRequestMethods.signTransactionAmino:
      case Web3CosmosRequestMethods.signTransactionDirect:
        final result = response.resultAs<Web3CosmosSignTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      default:
        return super
            .finalizeWalletResponse(message: message, params: params, response: response);
    }
  }
}
