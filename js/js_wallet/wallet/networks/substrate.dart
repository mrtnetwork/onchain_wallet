import 'dart:js_interop';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/substrate.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../js_wallet.dart';
import '../../models/models/networks/substrate.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class SubstrateWeb3JSStateAddress extends Web3JSStateAddress<BaseSubstrateAddress,
    Web3SubstrateChainAccount, JSSubstrateWalletAccount, Web3SubstrateChainIdnetifier> {
  const SubstrateWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class SubstrateWeb3JSStateAccount extends Web3JSStateAccount<
    BaseSubstrateAddress,
    Web3SubstrateChainAccount,
    JSSubstrateWalletAccount,
    Web3SubstrateChainIdnetifier,
    SubstrateWeb3JSStateAddress> {
  List<JSSubstrateKnownMetadata> get knownMetadatas => chains
      .map((e) => JSSubstrateKnownMetadata(
          genesisHash: e.genesisHash,
          identifier: e.wsIdentifier,
          specVersion: e.specVersion))
      .toList();
  SubstrateWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory SubstrateWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return SubstrateWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory SubstrateWeb3JSStateAccount(Web3SubstrateChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return SubstrateWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3SubstrateChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return SubstrateWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSSubstrateWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              genesisHash: network.genesisHash,
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return SubstrateWeb3JSStateAccount._(
        accounts: accounts.whereType<SubstrateWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : SubstrateWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSSubstrateWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    genesisHash: networks[defaultAddress.id]!.genesisHash,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class SubstrateWeb3JSStateHandler extends Web3JSStateHandler<
        BaseSubstrateAddress,
        Web3SubstrateChainAccount,
        JSSubstrateWalletAccount,
        Web3SubstrateChainIdnetifier,
        SubstrateWeb3JSStateAddress,
        SubstrateWeb3JSStateAccount>
    with
        SubstrateWeb3StateHandler<
            JSSubstrateWalletAccount,
            SubstrateWeb3JSStateAddress,
            SubstrateWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  SubstrateWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3SubstrateChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3SubstrateRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3SubstrateRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3SubstrateRequestMethods.knownMetadata:
        return createResponse();
      case Web3SubstrateRequestMethods.signMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3SubstrateRequestMethods.signTransaction:
        return toSignTransactionRequest(params: params, state: state, method: method!);
      case Web3SubstrateRequestMethods.addSubstrateChain:
        return toAddNewChainRequest(params: params, state: state, method: method!);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3SubstrateRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3SubstrateRequestMethods.knownMetadata:
        return WalletMessageResponse.success(state.knownMetadatas.toJS);
      case Web3SubstrateRequestMethods.requestAccounts:
        return onConnectResponse(message);
      case Web3SubstrateRequestMethods.addSubstrateChain:
        return WalletMessageResponse.success(true.toJS);
      case Web3SubstrateRequestMethods.signTransaction:
      case Web3SubstrateRequestMethods.signMessage:
        final signedTx = Web3SubstrateSendTransactionResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSSubstrateTxResponse(
            signature: signedTx.signatureHex,
            id: signedTx.id,
            signedTransaction: signedTx.signedTransactionHex));
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  SubstrateWeb3JSStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return SubstrateWeb3JSStateAccount.init();
    return SubstrateWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
