import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/ton.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class TonWalletConnectAddress extends WalletConnectAddress {
  final List<int> walletStateInit;
  TonWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required List<int> walletStateInit})
      : walletStateInit = walletStateInit.asImmutableBytes;
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "walletStateInit":
          StringUtils.decode(walletStateInit, encoding: StringEncoding.base64),
    }.withoutNullValue;
  }
}

class TonWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<TonAddress,
    Web3TonChainAccount, TonWalletConnectAddress, Web3ChainDefaultIdnetifier> {
  const TonWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class TonWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    TonAddress,
    Web3TonChainAccount,
    TonWalletConnectAddress,
    Web3ChainDefaultIdnetifier,
    TonWeb3WalletConnectStateAddress> {
  TonWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory TonWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return TonWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory TonWeb3WalletConnectStateAccount(Web3TonChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return TonWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};

    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return TonWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: TonWalletConnectAddress(
              address: e.addressStr,
              publicKey: e.publicKey,
              walletStateInit: e.accountState,
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return TonWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<TonWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : TonWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: TonWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    walletStateInit: defaultAddress.accountState,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class TonWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        TonAddress,
        Web3TonChainAccount,
        TonWalletConnectAddress,
        Web3ChainDefaultIdnetifier,
        TonWeb3WalletConnectStateAddress,
        TonWeb3WalletConnectStateAccount>
    with
        TonWeb3StateHandler<
            TonWalletConnectAddress,
            TonWeb3WalletConnectStateAddress,
            TonWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  TonWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  TonWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return TonWeb3WalletConnectStateAccount.init();
    }
    return TonWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3TonRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3TonRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        final result = response.resultAs<Web3TonSendTransactionResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());

      case Web3TonRequestMethods.signMessage:
        final result = response.resultAs<Web3TonSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}
