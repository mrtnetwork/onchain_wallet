import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/zcash.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class ZcashWalletConnectAddress extends WalletConnectAddress {
  ZcashWalletConnectAddress(
      {required super.address, required super.chain, super.publicKey});
}

class ZcashWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    ZcashAddress,
    Web3ZcashChainAccount,
    ZcashWalletConnectAddress,
    Web3ZcashChainIdnetifier> {
  const ZcashWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class ZcashWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    ZcashAddress,
    Web3ZcashChainAccount,
    ZcashWalletConnectAddress,
    Web3ZcashChainIdnetifier,
    ZcashWeb3WalletConnectStateAddress> {
  ZcashWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory ZcashWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return ZcashWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory ZcashWeb3WalletConnectStateAccount(Web3ZcashChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return ZcashWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return ZcashWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount:
              ZcashWalletConnectAddress(address: e.addressStr, chain: network.caip2),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return ZcashWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<ZcashWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : ZcashWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: ZcashWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class ZcashWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        ZcashAddress,
        Web3ZcashChainAccount,
        ZcashWalletConnectAddress,
        Web3ZcashChainIdnetifier,
        ZcashWeb3WalletConnectStateAddress,
        ZcashWeb3WalletConnectStateAccount>
    with
        ZcashWeb3StateHandler<
            ZcashWalletConnectAddress,
            ZcashWeb3WalletConnectStateAddress,
            ZcashWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  ZcashWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ZcashChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  ZcashWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return ZcashWeb3WalletConnectStateAccount.init();
    }
    return ZcashWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3ZcashRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3ZcashRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3ZcashRequestMethods.sendTransaction:
        final result = response.resultAs<Web3ZcashTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());

      case Web3ZcashRequestMethods.signMessage:
        final result = response.resultAs<Web3ZcashSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}
