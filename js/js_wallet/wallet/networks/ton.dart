import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/ton.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../models/models.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class TonWeb3JSStateAddress extends Web3JSStateAddress<TonAddress, Web3TonChainAccount,
    JSTonWalletAccount, Web3ChainDefaultIdnetifier> {
  const TonWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class TonWeb3JSStateAccount extends Web3JSStateAccount<TonAddress, Web3TonChainAccount,
    JSTonWalletAccount, Web3ChainDefaultIdnetifier, TonWeb3JSStateAddress> {
  TonWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory TonWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return TonWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory TonWeb3JSStateAccount(Web3TonChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return TonWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return TonWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSTonWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              walletStateInit: e.accountState,
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return TonWeb3JSStateAccount._(
        accounts: accounts.whereType<TonWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : TonWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSTonWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    walletStateInit: defaultAddress.accountState,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class TonWeb3JSStateHandler extends Web3JSStateHandler<
        TonAddress,
        Web3TonChainAccount,
        JSTonWalletAccount,
        Web3ChainDefaultIdnetifier,
        TonWeb3JSStateAddress,
        TonWeb3JSStateAccount>
    with
        TonWeb3StateHandler<
            JSTonWalletAccount,
            TonWeb3JSStateAddress,
            TonWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  TonWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final method = Web3TonRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3TonRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        return toSignTransactionRequest(params: params, state: state, method: method!);
      case Web3TonRequestMethods.signMessage:
        final signMessage =
            toSignMessageRequest(params: params, state: state, method: method!);
        return signMessage;
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }

  @override
  void onRequestDone(Web3JsClientRequest message) {}

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3TonRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3TonRequestMethods.signMessage:
        final signature =
            Web3TonSignMessageResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(
            JSTonSignMessageResponse.setup(signature.signature));
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        final r =
            Web3TonSendTransactionResponse.deserialize(bytes: response.resultAsList());
        final txHash = r.txHash;
        if (txHash == null) {
          return WalletMessageResponse.success(
              JSTonSignTransactionResponse.setup(r.message));
        }
        return WalletMessageResponse.success(
            JSTonSendTransactionResponse.setup(boc: r.message, txId: txHash));
      case Web3TonRequestMethods.requestAccounts:
        return onConnectResponse(message);
      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  TonWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return TonWeb3JSStateAccount.init();
    return TonWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
