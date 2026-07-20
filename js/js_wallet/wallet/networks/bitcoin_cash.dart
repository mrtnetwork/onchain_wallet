import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import '../../js_wallet.dart';
import '../../models/models/networks/bitcoin_cash.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class BitcoinCashWeb3JSStateAddress extends Web3JSStateAddress<
    BitcoinNetworkAddress,
    Web3BitcoinCashChainAccount,
    JSBitcoinCashWalletAccount,
    Web3BitcoinCashChainIdnetifier> {
  const BitcoinCashWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class BitcoinCashWeb3JSStateAccount extends Web3JSStateAccount<
    BitcoinNetworkAddress,
    Web3BitcoinCashChainAccount,
    JSBitcoinCashWalletAccount,
    Web3BitcoinCashChainIdnetifier,
    BitcoinCashWeb3JSStateAddress> {
  BitcoinCashWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory BitcoinCashWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return BitcoinCashWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory BitcoinCashWeb3JSStateAccount(
      Web3BitcoinCashChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return BitcoinCashWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return BitcoinCashWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSBitcoinCashWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              redeemScript: e.redeemScript,
              type: e.type.name,
              witnessScript: e.witnessScript,
              features: BitcoinCashJSConstant.accountFeatures(
                  network.wsIdentifier, e.type.supportBip137),
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return BitcoinCashWeb3JSStateAccount._(
        accounts: accounts.whereType<BitcoinCashWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : BitcoinCashWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSBitcoinCashWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    redeemScript: defaultAddress.redeemScript,
                    type: defaultAddress.type.name,
                    witnessScript: defaultAddress.witnessScript,
                    features: BitcoinCashJSConstant.accountFeatures(
                        networks[defaultAddress.id]!.wsIdentifier,
                        defaultAddress.type.supportBip137),
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class BitcoinCashWeb3JSStateHandler extends Web3JSStateHandler<
        BitcoinNetworkAddress,
        Web3BitcoinCashChainAccount,
        JSBitcoinCashWalletAccount,
        Web3BitcoinCashChainIdnetifier,
        BitcoinCashWeb3JSStateAddress,
        BitcoinCashWeb3JSStateAccount>
    with
        BitcoinCashWeb3StateHandler<
            JSBitcoinCashWalletAccount,
            BitcoinCashWeb3JSStateAddress,
            BitcoinCashWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  BitcoinCashWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3BitcoinCashChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3BitcoinCashRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3BitcoinCashRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3BitcoinCashRequestMethods.signTransaction:
        return toSignPsbtRequest(params: params, state: state, method: method!);
      case Web3BitcoinCashRequestMethods.sendTransaction:
        return toTransferRequest(params: params, state: state, method: method!);
      case Web3BitcoinCashRequestMethods.signPersonalMessage:
        return toSignMessageRequest(params: params, state: state, method: method!);
      case Web3BitcoinCashRequestMethods.getAccountAddresses:
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
    final method = Web3BitcoinCashRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3BitcoinCashRequestMethods.requestAccounts:
        return onConnectResponse(message);
      case Web3BitcoinCashRequestMethods.signTransaction:
        return WalletMessageResponse.success(
            JSBitcoinCashSignTransactionResponse.setup(response.resultAsString()));
      case Web3BitcoinCashRequestMethods.sendTransaction:
        return WalletMessageResponse.success(
            JSBitcoinCashSendTransactionResponse.setup(response.resultAsString()));
      case Web3BitcoinCashRequestMethods.signPersonalMessage:
        final signedMessage = Web3BitcoinSignMessageResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSBitcoinCashSignMessageResponse.setup(
            digest: signedMessage.digest, signature: signedMessage.signatureAsBase64()));
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  BitcoinCashWeb3JSStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return BitcoinCashWeb3JSStateAccount.init();
    return BitcoinCashWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
