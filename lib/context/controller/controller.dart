import 'dart:async';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/database/core/interface.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/sync.dart';
import 'package:on_chain_wallet/context/netsdk/connector.dart';
import 'package:on_chain_wallet/context/types/block.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/transporter.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';

abstract class IIsolateAppContextConnectionController<
    CRYPTOREQUEST extends IIsolateCryptoMessage> {
  final MessageChannel<ISolateMessageResponse<AppContextMessageResponse>,
      ISolateMessageRequest<AppContextMessageRequest>> connector;
  final IsolateNetSdkConnector netsdk;
  final IDatabaseApi database;
  final DefaultAppContext context;
  final MainCryptoResponseBuilder<CRYPTOREQUEST, CRYPTOREQUEST> crypto;
  AppContextMessageCryptoResponse<CRYPTOREQUEST> createCryptoResponse(
      CRYPTOREQUEST response);
  AppEnvironment get environment => netsdk.netSdk.environment;
  final CancelableListener cancelableListener = CancelableListener();

  IIsolateAppContextConnectionController(
      {required this.connector,
      required this.netsdk,
      required this.database,
      required this.context,
      required this.crypto}) {
    connector.stream.listen(onMessage);
  }

  Future<IResult<AppContextMessageResponseSuccess>> fetchAndStoreNetworkData(
      AppContextMessageUtilsRequestFetchAndStoreBinary request) async {
    final transport = await context.utils.fetchAndStoreNetworkData(
      urls: request.urls,
      location: request.location,
      headers: request.headers,
      streamTimeout: request.streamTimeout,
      streamingId: request.streamTrackerId,
      timeout: request.streamTimeout,
      cancelable: cancelableListener,
      onProgress: (progress) {
        final identifier = request.streamTrackerId;
        if (identifier == null) return;
        connector.add(ISolateMessageResponse(
            id: -1,
            message: ResultOk(AppContextMessageUtilsResponseStreamProgress(
                progress: progress, identifier: identifier)),
            section: request.section,
            type: IsolateMessageTypes.utilsStreamProgress));
      },
    );
    return transport.map((_) => AppContextMessageResponseSuccess.fetchAndStoreBinary());
  }

  Future<IResult<AppContextMessageUtilsResponseGetData>> getData(
      AppContextMessageUtilsRequestGetData request) async {
    final data = await context.utils.getStoredData(request.location);
    return data.map((e) => AppContextMessageUtilsResponseGetData(e));
  }

  Future<IResult<AppContextMessageResponseSuccess>> storeOrRemoveData(
      AppContextMessageUtilsRequestStoreOrRemoveData request) async {
    final data = await context.utils
        .storeOrRemoveData(location: request.location, data: request.data);
    return data.map((e) => AppContextMessageResponseSuccess.storeOrRemoveData());
  }

  Future<IResult<AppContextMessageResponseSuccess>> storeFile(
      AppContextMessageUtilsRequestStoreFile request) async {
    final data =
        await context.utils.storeFile(location: request.location, file: request.file);
    return data.map((e) => AppContextMessageResponseSuccess.storeFile());
  }

  Future<IResult<AppContextMessageUtilsResponseVerifyData>> verifyData(
      AppContextMessageUtilsRequestVerifyData request) async {
    final data = await context.utils.verifyStoreData(request.location);
    return data.map((e) => AppContextMessageUtilsResponseVerifyData(e));
  }

  Future<IResult<AppContextMessageDatabaseResponse>> tableAction(
    ITableAction action,
  ) async {
    return await IResult.call(() async {
      final response = await database.tableAction(action);
      if (environment.isNative) {
        return AppContextMessageDatabaseResult(response: response);
      }
      return AppContextMessageDatabaseSerializableResult(
          response: action.encodeResponse(response));
    });
  }

  Future<IResult<AppContextMessageDatabaseResponse>> storageAction(
    IStorageAction action,
  ) async {
    return await IResult.call(() async {
      final response = await database.storageAction(action);
      if (environment.isNative) {
        return AppContextMessageDatabaseResult(response: response);
      }
      return AppContextMessageDatabaseSerializableResult(
          response: action.encodeResponse(response));
    });
  }

  Future<void> onMessage(ISolateMessageRequest<AppContextMessageRequest> request) async {
    final response = await onRequest(request.message);
    if (response == null) return;
    connector.add(ISolateMessageResponse.from(response: response, request: request));
  }

  Future<IResult<AppContextMessageResponse>?> onRequest(
      AppContextMessageRequest request) async {
    switch (request) {
      case AppContextMessageLoggingRequest(:final message):
        Logging.logMessage(message);
        return null;
      case AppContextMessageCryptoRequest<CRYPTOREQUEST>(:final message):
        final result = await crypto.getEncodedResponse(message);
        return ResultOk(createCryptoResponse(result));
      case AppContextMessageDatabaseRequestIStorageAction(:final action):
        return storageAction(action);
      case AppContextMessageDatabaseRequestITableAction(:final action):
        return tableAction(action);
      case AppContextMessageUtilsRequestFetchAndStoreBinary msg:
        return fetchAndStoreNetworkData(msg);
      case AppContextMessageUtilsRequestGetData msg:
        return getData(msg);
      case AppContextMessageUtilsRequestStoreOrRemoveData msg:
        return storeOrRemoveData(msg);
      case AppContextMessageUtilsRequestVerifyData msg:
        return verifyData(msg);
      case AppContextMessageUtilsRequestStoreFile msg:
        return storeFile(msg);
      case AppContextMessageNetSdkRequestTransport():
      case AppContextMessageNetSdkRequestRequest():
        return null;
      default:
        return onUnknownRequest(request);
    }
  }

  Future<IResult<AppContextMessageResponse>?> onUnknownRequest(
      AppContextMessageRequest request) async {
    return ResultErr<AppContextMessageResponse>.fromException(
        AppInternalError.internalError("Invalid request."));
  }
}

abstract class IsolateAppContextChildConnectionController<
    CREATECONNECTION extends AppContextMessageResponse,
    CRYPTOREQUEST extends IIsolateCryptoMessage,
    CHILD extends IsolateAppContextChildConnectionController<
        CREATECONNECTION,
        CRYPTOREQUEST,
        CHILD>> extends IIsolateAppContextConnectionController<CRYPTOREQUEST> {
  final IsolateAppContextMainConnectionController<CREATECONNECTION, CRYPTOREQUEST, CHILD>
      mainConnection;
  final SafeStreamController<ISolateMessageRequest<AppContextMessageRequest>> controller;
  IsolateAppContextChildConnectionController(
      {required super.connector,
      required super.netsdk,
      required super.database,
      required this.controller,
      required super.context,
      required super.crypto,
      required this.mainConnection});
  Map<String, List<int>> pendingTasks = {};

  @override
  Future<IResult<AppContextMessageResponse>?> onRequest(
      AppContextMessageRequest request) async {
    switch (request) {
      case AppContextMessageLockingTaskRequest locking:
        final result = await mainConnection.lockColumn(locking);
        result.map((e) {
          final ids = pendingTasks[locking.identifier] ??= [];
          ids.add(e.lockingId);
        });
        return result;
      case AppContextMessageReleaseTaskRequest release:
        final result = mainConnection.releaseTask(
            identifier: release.identifier, taskId: release.id);
        final ids = pendingTasks[release.identifier] ??= [];
        ids.remove(release.id);
        return result;
      case AppContextMessageShutdownRequest(:final connectionId):
        await mainConnection.shutdownConnection(connectionId);
        return null;
      default:
        return super.onRequest(request);
    }
  }

  Future<IResult<void>> shutdown() async {
    connector.dispose();
    final connections = pendingTasks.clone();
    pendingTasks.clear();
    for (final i in connections.entries) {
      final identifier = i.key;
      for (final id in i.value) {
        mainConnection.releaseTask(identifier: identifier, taskId: id);
      }
    }

    return ResultOk(null);
  }
}

abstract class IsolateAppContextMainConnectionController<
    CREATECONNECTION extends AppContextMessageResponse,
    CRYPTOREQUEST extends IIsolateCryptoMessage,
    CHILD extends IsolateAppContextChildConnectionController<
        CREATECONNECTION,
        CRYPTOREQUEST,
        CHILD>> extends IIsolateAppContextConnectionController<CRYPTOREQUEST> {
  final Map<String, CHILD> connections = {};
  final Map<String, AppContextLockingTask> columns = {};

  Future<IResult<AppContextMessageLockingTaskResponse>> lockColumn(
      AppContextMessageLockingTaskRequest request) async {
    final lock = columns[request.identifier] ??= AppContextLockingTask();
    final Completer<IResult<AppContextMessageLockingTaskResponse>> completer =
        Completer();
    lock.run(
      timeout: request.releaseTimeout,
      onRelease: (id) {
        if (completer.isCompleted) return false;
        completer.complete(ResultOk(AppContextMessageLockingTaskResponse(id)));
        return true;
      },
    );
    return await completer.future.timeout(
      request.timeout,
      onTimeout: () {
        final err = ResultErr<AppContextMessageLockingTaskResponse>.fromException(
            AppExceptionConst.timeout);
        completer.complete(err);
        return err;
      },
    );
  }

  IResult<AppContextMessageResponseSuccess> releaseTask(
      {required String identifier, required int taskId}) {
    final lock = columns[identifier];
    final release = lock?.release(taskId) ?? false;
    if (release) {
      return ResultOk(AppContextMessageResponseSuccess.releaseTask());
    }
    return ResultErr.fromException(
        AppInternalError.internalError("releaseTask", reason: "Task not found"));
  }

  IsolateAppContextMainConnectionController(
      {required super.connector,
      required super.netsdk,
      required super.database,
      required super.context,
      required super.crypto});

  Future<IResult<CREATECONNECTION>> createConnection();
  @override
  Future<IResult<AppContextMessageResponse>?> onRequest(
      AppContextMessageRequest request) async {
    switch (request) {
      case AppContextMessageLockingTaskRequest locking:
        return lockColumn(locking);
      case AppContextMessageReleaseTaskRequest release:
        return releaseTask(identifier: release.identifier, taskId: release.id);
      case AppContextMessageCreateConnectionRequest():
        return createConnection();
      default:
        return super.onRequest(request);
    }
  }

  Future<void> shutdownConnection(String connectionId) async {
    final connector = connections.remove(connectionId);
    await connector?.shutdown();
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "createConnection",
            msg: "AppContext shutdown: $connectionId"));
  }
}
