import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class StellarWalletConnectAddress extends WalletConnectAddress {
  StellarWalletConnectAddress(
      {required super.address, required super.chain, required super.publicKey});
}

class StellarWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    StellarAddress,
    Web3StellarChainAccount,
    StellarWalletConnectAddress,
    Web3ChainDefaultIdnetifier> {
  const StellarWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class StellarWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    StellarAddress,
    Web3StellarChainAccount,
    StellarWalletConnectAddress,
    Web3ChainDefaultIdnetifier,
    StellarWeb3WalletConnectStateAddress> {
  StellarWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory StellarWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return StellarWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory StellarWeb3WalletConnectStateAccount(
      Web3StellarChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return StellarWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return StellarWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: StellarWalletConnectAddress(
              address: e.addressStr, publicKey: e.publicKey, chain: network.caip2),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return StellarWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<StellarWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : StellarWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: StellarWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class StellarWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        StellarAddress,
        Web3StellarChainAccount,
        StellarWalletConnectAddress,
        Web3ChainDefaultIdnetifier,
        StellarWeb3WalletConnectStateAddress,
        StellarWeb3WalletConnectStateAccount>
    with
        StellarWeb3StateHandler<
            StellarWalletConnectAddress,
            StellarWeb3WalletConnectStateAddress,
            StellarWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  StellarWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  StellarWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return StellarWeb3WalletConnectStateAccount.init();
    }
    return StellarWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3StellarRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3StellarRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3StellarRequestMethods.sendTransaction:
      case Web3StellarRequestMethods.signTransaction:
        final result = response.resultAs<Web3StellarSendTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());

      case Web3StellarRequestMethods.signMessage:
        final result = response.resultAs<Web3StellarSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}
