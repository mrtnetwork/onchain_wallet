import 'dart:js_interop';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain/on_chain.dart';
import '../../models/models.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class TronWeb3JSStateAddress extends Web3JSStateAddress<TronAddress, Web3TronChainAccount,
    JSSTronWalletAccount, Web3TronChainIdnetifier> {
  const TronWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class TronWeb3JSStateAccount extends Web3JSStateAccount<TronAddress, Web3TronChainAccount,
    JSSTronWalletAccount, Web3TronChainIdnetifier, TronWeb3JSStateAddress> {
  bool chainExist(int chainId) {
    return chains.any((e) => e.chainId == chainId);
  }

  Web3TronChainIdnetifier getChainFromChainId(int chainId) {
    return chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
  }

  TronWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory TronWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return TronWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory TronWeb3JSStateAccount(Web3TronChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return TronWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3TronChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return TronWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSSTronWalletAccount.setup(
              address: e.addressStr,
              publicKey: e.publicKey,
              hex: e.address.toAddress(false),
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return TronWeb3JSStateAccount._(
        accounts: accounts.whereType<TronWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : TronWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSSTronWalletAccount.setup(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    hex: defaultAddress.address.toAddress(false),
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class TronWeb3JSStateHandler extends Web3JSStateHandler<
        TronAddress,
        Web3TronChainAccount,
        JSSTronWalletAccount,
        Web3TronChainIdnetifier,
        TronWeb3JSStateAddress,
        TronWeb3JSStateAccount>
    with
        TronWeb3StateHandler<
            JSSTronWalletAccount,
            TronWeb3JSStateAddress,
            TronWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  TronWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});

  @override
  JSWalletNetworkEvent createStateEvent(
      {required TronWeb3JSStateAccount previousState,
      required TronWeb3JSStateAccount currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool accountsChanged,
      required bool networksChanged}) {
    final event = super.createStateEvent(
        previousState: previousState,
        currentState: currentState,
        networksChanged: networksChanged,
        networkAccountsChanged: networkAccountsChanged,
        networkChanged: networkChanged,
        accountsChanged: accountsChanged);
    if (networkChanged) {
      final chain = currentState.defaultChain;
      if (chain != null) {
        event.chainChanged = JSTronTIPChainChanged(
            chainId: chain.chainId.toRadix16,
            netVersion: chain.chainId.toString(),
            fullNode: chain.fullNode,
            solidityNode: chain.solidityNode,
            eventServer: chain.fullNode,
            chain: "_");
      } else {
        final error = Web3RequestExceptionConst.disconnectProvider;
        event.disconnect =
            JSEthereumEIPProviderRpcError(message: error.message, code: error.code);
      }
    }
    return event;
  }

  @override
  Future<Web3MessageCore> request(Web3JsClientRequest params,
      {Web3TronChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3TronRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3TronRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3TronRequestMethods.switchTronChain:
        return toSwitchTronChainRequest(params: params, state: state, method: method!);
      case Web3TronRequestMethods.signTransaction:
        return toSignTransactionRequest(params: params, state: state, method: method!);
      case Web3TronRequestMethods.signMessageV2:
        return toSignMessageRequest(params: params, state: state, method: method!);
      default:
        return super.request(params, network: network);
    }
  }

  @override
  void onRequestDone(Web3JsClientRequest message) {}

  @override
  Future<WalletMessageResponse> finalizeWalletResponse(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3TronRequestMethods.fromName(message.request.method);

    switch (method) {
      case Web3TronRequestMethods.requestAccounts:
        return onConnectResponse(message);
      case Web3TronRequestMethods.signMessageV2:
        final signature = response.resultAsString();
        if (message.request.isWalletStandard) {
          return WalletMessageResponse.success(
              JSTronSignatureResponse.setup(BytesUtils.fromHexString(signature)));
        } else {
          return WalletMessageResponse.success(signature.toJS);
        }
      case Web3TronRequestMethods.switchTronChain:
        return WalletMessageResponse.success(true.toJS);
      case Web3TronRequestMethods.signTransaction:
        final List<int> data = BytesUtils.fromHexString(response.resultAsString());
        final transaction = Transaction.deserialize(List<int>.from(data));
        final signatures =
            transaction.signature.map((e) => BytesUtils.toHexString(e)).toList();
        Map<String, dynamic> txData;
        if (message.request.isWalletStandard) {
          final param =
              message.paramsAsMap(keys: JSTronWalletStandardTransactionParams.properties);
          txData = message.objectAsMap(object: param["transaction"], name: "transaction");
        } else {
          txData = message.paramsAsMap();
        }
        txData["signature"] = signatures;
        return WalletMessageResponse.success(txData.jsify());

      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  TronWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return TronWeb3JSStateAccount.init();
    return TronWeb3JSStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<JSWalletNetworkEvent?> createEvent(Web3NetworkEvent event) async {
    final state = await getState();
    switch (event) {
      case Web3NetworkEvent.chainChanged:
      case Web3NetworkEvent.connect:
        final event =
            JSWalletNetworkEvent(events: [JSNetworkEventType.defaultChainChanged]);
        final chain = state.defaultChain;
        if (chain != null) {
          event.chainChanged = JSTronTIPChainChanged(
              chainId: chain.chainId.toRadix16,
              netVersion: chain.chainId.toString(),
              fullNode: chain.fullNode,
              solidityNode: chain.solidityNode,
              eventServer: chain.fullNode,
              chain: "_");
        } else {
          final error = Web3RequestExceptionConst.disconnectProvider;
          event.disconnect =
              JSEthereumEIPProviderRpcError(message: error.message, code: error.code);
        }
        return event;
      default:
        return super.createEvent(event);
    }
  }
}
