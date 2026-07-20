import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/storage/web3_storage.dart';

class WalletConnectStorage with DisposableMixin, StreamStateController {
  final IWeb3StorageManager web3Storage;
  final _lock = SafeAtomicLock();
  bool _isReady = false;
  Map<String, WCSession> _sessions = {};
  Map<int, BridgeRequestMessage> _pendingMessage = {};

  WalletConnectStorage(this.web3Storage);

  WCSession? getSession({String? topic, String? peerKey}) {
    if (topic != null) {
      return _sessions[topic];
    } else if (peerKey != null) {
      return _sessions.values.firstWhereNullable((e) => e.peerKey == peerKey);
    }
    return null;
  }

  Future<IResult<void>> _deletePendingMessage(int id) async {
    final msg = _pendingMessage.remove(id);
    if (msg?.storageType == PublishMessageStorageType.memory) {
      return ResultOk.okVoid;
    }
    return await web3Storage.wcRemovePendingMessage(id);
  }

  Future<IResult<void>> _savePendingMessage(BridgeRequestMessage message) async {
    final clientMessage = message.clientMessage;
    return clientMessage.andThenAsync((clientMessage) async {
      _pendingMessage[message.correlationId] = message;

      if (message.storageType == PublishMessageStorageType.memory) {
        return ResultOk.okVoid;
      }
      return await web3Storage.wcSavePendingMessage(clientMessage);
    });
  }

  Future<IResult<void>> setPendingMessage(BridgeRequestMessage message) async {
    return await _lock.run(() async {
      final id = message.correlationId;
      final status = message.status;
      Logging.info(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "setPendingMessage",
            msg:
                "{id:${message.correlationId}, type:${message.storageType}, topic:${message.session.topic}, status: ${message.status}}"),
      );
      if (!status.isPending) {
        return await _deletePendingMessage(id);
      }
      if (_pendingMessage.containsKey(id)) return ResultOk.okVoid;
      return _savePendingMessage(message);
    });
  }

  List<BridgeRequestMessage> getPendingMessages() {
    // final messages = _pendingMessage.values.where((e) => !e.isExpired()).toList();
    // List<BridgeRequestMessage> bridgeMessage = [];
    // for (final i in messages) {
    //   final session = _sessions[i.topic] ?? i.session;
    //   if (session == null) continue;
    //   bridgeMessage
    //       .add(BridgeRequestMessage.fromPublishMessage(message: i, session: session));
    // }
    return _pendingMessage.values.toList();
  }

  Future<IResult<void>> setSession(WCSession session) async {
    session = session.copyWith(latestAction: DateTime.now());
    final result = await web3Storage.wcSaveSession(session);
    return result.map((_) {
      _sessions[session.topic] = session;
      notify();
    });
  }

  Future<IResult<void>> deleteSesshins() async {
    final result = await web3Storage.wcRemoveSessions();
    return result.map((_) {
      _sessions.clear();
      notify();
    });
  }

  Future<IResult<WCSession?>> deleteSession(String topic) async {
    final session = _sessions[topic];
    final pendingMessage = _pendingMessage.entries
        .where((e) => e.value.session.topic == topic)
        .map((e) => e.key)
        .toList();
    _pendingMessage.removeWhere((k, _) => pendingMessage.contains(k));
    final remove = await web3Storage.wcRemovePendingMessages(ids: pendingMessage);
    return remove.andThenAsync((e) async {
      final result = await web3Storage.wcRemoveSession(topic);
      return result.map((_) {
        _sessions.remove(topic);
        notify();
        return session;
      });
    });
  }

  List<WCSession> getActiveSessions() {
    final sessions = _sessions.values.where((e) => !e.isExpired).toList();
    sessions.sort((a, b) => b.latestAction.compareTo(a.latestAction));
    return sessions;
  }

  List<WCSession> getAllSessions() {
    // final sessions = _sessions.values.where((e) => !e.isExpired).toList();
    // sessions.sort((a, b) => b.latestAction.compareTo(a.latestAction));
    return _sessions.values.toList();
  }

  Future<IResult<Map<String, WCSession>>> _getSessions(
    List<RelayClientPublish> messages,
  ) async {
    final data = await web3Storage.wcGetAllSessions();
    return data.map((sessions) {
      // final sessions = data.map((session) {
      //   // final topicMessages = messages.where((e) => e.topic == session.topic);
      //   // session.idGenerator
      //   //     .updateState(topicMessages.expand((e) => [e.id, e.correlationId]).toList());
      //   return session;
      // }).toList();
      return {for (final i in sessions) i.topic: i};
    });
  }

  // Future<IResult<Map<String, WCSession>>> _initSessions(
  //   List<RelayClientPublish> messages,
  // ) async {
  //   final data = await web3Storage.wcGetAllSessions();
  //   return data.map((data) {
  //     final sessions = data.map((session) {
  //       final topicMessages = messages.where((e) => e.topic == session.topic);
  //       session.idGenerator
  //           .updateState(topicMessages.expand((e) => [e.id, e.correlationId]).toList());
  //       return session;
  //     }).toList();
  //     final expired = sessions.where((e) => e.isExpired).toList();
  //     final active = sessions.where((e) => !e.isExpired).toList();
  //     final topics = expired.map((e) => e.topic).toList();
  //     web3Storage.wcRemoveSessions(topics: topics);
  //     return {for (final i in active) i.topic: i};
  //   });
  // }

  // Future<IResult<Map<int, RelayClientPublish>>> _getPendingMessage() async {
  //   final data = await web3Storage.wcGetPendingMessages();
  //   return data.map((sessions) {
  //     final expired = sessions.where((e) => e.isExpired()).toList();
  //     final active = sessions.where((e) => !e.isExpired()).toList();
  //     final ids = expired.map((e) => e.correlationId).toList();
  //     web3Storage.wcRemovePendingMessages(ids: ids);
  //     return {for (final i in active) i.correlationId: i};
  //   });
  // }

  Future<IResult<Map<int, RelayClientPublish>>> _getPendingMessage() async {
    final data = await web3Storage.wcGetPendingMessages();
    return data.map((sessions) {
      return {for (final i in sessions) i.correlationId: i};
    });
  }

  Future<IResult<void>> init() async {
    return await _lock.run(() async {
      if (_isReady) return ResultOk(null);
      final pendingMessage = await _getPendingMessage();
      return pendingMessage.andThenAsync((messages) async {
        final sessions = await _getSessions(messages.values.toList());
        return sessions.map((sessions) {
          _sessions = sessions;
          Map<int, BridgeRequestMessage> pendingMessages = {};
          for (final i in messages.entries) {
            final session = _sessions[i.value.topic] ?? i.value.session;
            if (session == null) continue;
            pendingMessages[i.key] = BridgeRequestMessage.fromPublishMessage(
                message: i.value, session: session);
          }
          _pendingMessage = pendingMessages;
          notify();
          _isReady = true;
        });
      });
    });
  }

  Future<void> close() async {
    await _lock.run(() async {
      _sessions.clear();
      _pendingMessage.clear();
      _isReady = false;
    });
  }

  @override
  Future<void> dispose() async {
    await _lock.run(() async {
      _sessions.clear();
      _pendingMessage.clear();
      _isReady = false;
      super.dispose();
    });
  }
}
