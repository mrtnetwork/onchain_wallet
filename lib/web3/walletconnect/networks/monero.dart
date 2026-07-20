import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/permission/permission.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/state/monero.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class MoneroWalletConnectAddress extends WalletConnectAddress {
  MoneroWalletConnectAddress(
      {required super.address, required super.chain, required super.publicKey});
}

class MoneroWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    MoneroAddress,
    Web3MoneroChainAccount,
    MoneroWalletConnectAddress,
    Web3MoneroChainIdnetifier> {
  const MoneroWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class MoneroWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    MoneroAddress,
    Web3MoneroChainAccount,
    MoneroWalletConnectAddress,
    Web3MoneroChainIdnetifier,
    MoneroWeb3WalletConnectStateAddress> {
  MoneroWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory MoneroWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return MoneroWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory MoneroWeb3WalletConnectStateAccount(
      Web3MoneroChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return MoneroWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return MoneroWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: MoneroWalletConnectAddress(
              address: e.addressStr, publicKey: e.publicKey, chain: network.caip2),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return MoneroWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<MoneroWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : MoneroWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: MoneroWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class MoneroWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        MoneroAddress,
        Web3MoneroChainAccount,
        MoneroWalletConnectAddress,
        Web3MoneroChainIdnetifier,
        MoneroWeb3WalletConnectStateAddress,
        MoneroWeb3WalletConnectStateAccount>
    with
        MoneroWeb3StateHandler<
            MoneroWalletConnectAddress,
            MoneroWeb3WalletConnectStateAddress,
            MoneroWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  MoneroWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3MoneroChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  MoneroWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return MoneroWeb3WalletConnectStateAccount.init();
    }
    return MoneroWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3MoneroRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3MoneroRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3MoneroRequestMethods.sendTransaction:
        final result = response.resultAs<Web3MoneroTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());

      case Web3MoneroRequestMethods.signMessage:
        final result = response.resultAs<Web3MoneroSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}
