import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/web/context/extension_content.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import '../../../js_crypto_utils.dart';
import '../../../webview.dart';
import '../../constant/constant.dart';
import '../../models/models.dart';
import '../../models/models/networks/wallet_standard.dart';
import '../../utils/utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import '../networks/ada.dart';
import '../networks/aptos.dart';
import '../networks/bitcoin.dart';
import '../networks/bitcoin_cash.dart';
import '../networks/cosmos.dart';
import '../networks/ethereum.dart';
import '../networks/monero.dart';
import '../networks/ripple.dart';
import '../networks/solana.dart';
import '../networks/stellar.dart';
import '../networks/substrate.dart';
import '../networks/sui.dart';
import '../networks/ton.dart';
import '../networks/tron.dart';
import '../networks/zcash.dart';
import 'network_handler.dart';
part "../webview.dart";
part "../extension.dart";
part 'wallet_standard.dart';

@JS("onmessage")
external set onMessage(JSFunction _);
typedef SendMessageToClient = void Function(WalletMessageEvent, JSClientType client);
typedef ONCHANGESTATE = void Function();

enum JSWalletMode {
  extension,
  webview;

  bool get isExtension => this == extension;
}

abstract class Web3JSWalletHandler extends Web3WalletHandler<
    JSWalletStandardAccount,
    WalletMessageResponse,
    Web3JsClientRequest,
    JSWalletNetworkEvent,
    Web3JSStateHandler,
    Web3JsClientRequest> with JSWalletStandardHandler {
  final AppContext context;
  JSWalletMode get mode;
  @override
  late final Map<JSClientType, Web3JSStateHandler> _networks = {
    JSClientType.ethereum: EthereumWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.tron: TronWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.solana: SolanaWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.ton: TonWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.stellar: StellarWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.substrate: SubstrateWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.aptos: AptosWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.sui: SuiWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.cosmos: CosmosWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.bitcoin: BitcoinWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.bitcoinCash: BitcoinCashWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.xrpl: RippleWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.monero: MoneroWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.cardano: ADAWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
    JSClientType.zcash: ZcashWeb3JSStateHandler(
        sendMessageToClient: _sendEventToClient,
        sendInternalMessage: _sendInternalWalletMessage),
  };
  String get clientId;
  late final String _id = JsUtils.toWalletId(clientId);
  final ChaCha20Poly1305 _crypto;
  Web3NetworkState _state = Web3NetworkState.ready;
  Web3JSWalletHandler._(this._crypto, this.context);

  void handleClientMessage(PageMessage request) {
    final client = request.clientType;
    switch (request.data.messageType) {
      case PageMessageType.event:
        if (_state.isBlock) return;
        if (client == null) {
          _onGlobalEvent(request.data.asEvent());
        } else {
          final event = request.data.asEvent();
          final stateEvent = Web3NetworkEvent.fromName(event.event);
          _networks[client]?.event(stateEvent!);
        }

        break;
      case PageMessageType.request:
        final result = _completeJsRequest(request);
        result.then(_sendMessageToClient);
        result.catchError((e, s) {
          final message = WalletMessage.response(
              client: request.clientType,
              requestId: request.requestId,
              data: WalletMessageResponse.fail(Web3RequestExceptionConst.internalErr(
                      "handleClientMessage",
                      reason: e.toString(),
                      trace: s?.toString())
                  .toResponseMessage()
                  .toWalletError()));
          _sendMessageToClient(message);
          return message;
        });
        break;
    }
  }

  void _onClientEvent(CustomEvent response) {
    final PageMessage request = response.detail as PageMessage;
    handleClientMessage(request);
  }

  void _listenOnClients() {
    jsWindow.addEventListener(_id, _onClientEvent.toJS);
  }

  void _sendMessageToClient(WalletMessage response) {
    final event = CustomEvent.create(
        type: JsUtils.toEthereumClientId(clientId), detail: response, clone: true);
    jsWindow.dispatchEvent(event);
  }

  @override
  void _sendEventToClient(WalletMessageEvent event, JSClientType? client) {
    _sendMessageToClient(WalletMessage.event(client: client, data: event));
  }

  Future<void> _sendMessageToWallet(
      {required Web3WalletRequestParams message, required String requestId});

  Web3EncryptedMessage _encryptMessage(Web3MessageCore message) {
    final nonce = QuickCrypto.generateRandom(12);
    final List<int> encryptedBytes = _crypto.encrypt(nonce, message.toCbor().encode());
    return Web3EncryptedMessage(message: encryptedBytes, nonce: nonce);
  }

  Future<Web3MessageCore> _sendInternalWalletMessage(
      {required NetworkType network, required Web3WalletRequestParams request}) async {
    final result = await _buildAndSendMessage(
        client: JSClientType.fromNetworkName(network.name), message: request);
    final Web3MessageCore response = result.$1;
    if (response.type == Web3MessageTypes.error) {
      final result = response.cast<Web3ExceptionMessage>();
      throw result.toException();
    }
    return response.cast();
  }

  Future<(Web3MessageCore, Web3WalletRequestParams?)> _buildAndSendMessage(
      {PageMessage? params, Web3MessageCore? message, JSClientType? client}) async {
    final completer = this.completer.nextRequest;
    final String requestId = completer.id;
    try {
      if (message == null) {
        if (params == null) {
          throw WalletExceptionConst.invalidRequest;
        }
        final request = Web3JsClientRequest(params.data.asRequest());
        Web3GlobalRequestMethods? globalMethod =
            Web3GlobalRequestMethods.fromName(request.method);
        if (globalMethod != null) {
          message = await _onGlobalRequest(
              request: request, globalMethod: globalMethod, client: client);
        } else {
          final handler = _networks[client];
          if (handler == null) {
            throw WalletExceptionConst.networkDoesNotExist;
          }

          message ??= await handler.request(request);
        }
      }

      switch (message.type) {
        case Web3MessageTypes.globalResponse:
        case Web3MessageTypes.walletResponse:
          this.completer.complete(response: message, requestId: requestId);
          break;
        default:
          await _sendMessageToWallet(message: message.cast(), requestId: requestId);
          break;
      }
    } on Web3RequestException catch (e) {
      final exception = e.toResponseMessage();
      this.completer.complete(response: exception, requestId: requestId);
    } catch (e, trace) {
      final exception = Web3RequestExceptionConst.internalErr("_buildAndSendMessage",
              reason: e.toString(), trace: trace.toString())
          .toResponseMessage();
      this.completer.complete(response: exception, requestId: requestId);
    }
    final response = await completer.wait;
    if (message?.type != Web3MessageTypes.walletRequest &&
        message?.type != Web3MessageTypes.walletGlobalRequest) {
      return (response, null);
    }
    return (response, message?.cast<Web3WalletRequestParams>());
  }

  Future<WalletMessage> _completeJsRequest(PageMessage params) async {
    final client = params.clientType;
    final handler = _networks[client];
    final clientRequest = Web3JsClientRequest(params.data.asRequest());
    try {
      if (_state.isBlock) {
        throw Web3RequestExceptionConst.bannedHost;
      }
      final result = await _buildAndSendMessage(params: params, client: client);
      final Web3MessageCore response = result.$1;
      final Web3WalletRequestParams? request = result.$2;
      final WalletMessageResponse message = switch (response.type) {
        Web3MessageTypes.globalResponse => await _finalizeGlobalResponse(
            message: params.data.asRequest(),
            response: response.cast(),
            params: request?.cast()),
        Web3MessageTypes.walletResponse => await handler!.finalizeWalletResponse(
            message: clientRequest, response: response.cast(), params: request?.cast()),
        Web3MessageTypes.error => await handler?.finalizeError(
                message: clientRequest,
                error: response.cast(),
                params: request?.cast()) ??
            WalletMessageResponse.fail(
                response.cast<Web3ExceptionMessage>().toWalletError()),
        _ => WalletMessageResponse.fail(
            Web3RequestExceptionConst.invalidRequest.toResponseMessage().toWalletError())
      };
      return WalletMessage.response(
          requestId: params.requestId, client: params.clientType, data: message);
    } finally {
      handler?.onRequestDone(clientRequest);
    }
  }

  Future<void> _updateAuthenticated(Web3APPData authenticated) async {
    _state = authenticated.active ? Web3NetworkState.ready : Web3NetworkState.block;
    for (final i in authenticated.networks) {
      final client = JSClientType.fromNetworkName(i.name);
      final event = await _networks[client]?.initChain(authenticated, context);
      if (event == null) continue;
      _sendEventToClient(WalletMessageEvent.build(data: event), client);
    }
    _sendGlobalEvent();
  }

  void _onWalletResponseIternal(JSWalletEventDart request) async {
    try {
      final data = List<int>.from(request.data);
      final encryptedMessage = Web3EncryptedMessage.deserialize(bytes: data);
      final decode = _crypto.decrypt(encryptedMessage.nonce, encryptedMessage.message);
      final message = Web3MessageCore.deserialize(bytes: decode);
      switch (message.type) {
        case Web3MessageTypes.globalResponse:
          final Web3GlobalResponseMessage msg = message.cast<Web3GlobalResponseMessage>();
          if (msg.authenticated != null) {
            await _updateAuthenticated(msg.authenticated!);
          }
          completer.complete(response: msg, requestId: request.requestId);
          break;
        case Web3MessageTypes.walletResponse:
          final Web3WalletResponseMessage msg = message.cast<Web3WalletResponseMessage>();
          if (msg.authenticated != null) {
            await _updateAuthenticated(msg.authenticated!);
          }
          completer.complete(response: msg, requestId: request.requestId);
          break;
        case Web3MessageTypes.error:
          final msg = message.cast<Web3ExceptionMessage>();
          if (msg.authenticated != null) {
            await _updateAuthenticated(msg.authenticated!);
          }
          completer.complete(response: msg, requestId: request.requestId);
          break;
        case Web3MessageTypes.chains:
          final Web3ChainMessage msg = message.cast<Web3ChainMessage>();
          _updateAuthenticated(msg.authenticated);
          break;
        default:
      }
    } on Web3RequestException catch (e) {
      final toMessage = e.toResponseMessage(requestId: request.requestId);
      completer.complete(response: toMessage, requestId: request.requestId);
    } catch (e, trace) {
      final toMessage = Web3RequestExceptionConst.internalErr("_onWalletResponseIternal",
              reason: e.toString(), trace: trace.toString())
          .toResponseMessage(requestId: request.requestId);
      completer.complete(response: toMessage, requestId: request.requestId);
    }
  }

  bool _onWalletResponse(JSWalletEventDart? request) {
    assert(request?.clientId == clientId, 'invalid clinet id');
    if (request?.clientId != clientId) {
      return false;
    }
    switch (request!.type) {
      case WalletEventTypes.exception:
        final message = Web3ExceptionMessage.deserialize(bytes: request.data);
        completer.complete(response: message, requestId: request.requestId);
        break;
      default:
        _onWalletResponseIternal(request);
        break;
    }
    return true;
  }
}
