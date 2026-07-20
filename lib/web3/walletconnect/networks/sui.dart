import 'package:on_chain/sui/src/address/address/address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/sui.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class SuiWalletConnectAddress extends WalletConnectAddress {
  final int signingScheme;
  SuiWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required this.signingScheme});
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "signingScheme": signingScheme,
    }.withoutNullValue;
  }
}

class SuiWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<SuiAddress,
    Web3SuiChainAccount, SuiWalletConnectAddress, Web3ChainDefaultIdnetifier> {
  const SuiWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class SuiWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    SuiAddress,
    Web3SuiChainAccount,
    SuiWalletConnectAddress,
    Web3ChainDefaultIdnetifier,
    SuiWeb3WalletConnectStateAddress> {
  SuiWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory SuiWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return SuiWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory SuiWeb3WalletConnectStateAccount(Web3SuiChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return SuiWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return SuiWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: SuiWalletConnectAddress(
              address: e.addressStr,
              publicKey: e.publicKey,
              signingScheme: e.signingScheme,
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return SuiWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<SuiWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : SuiWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: SuiWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    signingScheme: defaultAddress.signingScheme,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class SuiWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        SuiAddress,
        Web3SuiChainAccount,
        SuiWalletConnectAddress,
        Web3ChainDefaultIdnetifier,
        SuiWeb3WalletConnectStateAddress,
        SuiWeb3WalletConnectStateAccount>
    with
        SuiWeb3StateHandler<
            SuiWalletConnectAddress,
            SuiWeb3WalletConnectStateAddress,
            SuiWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  SuiWeb3WalletConnectStateHandler({required super.sendInternalMessage});
  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  SuiWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return SuiWeb3WalletConnectStateAccount.init();
    }
    return SuiWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3SuiRequestMethods.fromName(message.method);
    switch (method) {
      case Web3SuiRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3SuiRequestMethods.signPersonalMessage:
      case Web3SuiRequestMethods.signMessage:
        final signature = response.resultAs<Web3SuiSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: signature.toWalletConnectJson());
      case Web3SuiRequestMethods.signTransaction:
      case Web3SuiRequestMethods.signAndExecuteTransaction:
        final signature = response.resultAs<Web3SuiSignOrExcuteTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: signature.toWalletConnectJson());
      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
