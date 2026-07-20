import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/state/ripple.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class XRPWalletConnectAddress extends WalletConnectAddress {
  XRPWalletConnectAddress(
      {required super.address, required super.chain, required super.publicKey});
}

class XRPWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    XRPBaseAddress,
    Web3XRPChainAccount,
    XRPWalletConnectAddress,
    Web3ChainDefaultIdnetifier> {
  const XRPWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class XRPWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    XRPBaseAddress,
    Web3XRPChainAccount,
    XRPWalletConnectAddress,
    Web3ChainDefaultIdnetifier,
    XRPWeb3WalletConnectStateAddress> {
  XRPWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory XRPWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return XRPWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory XRPWeb3WalletConnectStateAccount(Web3XRPChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return XRPWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return XRPWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: XRPWalletConnectAddress(
              address: e.addressStr, publicKey: e.publicKey, chain: network.caip2),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return XRPWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<XRPWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : XRPWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: XRPWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class XRPWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        XRPBaseAddress,
        Web3XRPChainAccount,
        XRPWalletConnectAddress,
        Web3ChainDefaultIdnetifier,
        XRPWeb3WalletConnectStateAddress,
        XRPWeb3WalletConnectStateAccount>
    with
        XRPWeb3StateHandler<
            XRPWalletConnectAddress,
            XRPWeb3WalletConnectStateAddress,
            XRPWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  XRPWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  XRPWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return XRPWeb3WalletConnectStateAccount.init();
    }
    return XRPWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3XRPRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3XRPRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3XRPRequestMethods.sendTransaction:
      case Web3XRPRequestMethods.signTransaction:
        final result = response.resultAs<Web3XRPTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());

      case Web3XRPRequestMethods.signMessage:
        final result = response.resultAs<Web3XRPSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}
