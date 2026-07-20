import 'dart:async';

import 'package:blockchain_utils/crypto/crypto/chacha20poly1305/chacha20poly1305.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/models/device/device.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/context.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/completer.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';

abstract class CryptoWorkerController<READ extends IIsolateCryptoMessage,
    WRITE extends Object> {
  CryptoTransporterMain<READ, WRITE> get mainConnector;
  int get maxSyncThread;

  final sync = SafeAtomicLock();
  final List<PendingConnectorRequest> _pendigConnectorRequests = [];

  final Map<SyncWorkerMode, CryptoStreamTransporterMain<READ, WRITE>> _syncWorkers = {};

  // CryptoTransporterMain<READ, WRITE>? _mainTransport;

  late final List<SyncWorkerMode> availableWorkers;

  CryptoWorkerController() {
    availableWorkers = SyncWorkerMode.getAvailableSyncWokers(maxSyncThread);
  }

  Future<IResult<CryptoStreamTransporterMain>?> getOrCreateStreamConnectorInternal(
      {SyncWorkerMode? mode}) async {
    for (final i in _syncWorkers.values) {
      if (i.status.isIdle) {
        if (mode == null || mode == i.mode) return ResultOk(i);
      }
    }
    Future<IResult<CryptoStreamTransporterMain<READ, WRITE>>> crateConnector(
        SyncWorkerMode mode) async {
      final result = await createStreamConnector(mode);
      return result.map((connector) {
        _syncWorkers[mode] = connector;
        return connector;
      });
    }

    if (mode != null) {
      if (_syncWorkers.containsKey(mode)) return null;
      return crateConnector(mode);
    }
    for (final i in availableWorkers) {
      if (_syncWorkers.containsKey(i)) continue;
      return crateConnector(i);
    }

    return null;
  }

  Future<IResult<PendingConnectorResponse>?> getOrCreateConnector(
      PendingConnectorRequest request) async {
    final connector = await getOrCreateStreamConnectorInternal(mode: request.mode);
    return connector?.andThenAsync((connector) async {
      final result = await connector.getStreamResult(
        args: request.request,
        encryptPart: request.encryptPart,
      );
      return result.mapErr((e) {
        _syncWorkers.remove(connector.mode);
        connector.dispose();
        return e.exception;
      });
    });
  }

  Future<IResult<void>> processStreamConnectorRequest(
      PendingConnectorRequest request) async {
    return sync.run(() async {
      if (!_pendigConnectorRequests.contains(request)) {
        return ResultOk.okVoid;
      }
      final connector = await getOrCreateConnector(request);
      if (connector == null) {
        return ResultOk.okVoid;
      }
      final remove = _pendigConnectorRequests.remove(request);
      if (!request.complete(connector) && remove) {
        return connector.map((e) {
          final c = _syncWorkers.remove(e.mode);
          c?.dispose();
        });
      }
      return ResultOk.okVoid;
    }, lockId: LockId.two);
  }

  void addPendingConnectorRequest(PendingConnectorRequest request) {
    _pendigConnectorRequests.add(request);
    processStreamConnectorRequest(request);
  }

  void onSyncConnectorIdle(SyncWorkerMode _) {
    for (final i in _pendigConnectorRequests) {
      processStreamConnectorRequest(i);
    }
  }

  // void _onIsolateTerminated(SyncWorkerMode? mode) {
  //   assert(mode != null);
  //   sync.run(() {
  //     if (mode == null) return;
  //     final connector = _syncWorkers.remove(mode);
  //     connector?.onConnectorTerminated();
  //   }, lockId: switch (mode) { null => LockId.one, _ => LockId.two });
  // }

  CryptoStreamTransporterMain<READ, WRITE>? getSyncConnector(SyncWorkerMode mode) {
    return _syncWorkers[mode];
  }

  Future<IResult<PendingConnectorResponse>> getStreamConnector({
    required StreamArgsRequestable message,
    List<int>? encryptPart,
    SyncWorkerMode? mode,
  }) async {
    final request =
        PendingConnectorRequest(request: message, encryptPart: encryptPart, mode: mode);
    addPendingConnectorRequest(request);
    return await request.getConnection();
  }

  Future<IResult<CryptoTransporterMain<READ, WRITE>>> getConnector(
      {CryptoProcessLevel level = CryptoProcessLevel.normal}) async {
    return await sync.run(() async {
      if (level.isHigh) {
        final newConnection = await createMainConnector(level, fresh: true);
        if (newConnection.isErr) {
          return ResultErr.fromException(
              AppCryptoExceptionConst.failedToConnectToCryptoService);
        }
        final connection = newConnection.unwrap();
        return ResultOk(connection);
      }
      return ResultOk(mainConnector);
    });
  }

  Future<IResult<CryptoTransporterMain<READ, WRITE>>> createMainConnector(
      CryptoProcessLevel level,
      {bool fresh = false});

  Future<IResult<CryptoStreamTransporterMain<READ, WRITE>>> createStreamConnector(
      SyncWorkerMode mode);
}

abstract class CryptoRequestBuilder<READ extends IIsolateCryptoMessage,
    WRITE extends Object, MSG extends RequestableMessage> {
  final ChaCha20Poly1305 chacha;
  const CryptoRequestBuilder({required this.chacha});
  WRITE encodeMessage(
      {required List<int> request,
      required bool encrypted,
      required int requestId,
      List<int>? encryptedPart});
  CborMessageResponseArgs decodeResponse(READ msg) {
    try {
      if (msg.type.isEncrypted) {
        final encryptedMessage = msg.cast<IIsolateCryptoEncryptedMessage>();
        final decrypt = chacha.decrypt(
            encryptedMessage.nonceBytes(), encryptedMessage.messageBytes());
        if (decrypt == null) {
          return MessageArgsException(AppInternalError.internalError(
              "CryptoTransporter._parseMessage",
              reason: "Failed to decrypt response."));
        }
        return CborMessageResponseArgs.deserialize(decrypt);
      }
      return CborMessageResponseArgs.deserialize(msg.messageBytes());
    } catch (e, trace) {
      Logging.danger(
        fn: () => AppLogData(
          runtime: runtimeType,
          msg: "unexpected isolate message.",
          err: e,
          function: "parseMessage",
          trace: trace.toString(),
        ),
      );
      return MessageArgsException(AppInternalError.internalError(
          "CryptoTransporter._parseMessage",
          reason: "Unknown response."));
    }
  }

  WRITE getEncodedRequest(
      {required MSG args, List<int>? encryptPart, int requestId = 0}) {
    return encodeMessage(
        request: args.toCbor().encode(),
        encrypted: args.isEncrypted,
        requestId: requestId,
        encryptedPart: encryptPart);
  }
}

abstract class CryptoTransporter<READ extends IIsolateCryptoMessage, WRITE extends Object,
    MSG extends RequestableMessage> extends CryptoRequestBuilder<READ, WRITE, MSG> {
  // final ChaCha20Poly1305 chacha;
  final MessageChannel<WRITE, READ> connector;
  final Map<int, WorkerMessageCompleter> _requests = {};
  // final CryptoWorkerController controller;
  final _lock = SafeAtomicLock();

  int _requestId = 1;
  CryptoTransporter({required List<int> sharedKey, required this.connector})
      : super(chacha: ChaCha20Poly1305(sharedKey)) {
    connector.stream.listen(onMessage);
  }

  Future<WorkerMessageCompleter> getRequestId(RequestableMessage message) async {
    final int newId = _requestId++;
    try {
      final id = WorkerMessageCompleter(newId);
      _requests[newId] = id;
      return id;
    } finally {
      message.cancelable.addListener(() {
        return _requests[newId]?.cancel();
      });
    }
  }

  Future<IResult<void>> post(WRITE data) => connector.add(data);
  Future<IResult<void>> sentRequest(
      {required RequestableMessage request,
      required int requestId,
      required List<int>? encryptedPart}) async {
    return await post(encodeMessage(
        request: request.toCbor().encode(),
        encryptedPart: encryptedPart,
        encrypted: request.isEncrypted,
        requestId: requestId));
  }

  Duration buildRequestTimeout(RequestableMessage message) {
    int timeout = message.processTimeout.inSeconds;
    if (message.level == CryptoProcessLevel.high) {
      timeout *= 2;
    }
    if (Logging.mode == LoggerMode.debug) {
      timeout *= 6;
    }
    timeout = IntUtils.max(timeout, 60);
    return Duration(seconds: timeout);
  }

  AppEnvironment get environment;
  Future<IResult<MessageArgsComplete>> getResult(
      {required MSG args, List<int>? encryptPart});
  Future<void> dispose();
  void onMessage(READ msg);
  Future<void> onConnectorTerminated();
}

abstract class CryptoTransporterMain<READ extends IIsolateCryptoMessage,
    WRITE extends Object> extends CryptoTransporter<READ, WRITE, RequestableMessage> {
  final CryptoProcessLevel level;
  CryptoTransporterMain(
      {required super.sharedKey, required super.connector, required this.level});
  @override
  void onMessage(READ msg) {
    final response = decodeResponse(msg);
    _requests[msg.id]?.complete(response);
  }

  @override
  Future<IResult<MessageArgsComplete>> getResult(
      {required RequestableMessage args, List<int>? encryptPart}) async {
    final next = await getRequestId(args);
    final result =
        await sentRequest(request: args, requestId: next.id, encryptedPart: encryptPart);
    return (await result.andThenAsync((_) async {
      return await next.getResult<MessageArgsComplete>(buildRequestTimeout(args));
    }))
        .onComplete(
      (_, ___) {
        _requests.remove(next.id);
        if (level == CryptoProcessLevel.high) {
          dispose();
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    await _lock.run(() async {
      final request = _requests.values.toList();
      _requests.clear();
      for (final i in request) {
        i.close();
      }
      switch (connector) {
        case ISolateConnector<WRITE, READ> channel:
          await channel.closeConnection();
          break;
      }
    });
  }

  @override
  Future<void> onConnectorTerminated() async {
    final request = _requests.values.toList();
    _requests.clear();
    for (final i in request) {
      i.close();
    }
  }
}

abstract class CryptoStreamTransporterMain<READ extends IIsolateCryptoMessage,
    WRITE extends Object> extends CryptoTransporter<READ, WRITE, MessageArgsStream> {
  final SyncWorkerMode mode;
  SyncWorkerStatus _status = SyncWorkerStatus.idle;
  SyncWorkerStatus get status => _status;
  ActiveStreamConnectorData? _latestConnector;
  final CryptoWorkerController controller;
  CryptoStreamTransporterMain(
      {required super.sharedKey,
      required super.connector,
      required this.mode,
      required this.controller});

  @override
  Future<IResult<MessageArgsComplete>> getResult(
      {required MessageArgsStream args, List<int>? encryptPart}) async {
    if (args.streamId != _latestConnector?.streamId) {
      return ResultErr.fromException(
          AppCryptoExceptionConst.failedToConnectToCryptoService);
    }
    final next = await getRequestId(args);
    final result =
        await sentRequest(request: args, requestId: next.id, encryptedPart: encryptPart);
    return (await result.andThenAsync((_) async {
      return await next.getResult<MessageArgsComplete>(buildRequestTimeout(args));
    }))
        .onComplete(
      (_, __) {
        _requests.remove(next.id);
      },
    );
  }

  ///  timeout: this.connector.buildRequestTimeout(message)

  Future<IResult<PendingConnectorResponse>> getStreamResult(
      {required StreamArgsRequestable args, List<int>? encryptPart}) async {
    return await _lock.run(() async {
      _status = SyncWorkerStatus.busy;
      final next = await getRequestId(args);
      final result = await sentRequest(
          request: args, requestId: next.id, encryptedPart: encryptPart);
      return (await result.andThenAsync((_) async {
        final result =
            await next.getResult<MessageArgsStreamId>(buildRequestTimeout(args));
        return result.map((e) {
          final StreamController<MessageArgsStreamResponse> controller =
              StreamController();
          controller.onCancel = () {
            _lock.run(() async {
              if (_latestConnector?.streamId == e.streamId) {
                final message = MessageArgsStream.close(e.streamId);
                getResult(args: message).then((_) {});
              }
            });
          };
          _latestConnector = ActiveStreamConnectorData(
              streamId: e.streamId,
              controller: SafeStreamController(
                  controller: controller,
                  name: "CryptoStreamTransporterMain.getStreamResult"));
          return PendingConnectorResponse(id: e, mode: mode, stream: controller.stream);
        }).mapErr((e) {
          _status = SyncWorkerStatus.idle;
          return e.exception;
        });
      }))
          .onComplete(
        (_, __) {
          _requests.remove(next.id);
        },
      );
    });
  }

  Future<void> closeStream(String streamId) async {
    if (_latestConnector?.streamId == streamId) {
      onStreamClosed();
    }
  }

  void onStreamClosed() {
    _lock.run(() {
      final request = _requests.values.toList();
      _requests.clear();
      for (final i in request) {
        i.close();
      }
      _latestConnector?.close();
      _latestConnector = null;
      _status = SyncWorkerStatus.idle;
      controller.onSyncConnectorIdle(mode);
    });
  }

  @override
  void onMessage(READ msg) {
    final response = decodeResponse(msg);
    switch (response) {
      case MessageArgsStreamResponse msg:
        final connector = _latestConnector;
        assert(connector != null && connector.streamId == msg.streamId,
            "missing connector.");
        if (connector == null || connector.streamId != msg.streamId) return;
        if (msg.method == MessageArgsStreamMethod.close) {
          onStreamClosed();
          return;
        }
        _latestConnector?.addMessage(msg);

        break;
      default:
        _requests[msg.id]?.complete(response);
        break;
    }
  }

  @override
  Future<void> dispose() async {
    onStreamClosed();
    switch (connector) {
      case ISolateConnector<WRITE, READ> channel:
        await channel.closeConnection();
        break;
    }
  }

  @override
  Future<void> onConnectorTerminated() async {
    onStreamClosed();
  }
}

abstract class MainCryptoResponseBuilder<READ extends IIsolateCryptoMessage,
    WRITE extends Object> extends CryptoResponseBuilder<READ, WRITE, CryptoMessageArgs> {
  MainCryptoResponseBuilder({required super.chacha, required super.context});
}

abstract class CryptoResponseBuilder<READ extends IIsolateCryptoMessage,
    WRITE extends Object, MESSAGE extends RequestableMessage> {
  abstract final IsolateCryptoController<MESSAGE> crypto;
  final ChaCha20Poly1305 chacha;
  final AppContext context;
  CryptoResponseBuilder({required this.chacha, required this.context});
  Future<IResult<CborMessageResponseArgs>> processCrypto(
      MESSAGE message, int id, List<int>? encryptedPart) {
    return crypto.handleMessage(
        args: message, id: id, encryptedPart: encryptedPart, context: context);
  }

  IResult<MESSAGE> decodeMessage(List<int> bytse);
  Future<IResult<WRITE>> processMessage(READ msg) async {
    final id = msg.id;
    final encrypted = msg.type.isEncrypted;
    List<int> messageBytes = msg.messageBytes();
    if (encrypted) {
      final encryptedMessage = msg.cast<IIsolateCryptoEncryptedMessage>();
      final plainText = chacha.decrypt(encryptedMessage.nonceBytes(), messageBytes);
      if (plainText == null) {
        return ResultErr.fromException(AppInternalError.internalError("processMessage",
            reason: "Decryption message failed."));
      }
      messageBytes = plainText;
    }
    final message = decodeMessage(messageBytes);
    return message.andThenAsync((message) async {
      List<int>? encryptedPart;
      if (!encrypted) {
        final encMessage = msg.encryptPart();
        if (encMessage != null) {
          encryptedPart =
              chacha.decrypt(encMessage.nonceBytes(), encMessage.messageBytes());
          if (encryptedPart == null) {
            return ResultErr.fromException(AppInternalError.internalError(
                "processMessage",
                reason: "Decrypt encryption part failed."));
          }
        }
      }
      final response = await processCrypto(message, id, encryptedPart);
      return response.map((response) => encodeMessage(
          request: response.toCbor().encode(), encrypted: encrypted, requestId: id));
    });
  }

  WRITE encodeMessage(
      {required List<int> request, required bool encrypted, required int requestId});
  Future<WRITE> getEncodedResponse(READ message) async {
    final response = await processMessage(message);
    return await response.foldOneAsync((msg, error) async {
      return msg ??
          encodeMessage(
              request: MessageArgsException(error!).toCbor().encode(),
              encrypted: false,
              requestId: message.id);
    });
  }
}

abstract class CryptoTransporterIsolate<READ extends IIsolateCryptoMessage,
        WRITE extends Object, MESSAGE extends RequestableMessage>
    extends CryptoResponseBuilder<READ, WRITE, MESSAGE> {
  CryptoTransporterIsolate({required super.chacha, required super.context});
  @override
  IResult<MESSAGE> decodeMessage(List<int> bytse);

  Future<IResult<void>> add(WRITE msg);

  Future<void> onMessage(READ msg) async {
    final response = await getEncodedResponse(msg);
    await add(response);
  }

  Future<void> onClose();
}
