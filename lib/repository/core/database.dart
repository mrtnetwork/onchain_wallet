import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/repository/action/action.dart';

abstract class IAppDatabaseApi {
  const IAppDatabaseApi();
  Stream<IStorageEvent<Object?>> listenOnTable(String tableId,
      {List<OnChainBrdigeSerializationIdentifier> actions =
          OnChainBrdigeSerializationIdentifier.values});
  Future<IResult<T>> excuteStorage<T extends Object?>(IStorageAction<T> action);
  Future<IResult<T>> excuteTable<T extends Object?>(ITableAction<T> action);
  Future<IResult<ITableDataStructA?>> readColumn(TableStructAColums column,
      {StorageActionId actionId = StorageActionId.unknown}) async {
    final action = StorageActionRead(
        query: TableStrucAQuery(
            column: column.toStorageColumns(), encrypted: column.encrypted),
        tableId: column.tableName,
        storage: column.storage,
        actionId: actionId.id);
    return await excuteStorage(action);
  }

  Future<IResult<void>> removeColumn(TableStructAColums column,
      {StorageActionId actionId = StorageActionId.unknown}) async {
    final action = StorageActionRemove(
        query: TableStrucAQuery(column: column.toStorageColumns()),
        tableId: column.tableName,
        storage: column.storage,
        actionId: actionId.id);
    return await excuteStorage(action);
  }

  Future<IResult<void>> writeColumn(
      {required TableStructAColums column,
      required List<int> data,
      StorageActionId actionId = StorageActionId.unknown}) async {
    final action = StorageActionWrite(
        data: TableStructAStorageData(
            data: data, column: column.toStorageColumns(), encrypted: column.encrypted),
        tableId: column.tableName,
        storage: column.storage,
        actionId: actionId.id);
    return await excuteStorage(action);
  }
}

class DisabledAppDatabaseApi extends IAppDatabaseApi {
  @override
  Stream<IStorageEvent<Object?>> listenOnTable(String tableId,
      {List<OnChainBrdigeSerializationIdentifier> actions =
          OnChainBrdigeSerializationIdentifier.values}) {
    return Stream.empty();
  }

  @override
  Future<IResult<T>> excuteStorage<T extends Object?>(IStorageAction<T> action) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<T>> excuteTable<T extends Object?>(ITableAction<T> action) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}
