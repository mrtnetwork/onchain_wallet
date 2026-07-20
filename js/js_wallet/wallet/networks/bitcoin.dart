import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../js_wallet.dart';
import '../../models/models/networks/bitcoin.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class BitcoinWeb3JSStateAddress extends Web3JSStateAddress<BitcoinNetworkAddress,
    Web3BitcoinChainAccount, JSBitcoinWalletAccount, Web3BitcoinChainIdnetifier> {
  const BitcoinWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class BitcoinWeb3JSStateAccount extends Web3JSStateAccount<
    BitcoinNetworkAddress,
    Web3BitcoinChainAccount,
    JSBitcoinWalletAccount,
    Web3BitcoinChainIdnetifier,
    BitcoinWeb3JSStateAddress> {
  BitcoinWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory BitcoinWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return BitcoinWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory BitcoinWeb3JSStateAccount(Web3BitcoinChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return BitcoinWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return BitcoinWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSBitcoinWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              redeemScript: e.redeemScript,
              type: e.type.name,
              witnessScript: e.witnessScript,
              features: BitcoinJSConstant.accountFeatures(
                  network.wsIdentifier, e.type.supportBip137),
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return BitcoinWeb3JSStateAccount._(
        accounts: accounts.whereType<BitcoinWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : BitcoinWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSBitcoinWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    redeemScript: defaultAddress.redeemScript,
                    type: defaultAddress.type.name,
                    witnessScript: defaultAddress.witnessScript,
                    features: BitcoinJSConstant.accountFeatures(
                        networks[defaultAddress.id]!.wsIdentifier,
                        defaultAddress.type.supportBip137),
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class BitcoinWeb3JSStateHandler extends Web3JSStateHandler<
        BitcoinNetworkAddress,
        Web3BitcoinChainAccount,
        JSBitcoinWalletAccount,
        Web3BitcoinChainIdnetifier,
        BitcoinWeb3JSStateAddress,
        BitcoinWeb3JSStateAccount>
    with
        BitcoinWeb3StateHandler<
            JSBitcoinWalletAccount,
            BitcoinWeb3JSStateAddress,
            BitcoinWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  BitcoinWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3BitcoinChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3BitcoinRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3BitcoinRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3BitcoinRequestMethods.signTransaction:
        return toSignPsbtRequest(params: params, state: state, method: method!);
      case Web3BitcoinRequestMethods.sendTransaction:
        return toTransferRequest(params: params, state: state, method: method!);
      case Web3BitcoinRequestMethods.signPersonalMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3BitcoinRequestMethods.getAccountAddresses:
        return toGetAccountAddressesRequest(
            params: params, state: state, method: method!);
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
    final method = Web3BitcoinRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3BitcoinRequestMethods.requestAccounts:
        return onConnectResponse(message);
      case Web3BitcoinRequestMethods.signTransaction:
        return WalletMessageResponse.success(
            JSBitcoinSignTransactionResponse.setup(response.resultAsString()));
      case Web3BitcoinRequestMethods.sendTransaction:
        return WalletMessageResponse.success(
            JSBitcoinSendTransactionResponse.setup(response.resultAsString()));
      case Web3BitcoinRequestMethods.signPersonalMessage:
        final signedMessage = Web3BitcoinSignMessageResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSBitcoinSignMessageResponse.setup(
            digest: signedMessage.digest, signature: signedMessage.signatureAsBase64()));
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  BitcoinWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return BitcoinWeb3JSStateAccount.init();
    return BitcoinWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
