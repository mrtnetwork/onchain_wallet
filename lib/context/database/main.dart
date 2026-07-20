import 'dart:async';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/exception/exception.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/repository/core/database.dart';

class DefaultAppDatabase extends IAppDatabaseApi {
  final MessageChannel<ISolateMessageRequest<AppContextMessageDatabaseRequest>,
      ISolateMessageResponse<AppContextMessageDatabaseResponse>> connector;
  int _id = 0;

  final Map<int, Completer<IResult<AppContextMessageDatabaseResponse>>> _messages = {};
  DefaultAppDatabase({required this.connector}) {
    connector.stream.listen(onMessage);
  }
  Future<void> onMessage(
      ISolateMessageResponse<AppContextMessageDatabaseResponse> msg) async {
    final response = _messages.remove(msg.id);
    response?.complete(msg.message);
  }

  Future<IResult<AppContextMessageDatabaseResponse>> _send(
      AppContextMessageDatabaseRequest request) async {
    final id = _id++;
    final completer = Completer<IResult<AppContextMessageDatabaseResponse>>();
    _messages[id] = completer;
    final result = await connector.add(ISolateMessageRequest(id: id, message: request));
    return result.andThenAsync((_) async {
      final result = await completer.future.timeout(
        AppContextConst.databaseOperationTimeout,
        onTimeout: () {
          _messages.remove(id);
          return ResultErr.fromException(AppContextError.requestTimeout);
        },
      );
      return result;
    });
  }

  @override
  Stream<IStorageEvent<Object?>> listenOnTable(String tableId,
      {List<OnChainBrdigeSerializationIdentifier> actions =
          OnChainBrdigeSerializationIdentifier.values}) {
    return Stream.empty();
  }

  @override
  Future<IResult<T>> excuteStorage<T extends Object?>(IStorageAction<T> action) async {
    final request = AppContextMessageDatabaseRequestIStorageAction(action: action);
    final result = await _send(request);
    return result.mapCatch((e) {
      return switch (e) {
        AppContextMessageDatabaseResult(:final response) =>
          JsonParser.valueAs<T>(response),
        AppContextMessageDatabaseSerializableResult(:final response) =>
          JsonParser.valueAs<T>(action.decodeResponse(response)),
      };
    });
  }

  @override
  Future<IResult<T>> excuteTable<T extends Object?>(ITableAction<T> action) async {
    final request = AppContextMessageDatabaseRequestITableAction(action: action);
    final result = await _send(request);
    return result.mapCatch((e) {
      return switch (e) {
        AppContextMessageDatabaseResult(:final response) =>
          JsonParser.valueAs<T>(response),
        AppContextMessageDatabaseSerializableResult(:final response) =>
          JsonParser.valueAs<T>(action.decodeResponse(response)),
      };
    });
  }
}
