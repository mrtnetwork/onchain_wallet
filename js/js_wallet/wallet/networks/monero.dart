import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/monero.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../models/models/networks/monero.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../models/models/requests.dart';
import '../core/network_handler.dart';

class MoneroWeb3JSStateAddress extends Web3JSStateAddress<MoneroAddress,
    Web3MoneroChainAccount, JSMoneroWalletAccount, Web3MoneroChainIdnetifier> {
  const MoneroWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class MoneroWeb3JSStateAccount extends Web3JSStateAccount<
    MoneroAddress,
    Web3MoneroChainAccount,
    JSMoneroWalletAccount,
    Web3MoneroChainIdnetifier,
    MoneroWeb3JSStateAddress> {
  MoneroWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory MoneroWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return MoneroWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory MoneroWeb3JSStateAccount(Web3MoneroChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return MoneroWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return MoneroWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSMoneroWalletAccount.setup(
              address: e.addressStr, publicKey: e.publicKey, chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();

    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return MoneroWeb3JSStateAccount._(
        accounts: accounts.whereType<MoneroWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : MoneroWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSMoneroWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class MoneroWeb3JSStateHandler extends Web3JSStateHandler<
        MoneroAddress,
        Web3MoneroChainAccount,
        JSMoneroWalletAccount,
        Web3MoneroChainIdnetifier,
        MoneroWeb3JSStateAddress,
        MoneroWeb3JSStateAccount>
    with
        MoneroWeb3StateHandler<
            JSMoneroWalletAccount,
            MoneroWeb3JSStateAddress,
            MoneroWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  MoneroWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3MoneroChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3MoneroRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3MoneroRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3MoneroRequestMethods.signMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3MoneroRequestMethods.sendTransaction:
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
    final method = Web3MoneroRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3MoneroRequestMethods.signMessage:
        return WalletMessageResponse.success(
            JSMoneroSignMessageResponse.setup(response.resultAsList()));
      case Web3MoneroRequestMethods.sendTransaction:
        final result = Web3MoneroTransactionResponse.deserialize(
            bytes: response.resultAsList<int>());
        final txId = JSMoneroSendTransactionResponse.setup(
            proofs: result.proofs
                .map((e) => JSMoneroSendTransactionProofResponse.setup(
                    address: e.address, proof: e.proof))
                .toList(),
            txId: result.txId);
        return WalletMessageResponse.success(txId);
      case Web3MoneroRequestMethods.requestAccounts:
        return onConnectResponse(message);
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  MoneroWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return MoneroWeb3JSStateAccount.init();
    return MoneroWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
