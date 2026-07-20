import 'package:on_chain/solana/src/address/sol_address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/solana.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class SolanaWalletConnectAddress extends WalletConnectAddress {
  SolanaWalletConnectAddress(
      {required super.address, required super.chain, required super.publicKey});
}

class SolanaWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    SolAddress,
    Web3SolanaChainAccount,
    SolanaWalletConnectAddress,
    Web3ChainDefaultIdnetifier> {
  const SolanaWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class SolanaWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    SolAddress,
    Web3SolanaChainAccount,
    SolanaWalletConnectAddress,
    Web3ChainDefaultIdnetifier,
    SolanaWeb3WalletConnectStateAddress> {
  final String? applicationId;
  SolanaWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    this.applicationId,
    super.defaultAccount,
    super.defaultChain,
  });
  factory SolanaWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return SolanaWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory SolanaWeb3WalletConnectStateAccount(
      Web3SolanaChainAuthenticated? authenticated, String applicationId) {
    if (authenticated == null) {
      return SolanaWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return SolanaWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: SolanaWalletConnectAddress(
              address: e.addressStr,
              publicKey: e.address.toBytes(),
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return SolanaWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<SolanaWeb3WalletConnectStateAddress>().toList(),
        applicationId: applicationId,
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : SolanaWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: SolanaWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.address.toBytes(),
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class SolanaWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        SolAddress,
        Web3SolanaChainAccount,
        SolanaWalletConnectAddress,
        Web3ChainDefaultIdnetifier,
        SolanaWeb3WalletConnectStateAddress,
        SolanaWeb3WalletConnectStateAccount>
    with
        SolanaWeb3StateHandler<
            SolanaWalletConnectAddress,
            SolanaWeb3WalletConnectStateAddress,
            SolanaWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  SolanaWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  SolanaWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return SolanaWeb3WalletConnectStateAccount.init();
    }
    return SolanaWeb3WalletConnectStateAccount(
        authenticated.getAuth(networkType), authenticated.applicationId);
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3SolanaRequestMethods.fromName(message.method);
    switch (method) {
      case Web3SolanaRequestMethods.sendTransaction:
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.signAllTransactions:
        final signedTxs = response
            .resultAsList<Web3SolanaTransactionResponse>()
            .map((e) => e.toWalletConnectJson())
            .toList();
        return WalletConnectWalletMessageResponse.success(
            data: signedTxs.length == 1 ? signedTxs.first : signedTxs);
      case Web3SolanaRequestMethods.signIn:
      case Web3SolanaRequestMethods.signMessage:
        final signedMessages = response
            .resultAsList<Web3SolanaSignMessageResponse>()
            .map((e) => e.toWalletConnectJson())
            .toList();
        return WalletConnectWalletMessageResponse.success(
            data: signedMessages.length == 1 ? signedMessages.first : signedMessages);

      case Web3SolanaRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
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
