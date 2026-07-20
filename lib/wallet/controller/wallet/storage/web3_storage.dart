import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';
import 'package:on_chain_wallet/repository/repository.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/activity.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

abstract mixin class IWeb3StorageManager {
  Future<IResult<Web3ApplicationAuthentication?>> readWeb3Permission(String identifier);
  Future<IResult<List<Web3AccountAcitvity>>> readWeb3ApplicationActivities(
      Web3ApplicationAuthentication permission);
  Future<IResult<void>> saveWeb3ApplicationActivity(
      {required Web3ApplicationAuthentication permission,
      required Web3AccountAcitvity activity});
  Future<IResult<void>> removeWeb3ApplicationActivities(
      Web3ApplicationAuthentication permission);
  Future<IResult<void>> savePermission(Web3ApplicationAuthentication permission);
  Future<IResult<void>> removeWeb3Permission(Web3ApplicationAuthentication permission);
  Future<IResult<List<Web3ApplicationAuthentication>>> readAllApplications();
  Future<IResult<void>> wcRemovePendingMessage(int id);
  Future<IResult<void>> wcSavePendingMessage(RelayClientPublish message);
  Future<IResult<void>> wcSaveSession(WCSession session);
  Future<IResult<void>> wcRemoveSessions({List<String>? topics});
  Future<IResult<void>> wcRemoveSession(String topic);
  Future<IResult<List<WCSession>>> wcGetAllSessions();
  Future<IResult<List<RelayClientPublish>>> wcGetPendingMessages();
  Future<IResult<void>> removeWeb3Operation(ITableRemoveStructA operation);
  Future<IResult<void>> wcRemovePendingMessages({List<int>? ids});
  void dispose();
}

/// identifier  [Web3ClientInfo.identifier] or [Web3ApplicationAuthentication.applicationId].
class Web3StorageManager implements IWeb3StorageManager {
  static const int web3WcSessionStorageId = 1;
  static const int web3WcMessageId = 2;
  static const int web3Activities = 3;
  final StorageControllerDefault database;
  Web3StorageManager(String storageId, IAppDatabaseApi database)
      : database = StorageControllerDefault(
            tableId: storageId,
            storage: APPDatabaseConst.web3AuthStorage,
            database: database);

  @override
  Future<IResult<void>> removeWeb3Operation(ITableRemoveStructA operation) async {
    return await database.removeStorageOperation(
      operation: operation,
      actionId: StorageActionId.web3,
    );
  }

  @override
  Future<IResult<Web3ApplicationAuthentication?>> readWeb3Permission(
      String identifier) async {
    final result = await database.queryStorage(
        storageId: APPDatabaseConst.defaultStorageId,
        actionId: StorageActionId.web3,
        key: identifier,
        keyA: '');
    return result.andThenAsync((e) {
      final data = e?.data;
      if (e == null || data == null) return ResultOk(null);
      final result = IResult.callSync(
        () => Web3ApplicationAuthentication.deserialize(bytes: data),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "readWeb3Permission",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((result, err) async {
        if (err != null) {
          final remove = await removeWeb3Operation(e.toRemoveOperation());
          return remove.map((e) => null);
        }
        return ResultOk(result);
      });
    });
  }

  @override
  Future<IResult<List<Web3AccountAcitvity>>> readWeb3ApplicationActivities(
      Web3ApplicationAuthentication permission) async {
    final data = await database.queriesStorage(
      storageId: web3Activities,
      key: permission.applicationId,
      actionId: StorageActionId.web3,
    );
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => Web3AccountAcitvity.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "readWeb3ApplicationActivities",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  removeWeb3Operation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<Web3AccountAcitvity>().toList());
  }

  @override
  Future<IResult<void>> saveWeb3ApplicationActivity(
      {required Web3ApplicationAuthentication permission,
      required Web3AccountAcitvity activity}) async {
    return await database.insertStorage(
        storageId: web3Activities,
        value: activity,
        key: permission.applicationId,
        actionId: StorageActionId.web3,
        keyA: activity.requestId);
  }

  @override
  Future<IResult<void>> removeWeb3ApplicationActivities(
      Web3ApplicationAuthentication permission) async {
    return await database.removeStorageData(
      storageId: web3Activities,
      key: permission.applicationId,
      actionId: StorageActionId.web3,
    );
  }

  @override
  Future<IResult<void>> savePermission(Web3ApplicationAuthentication permission) async {
    return await database.insertStorage(
      storageId: APPDatabaseConst.defaultStorageId,
      value: permission,
      key: permission.applicationId,
      actionId: StorageActionId.web3,
    );
  }

  @override
  Future<IResult<void>> removeWeb3Permission(
      Web3ApplicationAuthentication permission) async {
    return await database.removeStorageData(
      storageId: APPDatabaseConst.defaultStorageId,
      key: permission.applicationId,
      actionId: StorageActionId.web3,
    );
  }

  @override
  Future<IResult<List<Web3ApplicationAuthentication>>> readAllApplications() async {
    final data = await database.queriesStorage(
      storageId: APPDatabaseConst.defaultStorageId,
      actionId: StorageActionId.web3,
    );
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => Web3ApplicationAuthentication.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "readAllApplications",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  removeWeb3Operation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<Web3ApplicationAuthentication>().toList());
  }

  /// wallet connection sessions

  @override
  Future<IResult<void>> wcRemovePendingMessage(int id) async {
    return await database.removeStorages(
      key: "$id",
      storageId: web3WcMessageId,
      actionId: StorageActionId.walletConnect,
    );
  }

  @override
  Future<IResult<void>> wcSavePendingMessage(RelayClientPublish message) async {
    return await database.insertStorage(
      key: "${message.correlationId}",
      value: message,
      storageId: web3WcMessageId,
      actionId: StorageActionId.walletConnect,
    );
  }

  @override
  Future<IResult<void>> wcSaveSession(WCSession session) async {
    return await database.insertStorage(
      key: session.topic,
      value: session,
      storageId: web3WcSessionStorageId,
      actionId: StorageActionId.walletConnect,
    );
  }

  @override
  Future<IResult<void>> wcRemoveSessions({List<String>? topics}) async {
    if (topics != null) {
      final removeItems = topics
          .map((e) =>
              TableStructAStorageColums.remove(storageId: web3WcSessionStorageId, key: e))
          .toList();
      return await database.batchStorageRemove(
          actions: removeItems, actionId: StorageActionId.walletConnect);
    }
    return await database.removeStorages(
        storageId: web3WcSessionStorageId, actionId: StorageActionId.walletConnect);
  }

  @override
  Future<IResult<void>> wcRemoveSession(String topic) async {
    return await database.removeStorages(
        key: topic,
        storageId: web3WcSessionStorageId,
        actionId: StorageActionId.walletConnect);
  }

  @override
  Future<IResult<List<WCSession>>> wcGetAllSessions() async {
    final data = await database.queriesStorage(
        storageId: web3WcSessionStorageId, actionId: StorageActionId.walletConnect);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => WCSession.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "wcGetAllSessions",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  removeWeb3Operation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<WCSession>().toList());
  }

  @override
  Future<IResult<List<RelayClientPublish>>> wcGetPendingMessages() async {
    final data = await database.queriesStorage(
        storageId: web3WcMessageId, actionId: StorageActionId.walletConnect);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => RelayClientPublish.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "wcGetPendingMessages",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  removeWeb3Operation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<RelayClientPublish>().toList());
  }

  @override
  Future<IResult<void>> wcRemovePendingMessages({List<int>? ids}) async {
    if (ids != null) {
      final removeItems = ids
          .map((e) =>
              TableStructAStorageColums.remove(storageId: web3WcMessageId, key: "$e"))
          .toList();
      return database.batchStorageRemove(
          actions: removeItems, actionId: StorageActionId.walletConnect);
    }
    return await database.removeStorages(
        storageId: web3WcMessageId, actionId: StorageActionId.walletConnect);
  }

  @override
  void dispose() {
    database.dispose();
  }
}
