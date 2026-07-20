import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/state/zcash.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:zcash_dart/zcash.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../models/models/networks/zcash.dart';
import '../../models/models/requests.dart';
import '../core/network_handler.dart';

class ZcashWeb3JSStateAddress extends Web3JSStateAddress<ZcashAddress,
    Web3ZcashChainAccount, JSZcashWalletAccount, Web3ZcashChainIdnetifier> {
  const ZcashWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class ZcashWeb3JSStateAccount extends Web3JSStateAccount<
    ZcashAddress,
    Web3ZcashChainAccount,
    JSZcashWalletAccount,
    Web3ZcashChainIdnetifier,
    ZcashWeb3JSStateAddress> {
  ZcashWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory ZcashWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return ZcashWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory ZcashWeb3JSStateAccount(Web3ZcashChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return ZcashWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return ZcashWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSZcashWalletAccount.setup(
              address: e.addressStr, chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return ZcashWeb3JSStateAccount._(
        accounts: accounts.whereType<ZcashWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : ZcashWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSZcashWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class ZcashWeb3JSStateHandler extends Web3JSStateHandler<
        ZcashAddress,
        Web3ZcashChainAccount,
        JSZcashWalletAccount,
        Web3ZcashChainIdnetifier,
        ZcashWeb3JSStateAddress,
        ZcashWeb3JSStateAccount>
    with
        ZcashWeb3StateHandler<
            JSZcashWalletAccount,
            ZcashWeb3JSStateAddress,
            ZcashWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  ZcashWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3ZcashChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3ZcashRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3ZcashRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3ZcashRequestMethods.signMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3ZcashRequestMethods.sendTransaction:
        return toSignTransactionRequest(params: params, state: state, method: method!);
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
    final method = Web3ZcashRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3ZcashRequestMethods.signMessage:
        return WalletMessageResponse.success(
            JSZcashSignMessageResponse.setup(response.resultAsList()));
      case Web3ZcashRequestMethods.sendTransaction:
        final result =
            Web3ZcashTransactionResponse.deserialize(bytes: response.resultAsList<int>());
        final txId = JSZcashSendTransactionResponse.setup(txId: result.txId);
        return WalletMessageResponse.success(txId);
      case Web3ZcashRequestMethods.requestAccounts:
        return onConnectResponse(message);
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  ZcashWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return ZcashWeb3JSStateAccount.init();
    return ZcashWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
