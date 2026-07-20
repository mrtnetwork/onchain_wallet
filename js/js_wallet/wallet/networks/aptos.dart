import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import '../../js_wallet.dart';
import '../../models/models/networks/aptos.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../core/network_handler.dart';

class AptosWeb3JSStateAddress extends Web3JSStateAddress<AptosAddress,
    Web3AptosChainAccount, JSAptosWalletAccount, Web3AptosChainIdnetifier> {
  const AptosWeb3JSStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class AptosWeb3JSStateAccount extends Web3JSStateAccount<
    AptosAddress,
    Web3AptosChainAccount,
    JSAptosWalletAccount,
    Web3AptosChainIdnetifier,
    AptosWeb3JSStateAddress> {
  JSAptosNetworkInfo get currentChainInfo {
    final chain = defaultChain;
    if (chain == null) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return JSAptosNetworkInfo.setup(chainId: chain.chainId, name: chain.aptosChain.name);
  }

  AptosWeb3JSStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory AptosWeb3JSStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return AptosWeb3JSStateAccount._(accounts: const [], state: state, chains: []);
  }
  factory AptosWeb3JSStateAccount(Web3AptosChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return AptosWeb3JSStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return AptosWeb3JSStateAddress(
          chainaccount: e,
          jsAccount: JSAptosWalletAccount.setup(
              address: e.addressStr,
              signingScheme: e.signingScheme,
              publicKey: JSAptosPublicKey.setup(
                  publicKey: e.publicKey, publicKeyHex: e.publicKeyHex),
              chain: network.wsIdentifier),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return AptosWeb3JSStateAccount._(
        accounts: accounts.whereType<AptosWeb3JSStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : AptosWeb3JSStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: JSAptosWalletAccount.setup(
                    signingScheme: defaultAddress.signingScheme,
                    publicKey: JSAptosPublicKey.setup(
                        publicKey: defaultAddress.publicKey,
                        publicKeyHex: defaultAddress.publicKeyHex),
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.wsIdentifier),
              ));
  }
}

class AptosWeb3JSStateHandler extends Web3JSStateHandler<
        AptosAddress,
        Web3AptosChainAccount,
        JSAptosWalletAccount,
        Web3AptosChainIdnetifier,
        AptosWeb3JSStateAddress,
        AptosWeb3JSStateAccount>
    with
        AptosWeb3StateHandler<
            JSAptosWalletAccount,
            AptosWeb3JSStateAddress,
            AptosWeb3JSStateAccount,
            WalletMessageResponse,
            Web3JsClientRequest,
            JSWalletNetworkEvent> {
  AptosWeb3JSStateHandler(
      {required super.sendMessageToClient, required super.sendInternalMessage});
  @override
  JSWalletNetworkEvent createStateEvent(
      {required AptosWeb3JSStateAccount previousState,
      required AptosWeb3JSStateAccount currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool networksChanged,
      required bool accountsChanged}) {
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
        event.chainChanged =
            JSAptosNetworkInfo.setup(chainId: chain.chainId, name: chain.aptosChain.name);
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
      {Web3AptosChainIdnetifier? network}) async {
    final state = await getState();
    final method = Web3AptosRequestMethods.fromName(params.request.method);
    switch (method) {
      case Web3AptosRequestMethods.requestAccounts:
        return onConnect_(params);
      case Web3AptosRequestMethods.getNetwork:
        if (state.hasChainAccount) {
          return createResponse();
        }
        throw Web3RequestExceptionConst.missingPermission;
      case Web3AptosRequestMethods.signTransaction:
        return toSignTransactionRequest(params: params, state: state, method: method!);
      case Web3AptosRequestMethods.signMessage:
        return toSignInRequest(params: params, state: state, method: method!);
      case Web3AptosRequestMethods.switchNetwork:
        return toSwitchChainRequest(params: params, state: state, method: method!);
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
    final state = await getState();
    final method = Web3AptosRequestMethods.fromName(message.request.method);
    switch (method) {
      case Web3AptosRequestMethods.requestAccounts:
        if (state.hasChainAccount) {
          final chainId = message.requestParams.elementAtOrNull(0)?.toString();
          final chain = chainId == null
              ? null
              : state.chains.firstWhereOrNull((e) => e.isChain(chainId));
          if (chain == null || chain == state.defaultChain) {
            return WalletMessageResponse.success(
                JSAptosWalletStandardUserResponse.approved(state.defaultAccountOrError));
          }
        }

        return WalletMessageResponse.success(
            JSAptosWalletStandardUserResponse.rejected());
      case Web3AptosRequestMethods.signTransaction:
        final transactionResponse = response.resultAsList<int>();
        final message = JSAptosWalletStandardUserResponse.approved(
            JSAptosSignTransactionResponse.setup(
                bytes: transactionResponse,
                dataHex: BytesUtils.toHexString(transactionResponse, prefix: "0x")));
        return WalletMessageResponse.success(message);
      case Web3AptosRequestMethods.signMessage:
        final responseMessage =
            Web3AptosSignMessageResponse.deserialize(bytes: response.resultAsList<int>());
        final signedMessage = JSAptosSignMessageResponse.setup(
            signatureBytes: responseMessage.signature,
            signatureHex: BytesUtils.toHexString(responseMessage.signature, prefix: "0x"),
            message: responseMessage.message!,
            nonce: responseMessage.nonce!,
            fullMessage: responseMessage.fullMessage!,
            prefix: responseMessage.prefix!,
            address: responseMessage.address,
            application: responseMessage.application,
            chainId: responseMessage.chainId);
        return WalletMessageResponse.success(
            JSAptosWalletStandardUserResponse.approved(signedMessage));
      case Web3AptosRequestMethods.getNetwork:
        if (state.hasChainAccount) {
          return WalletMessageResponse.success(state.currentChainInfo);
        }
        throw Web3RequestExceptionConst.missingPermission;
      case Web3AptosRequestMethods.switchNetwork:
        final network =
            parseSwitchChainRequest(params: message, state: state, method: method!);
        if (network == state.defaultChain) {
          return WalletMessageResponse.success(JSAptosSwitchChainResponse.success());
        }
        return WalletMessageResponse.success(JSAptosSwitchChainResponse.fail());

      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }

  @override
  Future<WalletMessageResponse> finalizeError(
      {required Web3JsClientRequest message,
      required Web3RequestParams? params,
      required Web3ExceptionMessage error}) async {
    final method = Web3AptosRequestMethods.fromName(message.request.method);
    bool isAuthenticatedError = error.errorType.isAuthError;
    if (isAuthenticatedError) {
      switch (method) {
        case Web3AptosRequestMethods.requestAccounts:
        case Web3AptosRequestMethods.signTransaction:
        case Web3AptosRequestMethods.signMessage:
          return WalletMessageResponse.success(
              JSAptosWalletStandardUserResponse.rejected());
        default:
      }
    } else {
      switch (method) {
        case Web3AptosRequestMethods.switchNetwork:
          return WalletMessageResponse.success(
              JSAptosSwitchChainResponse.fail(reason: error.message));
        default:
      }
    }
    return super.finalizeError(message: message, params: params, error: error);
  }

  @override
  AptosWeb3JSStateAccount createState(Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return AptosWeb3JSStateAccount.init();
    return AptosWeb3JSStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<JSWalletNetworkEvent?> createEvent(Web3NetworkEvent event) async {
    final state = await getState();
    switch (event) {
      case Web3NetworkEvent.chainChanged:
        final event =
            JSWalletNetworkEvent(events: [JSNetworkEventType.defaultChainChanged]);
        final chain = state.defaultChain;
        if (chain != null) {
          event.chainChanged = JSAptosNetworkInfo.setup(
              chainId: chain.chainId, name: chain.aptosChain.name);
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
