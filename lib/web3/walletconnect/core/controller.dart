import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/storage/web3_storage.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/controller.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/storage/storage.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'session.dart';

class Web3WalletController implements IWeb3WalletConnectController {
  final TypeCbWcRequest sendRequest;
  final TypeCbWcAuthRequest authRequest;
  final TypeCbWcGetLocalAuth defaultAuth;
  final Map<String, Web3WalletConnectSessionHandler> sessions = {};
  final Map<String, Web3RequestWalletConnectApplicationInformation> __requests = {};
  final WalletConnectStorage _storage;
  final SafeAtomicLock _lock = SafeAtomicLock();
  final IBridgeClient client;
  final AppContext context;

  Web3WalletController({
    required this.sendRequest,
    required this.authRequest,
    required this.defaultAuth,
    required IWeb3StorageManager storage,
    required this.client,
    required this.context,
  }) : _storage = WalletConnectStorage(storage) {
    client.onWeb3Event.listen(_onEvent);
  }
  @override
  StreamValue<SocketConnectionStatus> get connectionStatus =>
      client.connectionStatus(BridgeProtocol.walletConnect);
  @override
  StreamValue<void> get onSessionUpdated => _storage.notifier;

  void _successRequest(String requestId) {
    final request = __requests.remove(requestId);
    request?.completeSuccess();
  }

  void _errorRequest(String requestId, {BaseAppException? error}) {
    final request = __requests.remove(requestId);
    request?.completeError(err: error);
  }

  @override
  Future<IResult<List<int>>> getSessionRequiredChainIds(
      {required WCSession session, Web3APPData? auth}) async {
    if (auth == null) {
      final local = await defaultAuth();
      if (local.isErr) return local.cast();
      auth = local.unwrap();
    }
    final localAuth = auth;

    final defaultNamespaces = await generateDefaultNamespace(auth: localAuth);
    return defaultNamespaces.andThenAsync((defaultNamespaces) {
      Set<String> chains = {
        ...defaultNamespaces.allowedNamespace(session.requiredNamespaces).chainIds,
      };
      if (chains.isEmpty) {
        chains = defaultNamespaces
            .allowedNamespace(session.optionalNamespaces)
            .chainIds
            .take(1)
            .toSet();
      }
      final networks = localAuth.chains.expand((e) => e.networks).toList();
      List<int> networkIds = [];
      for (final i in chains) {
        final network = networks.firstWhereOrNull((e) => e.isChain(i));
        if (network != null) networkIds.add(network.id);
      }
      return ResultOk(networkIds);
    });
  }

  Future<IResult<WCSessionNamespaces>> generateDefaultNamespace(
      {Web3APPData? auth}) async {
    Web3APPData? localAuth = auth;
    if (localAuth == null) {
      final local = await defaultAuth();
      if (local.isErr) return local.cast();
      localAuth = local.unwrap();
    }

    List<WCChainNamespace> wcNamespaces = [];
    for (final i in localAuth.chains) {
      final method = Web3NetworkRequestMethods.getMethods(i.networkType);
      final eventsNames =
          Web3NetworkEvent.getEvents(i.networkType).map((e) => e.name).toList();
      final namespace = WCChainNamespace(
          identifier: i.networkType.caip2,
          namespace: WCNamespace(
              chains: i.networks.map((e) => e.caip2).toList(),
              accounts: [],
              methods: method.expand((e) => e.walletConnectMethodNames).toList(),
              events: eventsNames));
      wcNamespaces.add(namespace);
    }
    final namespaces = WCSessionNamespaces(wcNamespaces, allowEmptyAccount: true);
    return ResultOk(namespaces);
  }

  Future<IResult<void>> _sendMessage(WalletMessageRequest request) async {
    final session = sessions[request.topic];
    assert(session != null, "session not found.");
    if (session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    final r = Web3RequestWalletConnectApplicationInformation(
        info: session.client, request: request.message, requestId: request.requestId);
    final id = request.wcRequestId ?? request.requestId;
    __requests[id] = r;
    final response = await sendRequest(r);
    return response.map((response) {
      session.onWalletResponse(message: response, requestId: request.requestId);
      if (request.wcRequestId == null) {
        _successRequest(request.requestId);
      }
    });
  }

  Future<IResult<void>> emitSessionEvent(
      {required List<List<WCActionSessionEvent>> events,
      required WCSession session}) async {
    for (final i in events) {
      for (final event in i) {
        if (session.namespaces.chainApproved(event.chainId)) {
          await client.sendWeb3Request(
              action: event,
              session: session,
              storage: PublishMessageStorageType.database);
        }
      }
    }
    return ResultOk.okVoid;
  }

  Future<void> _sendEvent(WalletEventRequest request) async {
    final session = sessions[request.topic];
    if (session == null || !session.session.isActive) return;
    final events = request.event.map((e) => e.generateEvents()).toList();
    final updateSession = request.session;
    if (updateSession != null) {
      await _storage.setSession(updateSession);
      await client.sendWeb3Request(
          action: WCActionSessionUpdate(namespaces: updateSession.namespaces),
          storage: PublishMessageStorageType.database,
          session: session.session);
    }
    await emitSessionEvent(events: events, session: session.session);
  }

  @override
  WCSession? getSession({String? topic, String? peerKey}) {
    return _storage.getSession(topic: topic, peerKey: peerKey);
  }

  Future<IResult<Web3WalletConnectSessionHandler?>> _getInternalSession(
      String topic) async {
    Web3WalletConnectSessionHandler? handler =
        sessions.values.firstWhereOrNull((e) => e.topic == topic);
    if (handler != null) {
      return ResultOk(handler);
    }
    final session = getSession(topic: topic);
    if (session == null) return ResultOk(null);
    final clientId = session.peerKey;
    final metadata = session.peer.metadata;
    final client = Web3ClientInfo.walletConnect(
        clientId: clientId,
        url: metadata.url,
        name: metadata.name,
        description: metadata.description,
        faviIcon: metadata.icons
            .map((e) => APPImage.network(e))
            .whereType<APPImage>()
            .firstOrNull);
    final auth = await authRequest(client, false);
    return auth.andThenAsync((auth) async {
      if (auth == null) return ResultOk(null);
      final handler = Web3WalletConnectSessionHandler(
          sendMessagetowallet: _sendMessage,
          sendEventToClient: _sendEvent,
          context: context,
          client: client,
          session: session);
      sessions[clientId] = handler;
      await handler.updateAuthenticated(auth.dappData);
      return ResultOk(handler);
    });
  }

  IResult<int> _findNextSessionId() {
    int id = BinaryOps.mask8 + 1;
    final allSessions = _storage.getActiveSessions().map((e) => e.clientId).toList();
    while (allSessions.contains(id)) {
      id++;
    }
    if (id >= BinaryOps.mask16) {
      return ResultErr.fromException(BridgeExceptionConst.tooManyWeb3Clients);
    }
    return ResultOk(id);
  }

  /// wallet connect
  Future<IResult<WCSessionProposeResponse>> _onSessionPropose(
      BridgeEventWeb3PairingPropose request) async {
    final proposer = request.request.proposer;
    final clientId = proposer.publicKey;
    final metadata = proposer.metadata;
    assert(!sessions.containsKey(clientId));

    final defaultNamespaces = await generateDefaultNamespace();
    return defaultNamespaces.andThenAsync((defaultNamespaces) async {
      if (!defaultNamespaces.allowNamespace(request.request.requiredNamespaces)) {
        return ResultErr.fromException(
            BridgeExceptionConst.requiredNamespacesNotSupported);
      }

      Set<String> chains = {
        ...defaultNamespaces
            .allowedNamespace(request.request.requiredNamespaces)
            .chainIds,
      };
      if (chains.isEmpty) {
        chains = defaultNamespaces
            .allowedNamespace(request.request.optionalNamespaces)
            .chainIds
            .take(1)
            .toSet();
      }
      final client = Web3ClientInfo.walletConnect(
          clientId: clientId,
          url: metadata.url,
          name: metadata.name,
          description: metadata.description,
          faviIcon: metadata.icons
              .map((e) => APPImage.network(e))
              .whereType<APPImage>()
              .firstOrNull);
      Duration? timeout = request.timeout();
      if (timeout == null) {
        return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
      }

      final auth = await authRequest(client, true);
      return auth.andThenAsync((auth) async {
        if (auth == null) {
          return ResultOk(WCSessionProposeReject(
              request: request, exception: Web3RequestExceptionConst.bannedHost));
        }
        final sharedKey = await context.cryptoLib.excute(
            CryptoRequestGenerateWalletConnectSymKeyInfo(
                publicKey: BytesUtils.fromHexString(clientId),
                privateKey: auth.authentication.token.privateKey));
        return sharedKey.andThenAsync((sharedKey) {
          final id = _findNextSessionId();
          return id.andThenAsync((id) async {
            WCSession createSession = WCSession(
                topic: sharedKey.topicAsHex,
                symkey: sharedKey.symkey,
                clientId: id,
                relay: WCProtocolOptions(protocol: BridgeConstants.wcRelayProtocol),
                namespaces: WCSessionNamespaces([]),
                optionalNamespaces: request.request.optionalNamespaces,
                requiredNamespaces: request.request.requiredNamespaces,
                peer: proposer,
                expireTime: BridgeUtils.wcDefaultSessionExpireTime());
            final handler = Web3WalletConnectSessionHandler(
                sendMessagetowallet: _sendMessage,
                sendEventToClient: _sendEvent,
                client: client,
                context: context,
                session: createSession);
            await handler.updateAuthenticated(auth.dappData);
            sessions[clientId] = handler;
            final rId = request.correlationId.toString();
            final connectRequest = WalletConnectNetworkRequest.global(
                method: Web3GlobalRequestMethods.connect.name,
                chains: chains.toList(),
                wcRequestId: rId);
            final active = await handler.activeSession(connectRequest).timeout(
              timeout,
              onTimeout: () {
                _errorRequest(rId, error: BridgeExceptionConst.pairingRequestTimeout);
                return ResultErr.fromException(
                    BridgeExceptionConst.pairingRequestTimeout);
              },
            );
            return active.andThenAsync((active) async {
              if (!active) {
                sessions.remove(clientId);
                return ResultOk(WCSessionProposeReject(
                    request: request,
                    exception: Web3RequestExceptionConst.rejectedByUser));
              }
              await _storage.setSession(handler.session);
              return ResultOk(WCSessionProposeAprove(
                  request: request,
                  publicKey: sharedKey.publicKeyAsHex,
                  session: handler.session));
            });
          });
        });
      });
    });
  }

  Future<IResult<void>> _onSessionRequest(BridgeEventWeb3SessionRequest request) async {
    return await _lock.run(() async {
      final session = await _getInternalSession(request.session.topic);
      final timeout = request.timeout();
      if (timeout == null) return ResultOk.okVoid;

      return session.andThenAsync((session) async {
        if (session == null) {
          client.publish(BridgeRequestMessage.response(
              response: TopicResponseError.web3(
                  BridgeGenericError.userDisconnected.toRpcError()),
              session: request.session,
              correlationId: request.id));
          return ResultOk.okVoid;
        }

        final response = await session
            .onClientRequest(WalletConnectClientRequestParams(request))
            .timeout(timeout);
        return response.map((response) {
          final result = switch (response.type) {
            WalletConnectWalletMessageResponseType.success =>
              TopicResponseSuccess(response.data),
            WalletConnectWalletMessageResponseType.failed => () {
                final exp = response.data as Web3ExceptionMessage;
                return TopicResponseError.web3(
                    JsonRpcError(code: exp.code, message: exp.message));
              }(),
          };
          client.publish(BridgeRequestMessage.response(
              response: result, session: request.session, correlationId: request.id));
        }).mapErr((e) {
          final rId = request.id.toString();
          _errorRequest(rId, error: BridgeExceptionConst.sessionRequestExpired);
          return e.exception;
        });
      });
    });
  }

  Future<void> _onEvent(BridgeEventWeb3 event) async {
    switch (event) {
      case BridgeEventWeb3Connected():
        final pairing = _pairingSessions.values.toList();
        for (final i in pairing) {
          client.addAndSubscribeSession(i.$1);
        }
        final sessions = _storage.getAllSessions();
        for (final i in sessions) {
          if (i.isExpired) {
            final result = await _disconnectSession(i);
            result.map((e) {
              client.publish(e);
            });
            continue;
          }
          client.addAndSubscribeSession(i);
        }
        final messages = _storage.getPendingMessages();
        for (final i in messages) {
          client.publish(i);
        }
        break;

      case BridgeEventWeb3Disconnected():
        break;
      case BridgeEventWeb3PairingDelete(:final topic):
        final pairing = _pairingSessions[topic];
        pairing?.$2.completeError(BridgeExceptionConst.pairingDisconnected);
        break;
      case BridgeEventWeb3PairingPropose(:final topic):
        final pairing = _pairingSessions[topic];
        pairing?.$2.complete(ResultOk(event));
        break;
      case BridgeEventWeb3SessionRequest():
        _onSessionRequest(event);
        break;
      case BridgeEventWeb3SessionDelete(:final session, :final correlationId):
        final result = await _disconnectSession(session);
        result.map((e) => client.publish(BridgeRequestMessage.response(
            response: TopicResponseSuccess(true),
            session: session,
            storage: PublishMessageStorageType.memory,
            correlationId: correlationId)));
        break;
      case BridgeEventWeb3MessageStatus(:final message):
        await _storage.setPendingMessage(message);
        if (message.status.isPending) return;
        final rId = message.correlationId.toString();
        if (message.status.isPublished || message.status.isComplete) {
          _successRequest(rId);
        } else {
          _errorRequest(rId);
        }
        break;
    }
  }

  final Map<String, (BridgeSession, Completer<IResult<BridgeEventWeb3PairingPropose>>)>
      _pairingSessions = {};

  /// extenal methods
  @override
  Future<IResult<void>> pair(Uri uri,
      {OnceCancelableTemplate<BridgeEventWeb3PairingPropose>? cancelable}) async {
    final BridgeUri parsedUri = BridgeUtils.wcParseUri(uri);
    final String topic = parsedUri.topic;
    final methods = parsedUri.methods.map(BridgeKnownMethods.fromName);
    if (methods.any((e) => e == BridgeKnownMethods.unregisteredMethod)) {
      return ResultErr.fromException(BridgeExceptionConst.unsuportedMethod);
    }
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "pair",
            msg: "Create pairing for topic: $topic"));
    Duration? timeout = parsedUri.timeout();
    if (timeout == null) {
      return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
    }
    final pairingSession = BridgeSession(
        symKey: parsedUri.symkey,
        topic: topic,
        type: BridgeSessionType.pairingWb3,
        protocol: BridgeProtocol.walletConnect);
    await client.addAndSubscribeSession(pairingSession);
    final completer =
        cancelable?.completer ?? Completer<IResult<BridgeEventWeb3PairingPropose>>();
    _pairingSessions[topic] = (pairingSession, completer);

    timeout = parsedUri.timeout();
    if (timeout == null) {
      return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
    }
    final proposalRequest = (await completer.future.timeout(timeout, onTimeout: () {
      return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
    }));

    return proposalRequest.thenAsync(onErr: (error) {
      final exception = error.exception;
      if (exception != BridgeExceptionConst.pairingDisconnected ||
          exception == AppExceptionConst.requestCanceled) {
        disconnectPairing(pairingSession);
      }
      return error.cast<void>();
    }, onOk: (proposalRequest) async {
      final response = await _onSessionPropose(proposalRequest);
      return response.thenAsync(onErr: (error) {
        client
            .publish(
          BridgeRequestMessage.response(
              response: TopicResponseError.web3(
                  BridgeGenericError.userDisconnected.toRpcError()),
              session: pairingSession,
              storage: PublishMessageStorageType.memory,
              correlationId: proposalRequest.correlationId),
        )
            .then((_) {
          client.removeAndUnSubscribeSession(pairingSession);
        });
        return error.cast<void>();
      }, onOk: (response) async {
        switch (response) {
          case WCSessionProposeAprove(
              :var relayProtocol,
              :final publicKey,
              :final session,
              :final sessionProperties
            ):
            relayProtocol ??= BridgeConstants.wcRelayProtocol;
            final relay = WCProtocolOptions(protocol: relayProtocol);
            final result = await client.publish(
              BridgeRequestMessage.response(
                  response: TopicResponseSuccess(
                      WCActionResponsePropose(relay: relay, responderPublicKey: publicKey)
                          .toJson()),
                  session: pairingSession,
                  correlationId: proposalRequest.correlationId),
            );
            return result.mapErr((e) {
              disconnectPairing(pairingSession);

              return e.exception;
            }).andThenAsync((_) async {
              _pairingSessions.remove(pairingSession.topic);
              client.removeAndUnSubscribeSession(pairingSession);
              await client.addAndSubscribeSession(session);
              final settleRequest = WCActionSessionSettle(
                  relay: relay,
                  namespaces: session.namespaces,
                  sessionProperties: sessionProperties,
                  expiry: BridgeUtils.wcDefaultSessionExpire(),
                  controller: WCProposer(
                    publicKey: publicKey,
                    metadata: WCMetadata(
                        name: 'OnChain',
                        description: 'The best wallet in world',
                        url: 'https://github.com/mrtnetwork',
                        icons: []),
                  ));
              client.sendWeb3Request(action: settleRequest, session: session);
              return ResultOk.okVoid;
            });

          case WCSessionProposeReject err:
            client
                .publish(
              BridgeRequestMessage.response(
                  response: TopicResponseError.web3(err.toRpcError()),
                  session: pairingSession,
                  storage: PublishMessageStorageType.memory,
                  correlationId: proposalRequest.correlationId),
            )
                .then((e) {
              client.removeAndUnSubscribeSession(pairingSession);
            });
            return ResultErr.fromException(err.exception);
        }
      });
    });
  }

  @override
  Future<List<Web3ClientInfo>> getActiveSessions() async {
    final sessions = _storage.getActiveSessions();
    return sessions
        .map((e) => Web3ClientInfo.walletConnect(
            clientId: e.peerKey,
            url: e.peer.metadata.url,
            name: e.peer.metadata.name,
            description: e.peer.metadata.description,
            faviIcon: e.peer.metadata.icons
                .map((e) => APPImage.network(e))
                .whereType<APPImage>()
                .firstOrNull))
        .toList();
  }

  Future<IResult<BridgeRequestMessage>> _disconnectSession(WCSession session,
      {bool unsubscribe = true}) async {
    final error = BridgeGenericError.userDisconnected;
    final request = BridgeRequestMessage.action(
      action: WCActionSessionDelete(code: error.code, message: error.message),
      fixedId: null,
      session: session,
      mode: PublishMessageMode.publish,
      storage: PublishMessageStorageType.database,
    );
    final _ = await client.toPublishMessage(request);
    final save = await _storage.setPendingMessage(request);
    return save.andThenAsync((e) async {
      final result = await _storage.deleteSession(request.session.topic);
      return result.mapAsync((session) async {
        if (unsubscribe) {
          await client.removeAndUnSubscribeSession(request.session);
        }

        return request;
      });
    });
  }

  @override
  Future<IResult<void>> disconnectSession(Web3ClientInfo client) async {
    WCSession? session = sessions.remove(client.identifier)?.session;
    bool isAlive = session != null;
    if (session == null) {
      session = getSession(peerKey: client.identifier);
      if (session == null) return ResultOk.okVoid;
    }
    final result = await _disconnectSession(session, unsubscribe: !isAlive);
    return result.andThenAsync((message) async {
      if (isAlive) {
        final result = await this.client.publish(message);
        this.client.removeAndUnSubscribeSession(session!);
        return result;
      }
      this.client.publish(message);
      this.client.removeAndUnSubscribeSession(session!);
      return ResultOk.okVoid;
    });
  }

  Future<void> disconnectPairing(BridgeSession session) async {
    final pairing = _pairingSessions.remove(session.topic);
    if (pairing == null) return;
    await client.disconnectPairing(session);
  }

  @override
  Future<void> updateAuthenticated(Web3DappInfo app) async {
    final auth = app.dappData;
    Web3WalletConnectSessionHandler? handler = sessions[auth.applicationId];
    if (handler != null) {
      await handler.updateAuthenticated(auth);
      return;
    }
    final session = getSession(peerKey: auth.applicationId);
    if (session == null) return;
    handler = Web3WalletConnectSessionHandler(
        sendMessagetowallet: (message) {},
        context: context,
        sendEventToClient: (message) async {},
        client: app.clientInfo,
        session: session);
    await handler.updateAuthenticated(auth);
    await _storage.setSession(handler.session);
    client.sendWeb3Request(
        action: WCActionSessionUpdate(namespaces: handler.session.namespaces),
        storage: PublishMessageStorageType.database,
        session: handler.session);
  }

  @override
  Future<void> connect() async {
    await _lock.run(() async {
      await _storage.init();
      await client.init(
        protocols: [BridgeProtocol.walletConnect],
      );
    }, lockId: LockId.three);
  }

  @override
  Future<void> dispose() async {
    await _lock.run(() async {
      _pairingSessions.clear();
      _storage.dispose();
      await client.dispose();
    }, lockId: LockId.three);
  }

  @override
  Future<void> close() async {
    await _lock.run(() async {
      await client.close();
      await _storage.close();
    }, lockId: LockId.three);
  }
}
