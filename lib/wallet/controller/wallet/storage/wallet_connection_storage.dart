import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/repository/repository.dart';

abstract mixin class IWalletConnectionStorageManager {
  Future<IResult<void>> removePendingMessage(RelayClientPublish message);
  Future<IResult<void>> savePendingMessage(RelayClientPublish message);
  Future<IResult<RelayClientPublish?>> getPendingMessage(int id);
  Future<IResult<List<RelayClientPublish>>> getPendingMessages();
  Future<IResult<void>> handlePublishMessageStorage(RelayClientPublish message);
  void close();
  void dispose();
}

/// TODO
/// incomplete
class WalletConnectionStorageManager implements IWalletConnectionStorageManager {
  static const int messageId = 0;
  final StorageControllerDefault database;

  final Map<int, RelayClientPublish> _memoryMessages = {};
  final Set<int> _inDatabse = {};

  WalletConnectionStorageManager(String storageId, IAppDatabaseApi database)
      : database = StorageControllerDefault(
            tableId: storageId,
            storage: APPDatabaseConst.walletConnectionStorage,
            database: database);

  @override
  Future<IResult<void>> removePendingMessage(RelayClientPublish message) async {
    final id = message.correlationId;
    try {
      switch (message.storageType) {
        case PublishMessageStorageType.memory:
          _memoryMessages.remove(id);
          break;
        case PublishMessageStorageType.database:
          return database.removeStorages(
              key: "$id",
              storageId: messageId,
              actionId: StorageActionId.walletExternalConnection);
        case PublishMessageStorageType.unknown:
        case PublishMessageStorageType.none:
          assert(!_inDatabse.contains(id));
          break;
      }
      return ResultOk.okVoid;
    } finally {
      _inDatabse.remove(id);
    }
  }

  @override
  Future<IResult<void>> handlePublishMessageStorage(RelayClientPublish message) async {
    // assert(message.status != PublishMessageStatus.unknown,
    //     "Unknown message status.");
    // switch (message.status) {
    //   case PublishMessageStatus.pending:
    //     await savePendingMessage(message);
    //     break;
    //   case PublishMessageStatus.published:
    //     if (message.mode.requiredResult) {
    //       return;
    //     }
    //     await removePendingMessage(message);
    //     break;
    //   case PublishMessageStatus.expired:
    //   case PublishMessageStatus.complete:
    //     await removePendingMessage(message);
    //     break;
    //   case PublishMessageStatus.unknown:
    //     break;
    // }
    return ResultOk.okVoid;
  }

  @override
  Future<IResult<void>> savePendingMessage(RelayClientPublish message) async {
    final id = message.correlationId;
    try {
      switch (message.storageType) {
        case PublishMessageStorageType.memory:
          _memoryMessages[message.correlationId] = message;
          break;
        case PublishMessageStorageType.database:
          if (_inDatabse.contains(id)) {
            return ResultOk.okVoid;
          }
          return await database.insertStorage(
            key: "${message.correlationId}",
            value: message,
            storageId: messageId,
            actionId: StorageActionId.walletExternalConnection,
          );
        case PublishMessageStorageType.none:
        case PublishMessageStorageType.unknown:
          break;
      }
      return ResultOk.okVoid;
    } finally {
      _inDatabse.add(id);
    }
  }

  @override
  Future<IResult<RelayClientPublish?>> getPendingMessage(int id) async {
    final memoryMessage = _memoryMessages[id];
    if (memoryMessage != null) {
      return ResultOk(memoryMessage);
    }
    final data = await database.queryStorage(
      storageId: messageId,
      key: id.toString(),
      actionId: StorageActionId.walletExternalConnection,
    );
    return data.andThenAsync((e) {
      final data = e?.data;
      if (e == null || data == null) return ResultOk(null);
      final result = IResult.callSync(
        () => RelayClientPublish.deserialize(bytes: data),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "getPendingMessage",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((result, err) async {
        if (err != null) {
          final remove = await database.removeStorageOperation(
              operation: e.toRemoveOperation(),
              actionId: StorageActionId.walletExternalConnection);
          return remove.map((e) => null);
        }
        return ResultOk(result);
      });
    });
  }

  @override
  Future<IResult<List<RelayClientPublish>>> getPendingMessages() async {
    final data = await database.queriesStorage(
        storageId: messageId, actionId: StorageActionId.walletExternalConnection);
    final result = data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => RelayClientPublish.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "getPendingMessages",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  database.removeStorageOperation(
                      operation: e.toRemoveOperation(),
                      actionId: StorageActionId.walletExternalConnection);
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<RelayClientPublish>().toList());
    return result.map((e) {
      final messages = [...e, ..._memoryMessages.values];
      _inDatabse.addAll(messages.map((e) => e.correlationId));
      return messages;
    });
  }

  @override
  void dispose() {
    database.dispose();
  }

  @override
  void close() {
    _memoryMessages.clear();
  }
}
