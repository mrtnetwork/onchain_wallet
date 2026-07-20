import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../js_wallet.dart';
import '../../models/models/networks/cosmos.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class CosmosWeb3JSStateAddress extends Web3JSStateAddress<CosmosBaseAddress,
    Web3CosmosChainAccount, JSCosmosWalletAccount, Web3CosmoshainIdnetifier> {
  const CosmosWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class CosmosWeb3JSStateAccount extends Web3JSStateAccount<
    CosmosBaseAddress,
    Web3CosmosChainAccount,
    JSCosmosWalletAccount,
    Web3CosmoshainIdnetifier,
    CosmosWeb3JSStateAddress> {
  CosmosWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });

  bool chainExist(String chainId) {
    return chains.any((e) => e.chainId == chainId);
  }

  List<JSCosmosWalletAccount> getChainIdJsAccounts(String chainId) {
    final network = chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return accounts
        .where((e) => e.networkIdentifier == network)
        .map((e) => e.jsAccount)
        .toList();
  }

  factory CosmosWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return CosmosWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory CosmosWeb3JSStateAccount(Web3CosmosChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return CosmosWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3CosmoshainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return CosmosWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSCosmosWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              algo: e.algo.name,
              typeUrl: e.algo.getPublicKeyTypeUrl(),
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return CosmosWeb3JSStateAccount._(
        accounts: accounts.whereType<CosmosWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : CosmosWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSCosmosWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    typeUrl: defaultAddress.algo.getPublicKeyTypeUrl(),
                    algo: defaultAddress.algo.name,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class CosmosWeb3JSStateHandler extends Web3JSStateHandler<
        CosmosBaseAddress,
        Web3CosmosChainAccount,
        JSCosmosWalletAccount,
        Web3CosmoshainIdnetifier,
        CosmosWeb3JSStateAddress,
        CosmosWeb3JSStateAccount>
    with
        CosmosWeb3StateHandler<
            JSCosmosWalletAccount,
            CosmosWeb3JSStateAddress,
            CosmosWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  CosmosWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3CosmoshainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3CosmosRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3CosmosRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3CosmosRequestMethods.signTransactionDirect:
      case Web3CosmosRequestMethods.signTransactionAmino:
        return toSignDirectTransactionRequest(
            params: params, state: state, method: method!);
      case Web3CosmosRequestMethods.signMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3CosmosRequestMethods.addNewChain:
        return toAddNewChainRequest(params: params, state: state, method: method!);
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
    final method = Web3CosmosRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3CosmosRequestMethods.signMessage:
        final signedMessage = Web3CosmosSignMessageResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSCosmosSignMessageResponse.setup(
            signedMessage: signedMessage.messageBytes,
            signature: signedMessage.signature));
      case Web3CosmosRequestMethods.requestAccounts:
        return onConnectResponse(message);
      case Web3CosmosRequestMethods.signTransactionAmino:
        final transaction = response.resultAsList<int>();
        final signedResponse =
            Web3CosmosSignTransactionResponse.deserialize(bytes: transaction)
                .cast<Web3CosmosSignTransactionAminoSignResponse>();
        return WalletMessageResponse.success(JSCosmosAminoSignResponse.setup(
            tx: signedResponse.tx.toJson(),
            signature: JSCosmosStdSignature.setup(
                pubKey: JSCosmosPubKey.setup(
                    type: signedResponse.publicKey.typeUrl ?? "",
                    value: signedResponse.publicKey.toBase64()),
                signature: signedResponse.singaureAsBase64())));
      case Web3CosmosRequestMethods.signTransactionDirect:
        final transaction = response.resultAsList<int>();
        final signedResponse =
            Web3CosmosSignTransactionResponse.deserialize(bytes: transaction)
                .cast<Web3CosmosSignTransactionDirectSignResponse>();
        return WalletMessageResponse.success(JSCosmosDirectSignResponse.setup(
            signed: JSCosmosSignDoc.setup(
                bodyBytes: signedResponse.bodyBytes,
                authInfoBytes: signedResponse.authInfoBytes,
                chainId: signedResponse.chainId,
                accountNumber: signedResponse.accountNumber),
            signature: JSCosmosStdSignature.setup(
                pubKey: JSCosmosPubKey.setup(
                    type: signedResponse.publicKey.typeUrl ?? "",
                    value: signedResponse.publicKey.toBase64()),
                signature: signedResponse.singaureAsBase64())));
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  CosmosWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return CosmosWeb3JSStateAccount.init();
    return CosmosWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
