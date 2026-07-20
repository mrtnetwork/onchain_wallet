import 'dart:js_interop';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain/solana/solana.dart' show SolAddress;
import '../../models/models/networks/solana.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../models/models/requests.dart';
import '../core/network_handler.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class SolanaWeb3JSStateAddress extends Web3JSStateAddress<SolAddress,
    Web3SolanaChainAccount, JSSolanaWalletAccount, Web3ChainDefaultIdnetifier> {
  const SolanaWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class SolanaWeb3JSStateAccount extends Web3JSStateAccount<
    SolAddress,
    Web3SolanaChainAccount,
    JSSolanaWalletAccount,
    Web3ChainDefaultIdnetifier,
    SolanaWeb3JSStateAddress> {
  final String? applicationId;
  SolanaWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    this.applicationId,
    super.defaultAccount,
    super.defaultChain,
  });
  factory SolanaWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return SolanaWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory SolanaWeb3JSStateAccount(
      Web3SolanaChainAuthenticated? authenticated, String applicationId) {
    if (authenticated == null) {
      return SolanaWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return SolanaWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSSolanaWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.address.toBytes(),
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return SolanaWeb3JSStateAccount._(
        accounts: accounts.whereType<SolanaWeb3JSStateAddress>().toList(),
        applicationId: applicationId,
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : SolanaWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSSolanaWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.address.toBytes(),
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class SolanaWeb3JSStateHandler extends Web3JSStateHandler<
        SolAddress,
        Web3SolanaChainAccount,
        JSSolanaWalletAccount,
        Web3ChainDefaultIdnetifier,
        SolanaWeb3JSStateAddress,
        SolanaWeb3JSStateAccount>
    with
        SolanaWeb3StateHandler<
            JSSolanaWalletAccount,
            SolanaWeb3JSStateAddress,
            SolanaWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  SolanaWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});
  // Web3SolanaSendTransactionData _parseTransactionObject(
  //     {required JSSolanaSignTransactionParams param,
  //     required SolanaWeb3JSStateAccount state,
  //     required Web3JsClientRequest params,
  //     required Web3SolanaRequestMethods method}) {
  //   return Web3ValidatorUtils.parseParams2(() {
  //     final transaction = Web3ValidatorUtils.parseParams2(
  //         () => SolanaTransaction.deserialize(params.objectAsBytes(
  //             object: param.transaction,
  //             name: "transaction",
  //             encoding: [StringEncoding.base64])),
  //         error: Web3RequestExceptionConst.invalidTransaction);
  //     Web3ChainDefaultIdnetifier? network;
  //     final chainId = param.chain;
  //     if (chainId != null) {
  //       network = state.getChainFromChainIdentifier(chainId);
  //     }
  //     final account = state.getJsAddressChainAccountOrThrow(param.account,
  //         network: network);
  //     final config = param.options == null
  //         ? null
  //         : Web3SolanaSendTransactionOptions.fromJson(
  //             json: params.objectAsMap(object: param.options, name: "options"),
  //             method: method);
  //     return Web3SolanaSendTransactionData(
  //       account: account,
  //       messageByte: transaction.serialize(),
  //       sendConfig: config,
  //     );
  //   }, error: Web3RequestExceptionConst.invalidTransaction);
  // }

  // /// toSignMessageRequest
  // @override
  // Web3SolanaSignMessage toSignMessageRequest(
  //     {required Web3JsClientRequest params,
  //     required SolanaWeb3JSStateAccount state,
  //     required Web3SolanaRequestMethods method,
  //     Web3ChainDefaultIdnetifier? network}) {
  //   return Web3ValidatorUtils.parseParams2(() {
  //     final List<Web3SolanaSignParams> messages = [];
  //     final param = params
  //         .elementAsJsObject<JSArray<JSSolanaSignMessageParams>>(0)
  //         .toDart;
  //     for (final i in param) {
  //       final account = state.getJsAddressChainAccountOrThrow(i.account);
  //       final messageBytes = params.objectAsBytes(i.message, "message",
  //           encoding: [
  //             StringEncoding.hex,
  //             StringEncoding.base58,
  //             StringEncoding.utf8
  //           ]);
  //       final msg = Web3SolanaSignMessageParams(
  //           account: account,
  //           data: BytesUtils.toHexString(messageBytes),
  //           content: StringUtils.decode(messageBytes));
  //       messages.add(msg);
  //     }
  //     return Web3SolanaSignMessage(messages: messages, method: method);
  //   }, error: Web3SolanaExceptionConstant.invalidSignInParams);
  // }

  // @override
  // Web3SolanaSignMessage toSignInRequest(
  //     {required Web3JsClientRequest params,
  //     required SolanaWeb3JSStateAccount state,
  //     required Web3SolanaRequestMethods method,
  //     Web3ChainDefaultIdnetifier? network}) {
  //   return Web3ValidatorUtils.parseParams2(() {
  //     final List<Web3SolanaSignInParams> messages = [];
  //     final param =
  //         params.elementAsJsObject<JSArray<JSSolanaSignInParams>>(0).toDart;
  //     for (final i in param) {
  //       final signIn = parseSignInRequest(
  //           data: params.objectAsMap(i), state: state, method: method);
  //       messages.add(signIn);
  //     }
  //     return Web3SolanaSignMessage(messages: messages, method: method);
  //   });
  // }

  // @override
  // Web3SolanaSendTransaction toSignTransactionsRequest(
  //     {required Web3JsClientRequest params,
  //     required SolanaWeb3JSStateAccount state,
  //     required Web3SolanaRequestMethods method,
  //     Web3ChainDefaultIdnetifier? network}) {
  //   final transactions = params.getParams();
  //   // .elementAsJsObject<JSArray<JSSolanaSignAndSendTransactionParams>>(0)
  //   // .toDart;
  //   final List<Web3SolanaSendTransactionData> messages = [];
  //   for (final i in transactions) {
  //     try {
  //       final data = params.elementAsMap(i);
  //       final tx = _parseTransactionObject(
  //           param: i, state: state, params: params, method: method);
  //       messages.add(tx);
  //     } catch (e) {
  //       rethrow;
  //     }
  //   }
  //   SolanaSignAndSendAllTransactionMode? mode;
  //   if (method == Web3SolanaRequestMethods.signAndSendAllTransactions) {
  //     final modeArg = params.request
  //         .elementAs<JSSolanaSignAndSendAllTransactionMode>(1,
  //             peroperties: ["mode"]);
  //     final modeName = modeArg?.mode;
  //     if (modeName != null) {
  //       mode = SolanaSignAndSendAllTransactionMode.fromName(modeName);
  //     }
  //   }
  //   return Web3SolanaSendTransaction(
  //       messages: messages, method: method, mode: mode);
  // }

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3ChainDefaultIdnetifier? network}) async {
    final state = await getState();
    final method = Web3SolanaRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3SolanaRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
      case Web3SolanaRequestMethods.signAllTransactions:
      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.sendTransaction:
        return toSignTransactionsRequest(params: params, state: state, method: method!);
      case Web3SolanaRequestMethods.signMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3SolanaRequestMethods.signIn:
        if (!state.hasAccount) {
          await onConnect_(null);
          return toSignInRequest(params: params, method: method!);
        }
        return toSignInRequest(params: params, state: state, method: method!);
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
    final method = Web3SolanaRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3SolanaRequestMethods.requestAccounts:
        return onConnectResponse(message);

      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.signAllTransactions:
        final signedTxs = response
            .resultAsListOfBytes()
            .map((e) => Web3SolanaTransactionResponse.deserialize(bytes: e))
            .map((e) => SolanaSignTransactionOutput.setup(e.signedTx))
            .toList();
        return WalletMessageResponse.success(signedTxs.toJS);
      case Web3SolanaRequestMethods.sendTransaction:
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
        final signedTxs = response
            .resultAsListOfBytes()
            .map((e) => Web3SolanaTransactionResponse.deserialize(bytes: e))
            .map((e) => SolanaSignAndSendTransactionOutput.setup(e.signature))
            .toList();
        return WalletMessageResponse.success(signedTxs.toJS);
      case Web3SolanaRequestMethods.signMessage:
      case Web3SolanaRequestMethods.signIn:
        List<JSSolanaSignInResponse> signatures = [];
        final r = params!.cast<Web3SolanaSignMessage>();
        final signedMessages = response
            .resultAsList<Map<String, dynamic>>()
            .map((e) => Web3SolanaSignMessageResponse.fromJson(e))
            .toList();
        for (int i = 0; i < signedMessages.length; i++) {
          final signedMessage = signedMessages[i];
          final param = r.messages[i];
          final response = JSSolanaSignInResponse.setup(
              signature: signedMessage.signature,
              signedMessage: signedMessage.signedMessage,
              account:
                  state.getStateAddress(param.account.address, id: param.account.id));
          signatures.add(response);
        }
        return WalletMessageResponse.success(signatures.toJS);
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  SolanaWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return SolanaWeb3JSStateAccount.init();
    return SolanaWeb3JSStateAccount(
        authenticated.getAuth(networkType), authenticated.applicationId);
  }
}
