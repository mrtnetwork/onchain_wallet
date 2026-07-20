import 'dart:js_interop';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/sui.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../js_wallet.dart';
import '../../models/models/networks/sui.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class SuiWeb3JSStateAddress extends Web3JSStateAddress<SuiAddress, Web3SuiChainAccount,
    JSSuiWalletAccount, Web3ChainDefaultIdnetifier> {
  const SuiWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class SuiWeb3JSStateAccount extends Web3JSStateAccount<SuiAddress, Web3SuiChainAccount,
    JSSuiWalletAccount, Web3ChainDefaultIdnetifier, SuiWeb3JSStateAddress> {
  SuiWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory SuiWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return SuiWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory SuiWeb3JSStateAccount(Web3SuiChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return SuiWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return SuiWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSSuiWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              signingScheme: e.signingScheme,
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return SuiWeb3JSStateAccount._(
        accounts: accounts.whereType<SuiWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : SuiWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSSuiWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    signingScheme: defaultAddress.signingScheme,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class SuiWeb3JSStateHandler extends Web3JSStateHandler<
        SuiAddress,
        Web3SuiChainAccount,
        JSSuiWalletAccount,
        Web3ChainDefaultIdnetifier,
        SuiWeb3JSStateAddress,
        SuiWeb3JSStateAccount>
    with
        SuiWeb3StateHandler<
            JSSuiWalletAccount,
            SuiWeb3JSStateAddress,
            SuiWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  SuiWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final method = Web3SuiRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3SuiRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3SuiRequestMethods.signTransaction:
      case Web3SuiRequestMethods.signAndExecuteTransaction:
      case Web3SuiRequestMethods.signTransactionBlock:
      case Web3SuiRequestMethods.signAndExecuteTransactionBlock:
        return toSignTransactionRequest(params: params, state: state, method: method!);
      case Web3SuiRequestMethods.signMessage:
      case Web3SuiRequestMethods.signPersonalMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
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
    final method = Web3SuiRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3SuiRequestMethods.requestAccounts:
        return onConnectResponse(message);
      case Web3SuiRequestMethods.signTransaction:
        final transaction = Web3SuiSignTransactionResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSSuiSignTransactionResponse.setup(
            bytes: transaction.transactionAsBase64,
            signature: transaction.signatureAsBase64));
      case Web3SuiRequestMethods.signMessage:
        final signedMessage =
            Web3SuiSignMessageResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSSuiSignMessageResponse.setup(
            messageBytes: signedMessage.messageAsBase64,
            signature: signedMessage.signatureAsBase64));
      case Web3SuiRequestMethods.signPersonalMessage:
        final signedMessage =
            Web3SuiSignMessageResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSSuiSignPrsonalMessageResponse.setup(
            bytes: signedMessage.messageAsBase64,
            signature: signedMessage.signatureAsBase64));

      case Web3SuiRequestMethods.signTransactionBlock:
        final transaction = Web3SuiSignTransactionResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSSuiSignTransactionBlockResponse.setup(
            transactionBlockBytes: transaction.transactionAsBase64,
            signature: transaction.signatureAsBase64));
      case Web3SuiRequestMethods.signAndExecuteTransaction:
        final transaction = Web3SuiSignAndExecuteTransactionResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSSuiSignAndExecuteTransactionResponse.setup(
            digest: transaction.digest, effects: transaction.effects));
      case Web3SuiRequestMethods.signAndExecuteTransactionBlock:
        final transaction = Web3SuiSignAndExecuteTransactionResponse.deserialize(
            bytes: response.resultAsList<int>());
        final jsResponse = JSSuiSignAndExecuteTransactionBlockResponse(
            transaction.excuteResponse.jsify() ?? JSObject());
        jsResponse.digest = transaction.digest;
        return WalletMessageResponse.success(jsResponse);

      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  SuiWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return SuiWeb3JSStateAccount.init();
    return SuiWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
