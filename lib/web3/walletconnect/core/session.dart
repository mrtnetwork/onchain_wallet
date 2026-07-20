import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/zcash.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/chain.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/global_response.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/wallet_response.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message_types.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/web3/web3/core/request/params.dart';
import 'package:on_chain_wallet/web3/web3/state/core/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/params/connect.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/ada.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/aptos.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/bitcoin.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/bitcoin_cash.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/cosmos.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/ethereum.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/monero.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/solana.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/stellar.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/substrate.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/sui.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/ton.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/tron.dart';
import 'package:on_chain_wallet/web3/walletconnect/networks/xrp.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';

class Web3WalletConnectSessionHandler extends Web3WalletHandler<
    WalletConnectAddress,
    WalletConnectWalletMessageResponse,
    WalletConnectNetworkRequest,
    WalletConnectClientEvent,
    Web3WalletConnectStateHandler,
    WalletConnectNetworkRequest> {
  final Web3ClientInfo client;
  final TypeCbWcWalletMessage sendMessagetowallet;
  final TypeCbWcClientMessage sendEventToClient;
  final AppContext context;
  WCSession _session;
  String get topic => _session.topic;
  WCSession get session => _session;
  Web3WalletConnectSessionHandler(
      {required this.sendMessagetowallet,
      required this.sendEventToClient,
      required this.client,
      required WCSession session,
      required this.context})
      : _session = session;
  late final Map<NetworkType, Web3WalletConnectStateHandler> _networks = {
    NetworkType.ethereum: EthereumWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.tron: TronWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.solana: SolanaWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.ton:
        TonWeb3WalletConnectStateHandler(sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.stellar: StellarWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.substrate: SubstrateWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.aptos: AptosWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.sui:
        SuiWeb3WalletConnectStateHandler(sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.cosmos: CosmosWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.bitcoinAndForked: BitcoinWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.bitcoinCash: BitcoinCashWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.xrpl:
        XRPWeb3WalletConnectStateHandler(sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.monero: MoneroWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.cardano:
        ADAWeb3WalletConnectStateHandler(sendInternalMessage: _sendInternalWalletMessage),
    NetworkType.zcash: ZcashWeb3WalletConnectStateHandler(
        sendInternalMessage: _sendInternalWalletMessage)
  };

  Future<(List<WalletConnectAddress>, List<String>)> _getWalletChange() async {
    final states = await Future.wait(_networks.values.map((e) => e.getState()).toList());
    final accounts = states.map((e) => e.stateAccounts).expand((e) => e).toList();
    final chains = states.map((e) => e.chains).expand((e) => e).toList();
    return (accounts, chains.map((e) => e.caip2).toList());
  }

  Future<List<Web3ChainIdnetifier>> _getWalletNetwork() async {
    final states = await Future.wait(_networks.values.map((e) => e.getState()).toList());
    final chains = states.map((e) => e.chains).expand((e) => e).toList();
    return chains;
  }

  Future<Web3MessageCore> _onGlobalRequest(
      {required Web3GlobalRequestMethods method,
      required NetworkType? network,
      required WalletConnectNetworkRequest request}) async {
    switch (method) {
      case Web3GlobalRequestMethods.disconnect:
        return _networks[network]!.discoonect();
      case Web3GlobalRequestMethods.connect:
        final connectParam = request.requestParams.elementAtOrNull(0);
        List<int> networkIds = [];
        if (connectParam != null) {
          final data = request.paramsAsMap();
          final List<String>? chains =
              Web3ValidatorUtils.parseList<List<String>?, String>(
                  key: "chains", method: method, json: data);
          if (chains != null && chains.isNotEmpty) {
            final walletChains = await _getWalletNetwork();
            for (final i in chains) {
              if (!Web3ValidatorUtils.isCaip2(i)) {
                throw Web3RequestExceptionConst.invalidCaip2ChainIdStyle;
              }
              final network = walletChains.firstWhere((e) => e.isChain(i),
                  orElse: () =>
                      throw Web3RequestExceptionConst.networkIdDoesNotExists(i));
              networkIds.add(network.id);
            }
          }
        }

        return Web3ConnectApplication.networks(networkIds);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }

  Future<WalletConnectWalletMessageResponse> _finalizeGlobalResponse(
      {required WalletConnectNetworkRequest message,
      required Web3WalletRequestParams? params,
      required Web3GlobalResponseMessage response}) async {
    final method = Web3GlobalRequestMethods.fromName(message.method);
    switch (method) {
      case Web3GlobalRequestMethods.disconnect:
        return WalletConnectWalletMessageResponse.success(data: true);
      case Web3GlobalRequestMethods.connect:
        final accounts = (await _getWalletChange()).$1;
        if (accounts.isNotEmpty) {
          return WalletConnectWalletMessageResponse.success(data: accounts);
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }

  Future<void> updateAuthenticated(Web3APPData authenticated) async {
    final events = await Future.wait(authenticated.networks
        .map((e) async => await _networks[e]?.initChain(authenticated, context)));
    await _sendEventToClient(events.whereType<WalletConnectClientEvent>().toList());
  }

  Future<Web3MessageCore> _sendInternalWalletMessage(
      {required NetworkType network, required Web3WalletRequestParams request}) async {
    final result = await _buildAndSendMessage(message: request);
    final Web3MessageCore response = result.$1;
    if (response.type == Web3MessageTypes.error) {
      final result = response.cast<Web3ExceptionMessage>();
      throw result.toException();
    }
    return response.cast();
  }

  void onWalletResponse(
      {required Web3MessageCore message, required String requestId}) async {
    try {
      switch (message.type) {
        case Web3MessageTypes.globalResponse:
          final Web3GlobalResponseMessage msg = message.cast<Web3GlobalResponseMessage>();
          if (msg.authenticated != null) {
            await updateAuthenticated(msg.authenticated!);
          }
          completer.complete(response: msg, requestId: requestId);
          break;
        case Web3MessageTypes.walletResponse:
          final Web3WalletResponseMessage msg = message.cast<Web3WalletResponseMessage>();
          if (msg.authenticated != null) {
            await updateAuthenticated(msg.authenticated!);
          }

          completer.complete(response: msg, requestId: requestId);
          break;
        case Web3MessageTypes.error:
          final msg = message.cast<Web3ExceptionMessage>();
          if (msg.authenticated != null) {
            await updateAuthenticated(msg.authenticated!);
          }
          completer.complete(response: msg, requestId: requestId);
          break;
        case Web3MessageTypes.chains:
          final Web3ChainMessage msg = message.cast<Web3ChainMessage>();
          final auth = msg.authenticated;
          updateAuthenticated(auth);
          break;
        default:
      }
    } on Web3RequestException catch (e) {
      final toMessage = e.toResponseMessage(requestId: requestId);
      completer.complete(response: toMessage, requestId: requestId);
    } catch (e, trace) {
      final toMessage = Web3RequestExceptionConst.internalErr("onWalletResponse",
              reason: e.toString(), trace: trace.toString())
          .toResponseMessage(requestId: requestId);
      completer.complete(response: toMessage, requestId: requestId);
    }
  }

  Future<void> _sendEventToClient(
    List<WalletConnectClientEvent> events,
  ) async {
    final namespaces = await generateNamespaces();
    if (namespaces != _session.namespaces) {
      _session = _session.copyWith(namespaces: namespaces);
      await sendEventToClient(
          WalletEventRequest(event: events, topic: _session.peerKey, session: _session));
      return;
    }
    await sendEventToClient(WalletEventRequest(event: events, topic: _session.peerKey));
  }

  Future<WalletConnectWalletMessageResponse> _requestCompleter(
      WalletConnectNetworkRequest params) async {
    final client = params.request?.network;
    final handler = _networks[client];
    try {
      final result = await _buildAndSendMessage(params: params);
      final Web3MessageCore response = result.$1;
      final Web3WalletRequestParams? request = result.$2;
      return switch (response.type) {
        Web3MessageTypes.globalResponse => await _finalizeGlobalResponse(
            message: params, response: response.cast(), params: request?.cast()),
        Web3MessageTypes.walletResponse => await handler!.finalizeWalletResponse(
            message: params, response: response.cast(), params: request?.cast()),
        Web3MessageTypes.error => await handler?.finalizeError(
                message: params, error: response.cast(), params: request?.cast()) ??
            WalletConnectWalletMessageResponse.fail(
                response.cast<Web3ExceptionMessage>()),
        _ => WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.invalidRequest.toResponseMessage())
      };
    } finally {
      handler?.onRequestDone(params);
    }
  }

  Future<(Web3MessageCore, Web3WalletRequestParams?)> _buildAndSendMessage({
    WalletConnectNetworkRequest? params,
    Web3MessageCore? message,
  }) async {
    final completer = this.completer.nextRequest;
    final String requestId = completer.id;
    try {
      if (message == null) {
        if (params == null) {
          throw Web3RequestExceptionConst.invalidRequest;
        }
        Web3GlobalRequestMethods? method =
            Web3GlobalRequestMethods.fromName(params.method);
        if (method != null) {
          message = await _onGlobalRequest(
              method: method, network: params.request?.network, request: params);
        } else {
          final handler = _networks[params.request?.network];
          if (handler == null) {
            throw Web3RequestExceptionConst.invalidRequest;
          }
          message ??= await handler.request(params);
        }
      }

      switch (message.type) {
        case Web3MessageTypes.globalResponse:
        case Web3MessageTypes.walletResponse:
          this.completer.complete(response: message, requestId: requestId);
          break;
        default:
          final msg = WalletMessageRequest(
              message: message.cast(),
              requestId: requestId,
              topic: _session.peerKey,
              wcRequestId: params?.wcRequestId);
          sendMessagetowallet(msg);
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

  Future<IResult<WalletConnectWalletMessageResponse>> onClientRequest(
      WalletConnectClientRequestParams sessionRequest) async {
    try {
      final handler = _networks[sessionRequest.network];
      if (handler == null) throw Web3RequestExceptionConst.networkDoesNotExists;
      final request = WalletConnectNetworkRequest.network(
          method: sessionRequest.method, request: sessionRequest);
      final result = await _requestCompleter(request);
      return ResultOk(result);
    } on Web3RequestException catch (e) {
      return ResultOk(WalletConnectWalletMessageResponse.fail(e.toResponseMessage()));
    } catch (e, trace) {
      return ResultOk(WalletConnectWalletMessageResponse.fail(
          Web3RequestExceptionConst.internalErr("onClientRequest",
                  reason: e.toString(), trace: trace.toString())
              .toResponseMessage()));
    }
  }

  Future<WCSessionNamespaces> generateNamespaces() async {
    final namespaces =
        await Future.wait(_networks.values.map((e) => e.generateNamespace()));
    return WCSessionNamespaces(namespaces.expand((e) => e).toList());
  }

  Future<IResult<bool>> activeSession(WalletConnectNetworkRequest request) async {
    if (_session.isActive) {
      return ResultErr.fromException(
          Web3RequestExceptionConst.internalErr("activeSession"));
    }
    final response = await _requestCompleter(request);
    final isActive = response.type == WalletConnectWalletMessageResponseType.success;
    Logging.error(
        when: () => !isActive,
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "activeSession",
            msg: "Active session failed: ${response.data}"));
    _session = _session.copyWith(isActive: isActive);
    return ResultOk(isActive);
  }
}
