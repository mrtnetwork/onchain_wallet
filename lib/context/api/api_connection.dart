import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';

abstract class IAppContextRequestController<REQUEST extends AppContextMessageRequest,
    RESPONSE extends AppContextMessageResponse> {
  final MessageChannel<ISolateMessageRequest<REQUEST>, ISolateMessageResponse<RESPONSE>>
      connection;
  int _id = BinaryOps.maxUint32;
  final Map<int, Completer<IResult<AppContextMessageResponse>>> _messages = {};
  IAppContextRequestController({required this.connection}) {
    connection.stream.listen(_onMessage);
  }
  void onUnknownResponse(RESPONSE response) {}
  void _onMessage(ISolateMessageResponse<RESPONSE> msg) {
    final connection = _messages.remove(msg.id);
    connection?.complete(msg.message);
    if (connection != null) return;
    msg.message.map((msg) {
      onUnknownResponse(msg);
    });
  }

  Future<IResult<R>> sendRequest<R extends RESPONSE>(REQUEST message,
      {Duration? timeout}) async {
    final id = _id++;

    final result = await connection.add(ISolateMessageRequest(id: id, message: message));
    return result.andThenAsync((e) async {
      final completer = Completer<IResult<AppContextMessageResponse>>();
      _messages[id] = completer;
      final result = await completer.future.timeout(
        timeout ?? AppContextConst.defaultConnectionRequestTimeout,
        onTimeout: () {
          return ResultErr.fromException(AppExceptionConst.timeout);
        },
      );
      return result
          .mapErr((e) {
            Logging.danger(
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "sendRequest",
                  msg: "context api request failed:",
                  err: e.exception,
                  trace: e.trace),
            );
            return e.exception;
          })
          .mapCatch(
            (e) => e.cast<R>(),
            loggingMode: LoggerMode.danger,
            logging: (exception, trace) => AppLogData(
                runtime: runtimeType,
                function: "sendRequest",
                msg:
                    "Invalid response. expected: $R, response: ${result.ok().runtimeType}",
                err: exception,
                trace: trace.toString()),
          )
          .mapErr((e) {
            _messages.remove(id);
            return e.exception;
          });
    });
  }
}

abstract class IAppContextConnectionApi {
  IAppContextConnectionApi();

  Future<IResult<RESPOINSE>> sendRequest<RESPOINSE extends AppContextMessageResponse>(
      AppContextMessageRequest message,
      {Duration? timeout});

  Future<IResult<T>> lockingTask<T extends Object?>(
      {required String identifier,
      required Duration timeout,
      required Duration releaseTimeout,
      required Future<IResult<T>> Function() onLocking}) async {
    final response = await sendRequest<AppContextMessageLockingTaskResponse>(
        AppContextMessageLockingTaskRequest(
            identifier: identifier, timeout: timeout, releaseTimeout: releaseTimeout),
        timeout: timeout);
    return response.andThenAsync((e) async {
      final respone = await onLocking();
      await releaseTask(identifier: identifier, lockId: e.lockingId);
      return respone;
    });
  }

  Future<IResult<AppContextMessageResponseSuccess>> releaseTask(
      {required String identifier, required int lockId}) async {
    return await sendRequest<AppContextMessageResponseSuccess>(
        AppContextMessageReleaseTaskRequest(identifier: identifier, id: lockId));
  }
}

class AppContextConnectionApi extends IAppContextRequestController<
    AppContextMessageRequest,
    AppContextMessageResponse> implements IAppContextConnectionApi {
  AppContextConnectionApi({required super.connection});

  @override
  Future<IResult<T>> lockingTask<T extends Object?>(
      {required String identifier,
      required Duration timeout,
      required Duration releaseTimeout,
      required Future<IResult<T>> Function() onLocking}) async {
    final response = await sendRequest<AppContextMessageLockingTaskResponse>(
        AppContextMessageLockingTaskRequest(
            identifier: identifier, timeout: timeout, releaseTimeout: releaseTimeout),
        timeout: timeout);
    return response.andThenAsync((e) async {
      final respone = await onLocking();
      await releaseTask(identifier: identifier, lockId: e.lockingId);
      return respone;
    });
  }

  @override
  Future<IResult<AppContextMessageResponseSuccess>> releaseTask(
      {required String identifier, required int lockId}) async {
    return await sendRequest<AppContextMessageResponseSuccess>(
        AppContextMessageReleaseTaskRequest(identifier: identifier, id: lockId));
  }
}

class DisabledAppContextConnectionApi extends IAppContextConnectionApi {
  DisabledAppContextConnectionApi();

  @override
  Future<IResult<RESPOINSE>> sendRequest<RESPOINSE extends AppContextMessageResponse>(
      AppContextMessageRequest message,
      {Duration? timeout}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}
