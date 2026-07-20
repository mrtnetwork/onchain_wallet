import 'dart:js_interop';

import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/cardano.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/state/types/types.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import '../../models/models.dart';
import '../../models/models/networks/ada.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class ADAWeb3JSStateAddress extends Web3JSStateAddress<ADAAddress, Web3ADAChainAccount,
    JSADAWalletAccount, Web3ADAChainIdnetifier> {
  const ADAWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class ADAWeb3JSStateAccount extends Web3JSStateAccount<ADAAddress, Web3ADAChainAccount,
    JSADAWalletAccount, Web3ADAChainIdnetifier, ADAWeb3JSStateAddress> {
  ADAWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory ADAWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return ADAWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory ADAWeb3JSStateAccount(Web3ADAChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return ADAWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return ADAWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSADAWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              chain: network.wsIdentifier,
              isRewardAddress: e.isRewardAddress),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return ADAWeb3JSStateAccount._(
        accounts: accounts.whereType<ADAWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : ADAWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSADAWalletAccount.setup(
                    isRewardAddress: defaultAddress.isRewardAddress,
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class ADAWeb3JSStateHandler extends Web3JSStateHandler<
        ADAAddress,
        Web3ADAChainAccount,
        JSADAWalletAccount,
        Web3ADAChainIdnetifier,
        ADAWeb3JSStateAddress,
        ADAWeb3JSStateAccount>
    with //
        ADAWeb3StateHandler<
            JSADAWalletAccount,
            ADAWeb3JSStateAddress,
            ADAWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  ADAWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3ADAChainIdnetifier? network}) async {
    final method = Web3ADARequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3ADARequestMethods.requestAccounts:
        return onConnect_(params);
      default:
        return super.request(params);
    }
  }

  @override
  void onRequestDone(Web3JsClientRequest message) {}

  @override
  Future<WalletMessageResponse> finalizeError(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3ExceptionMessage error}) async {
    final method = Web3ADARequestMethods.fromName(message.request.method);
    if (!message.request.isCardanoApi) {
      return super.finalizeError(message: message, params: params, error: error);
    }
    JSWalletError jsError = JSWalletError.cardano(
        info: error.message,
        code: findErrorCode(error: error.errorType, method: method),
        walletCode: error.errorType.walletCode);
    return WalletMessageResponse.fail(jsError);
  }

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3ADARequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3ADARequestMethods.requestAccounts:
        return onConnectResponse(message);

      case Web3ADARequestMethods.signMessage:
        final signature =
            Web3ADASignMessageResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(
            JSADASignMessageResponse.setup(signature.signature));
      case Web3ADARequestMethods.signData:
        final signature =
            Web3ADASignDataResponse.deserialize(bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(JSADASignDataResponse.setup(
            key: BytesUtils.toHexString(signature.key),
            pubKey: BytesUtils.toHexString(signature.pubKey),
            signature: BytesUtils.toHexString(signature.signature)));
      case Web3ADARequestMethods.getCollateral:
        final utxos = response.resultAsListOfBytes();
        return WalletMessageResponse.success(
            utxos.map((e) => BytesUtils.toHexString(e).toJS).toList().toJS);
      case Web3ADARequestMethods.signTransaction:
        final resposne = Web3ADASignTransactionsResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(
            resposne.witnesses.map((e) => e.witness.serializeHex().toJS).toList().toJS);
      case Web3ADARequestMethods.signTx:
        final resposne = Web3ADASignTransactionsResponse.deserialize(
            bytes: response.resultAsList<int>());
        if (resposne.witnesses.length != 1) {
          throw Web3RequestExceptionConst.internalErr("ada.finalizeWalletResponse",
              reason: "Unexpected response.");
        }
        return WalletMessageResponse.success(
            resposne.witnesses[0].witness.serializeHex().toJS);
      case Web3ADARequestMethods.signTxs:
        final resposne = Web3ADASignTransactionsResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(
            resposne.witnesses.map((e) => e.witness.serializeHex().toJS).toList().toJS);
      case Web3ADARequestMethods.submitTxs:
        final resposne = Web3ADASignTransactionsResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(resposne.witnesses
            .map((e) {
              if (e.error != null) {
                return JSWalletError.cardano(info: e.error, code: 1);
              }
              return e.txId.toJS;
            })
            .toList()
            .toJS);
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitUnsignedTx:
        final resposne = Web3ADASignTransactionsResponse.deserialize(
            bytes: response.resultAsList<int>());
        if (resposne.witnesses.length != 1) {
          throw Web3RequestExceptionConst.internalErr("ada.finalizeWalletResponse",
              reason: "Unexpected response.");
        }
        return WalletMessageResponse.success(resposne.witnesses[0].txId.toJS);
      case Web3ADARequestMethods.signAndSendTransaction:
        final resposne = Web3ADASignTransactionsResponse.deserialize(
            bytes: response.resultAsList<int>());
        return WalletMessageResponse.success(resposne.witnesses
            .map((e) {
              if (e.error != null) {
                return JSWalletError.cardano(info: e.error, code: 1);
              }
              return e.txId.toJS;
            })
            .toList()
            .toJS);
      case Web3ADARequestMethods.getScriptRequirements:
        final resposne = response.resultAsList<Web3ADAScriptRequirement>();
        return WalletMessageResponse.success(resposne
            .map((e) => JSADAScriptRequirement.setup(value: e.value, code: e.code))
            .toList()
            .toJS);
      case Web3ADARequestMethods.getAccountPub:
        final resposne = response.resultAsList<int>();
        return WalletMessageResponse.success(BytesUtils.toHexString(resposne).toJS);
      case Web3ADARequestMethods.getExtensions:
        final resposne = response.resultAsList<Web3ADAExtension>();
        return WalletMessageResponse.success(
            resposne.map((e) => JSADAExtension.setup(e.cip)).toList().toJS);

      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  ADAWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return ADAWeb3JSStateAccount.init();
    return ADAWeb3JSStateAccount(authenticated.getAuth(networkType));
  }
}
