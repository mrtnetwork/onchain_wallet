import 'dart:js_interop';

import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import '../../models/models/networks/ripple.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../models/models/requests.dart';
import '../core/network_handler.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class RippleWeb3JSStateAddress extends Web3JSStateAddress<XRPBaseAddress,
    Web3XRPChainAccount, JSRippleWalletAccount, Web3ChainDefaultIdnetifier> {
  const RippleWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class RippleWeb3JSStateAccount extends Web3JSStateAccount<
    XRPBaseAddress,
    Web3XRPChainAccount,
    JSRippleWalletAccount,
    Web3ChainDefaultIdnetifier,
    RippleWeb3JSStateAddress> {
  final String? applicationId;
  RippleWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    this.applicationId,
    super.defaultAccount,
    super.defaultChain,
  });
  factory RippleWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return RippleWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory RippleWeb3JSStateAccount(
      Web3XRPChainAuthenticated? authenticated, String applicationId) {
    if (authenticated == null) {
      return RippleWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return RippleWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSRippleWalletAccount.setup(
              address: e.addressStr, publicKey: e.publicKey, chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return RippleWeb3JSStateAccount._(
        accounts: accounts.whereType<RippleWeb3JSStateAddress>().toList(),
        applicationId: applicationId,
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : RippleWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSRippleWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class RippleWeb3JSStateHandler extends Web3JSStateHandler<
        XRPBaseAddress,
        Web3XRPChainAccount,
        JSRippleWalletAccount,
        Web3ChainDefaultIdnetifier,
        RippleWeb3JSStateAddress,
        RippleWeb3JSStateAccount>
    with
        XRPWeb3StateHandler<
            JSRippleWalletAccount,
            RippleWeb3JSStateAddress,
            RippleWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  RippleWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3ChainDefaultIdnetifier? network}) async {
    try {
      final state = await getState();
      final method = Web3XRPRequestMethods.fromName(params.request.method);
      switch (method) {
        case Web3XRPRequestMethods.requestAccounts:
          return onConnect_(params);
        case Web3XRPRequestMethods.signTransaction:
        case Web3XRPRequestMethods.sendTransaction:
          return toSignTransactionRequest(params: params, state: state, method: method!);
        case Web3XRPRequestMethods.signMessage:
          return toSignMessageRequest(params: params, state: state, method: method!);
        default:
          throw Web3RequestExceptionConst.methodDoesNotSupport;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3XRPRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3XRPRequestMethods.requestAccounts:
        return onConnectResponse(message);

      case Web3XRPRequestMethods.signTransaction:
      case Web3XRPRequestMethods.sendTransaction:
        final transaction =
            Web3XRPTransactionResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(transaction.toJson().jsify());
      case Web3XRPRequestMethods.signMessage:
        final signedResponse =
            Web3XRPSignMessageResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSRippleSignMessageResponse.setup(
            signature: signedResponse.signature, publicKey: signedResponse.publicKey));
    }

    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  RippleWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return RippleWeb3JSStateAccount.init();
    return RippleWeb3JSStateAccount(
        authenticated.getAuth(networkType), authenticated.applicationId);
  }
}
