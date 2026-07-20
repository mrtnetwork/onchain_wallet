import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/repository/action/action.dart';

import 'database.dart';

abstract mixin class IStorageController {
  Future<IResult<void>> insertStorage(
      {required int storage,
      required String tableId,
      required StorageActionId actionId,
      int storageId = APPDatabaseConst.defaultStorageId,
      String? key,
      String? keyA,
      required List<int> value,
      DateTime? createdAt});
  Future<IResult<List<dynamic>>> batchStorageAction(List<IStorageAction> actions);
  Future<IResult<T>> storageAction<T>(IStorageAction<T> action);
  Future<IResult<T>> tableAction<T>(ITableAction<T> action);
  Future<IResult<ITableDataStructA?>> queryStorage({
    required int storage,
    required String tableId,
    required StorageActionId actionId,
    int storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
  });
  Future<IResult<List<ITableDataStructA>>> queriesStorage({
    required String tableId,
    required int storage,
    required StorageActionId actionId,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
    int? limit,
    int? offset,
    int? createdAtLt,
    int? createdAtGt,
    IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
  });
  Future<IResult<List<ITableDataStructA>>> queriesTable({
    required String tableId,
    int? storage,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
    int? limit,
    int? offset,
    int? createdAtLt,
    int? createdAtGt,
    IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
  });
  Future<IResult<void>> removeStorages({
    required int storage,
    required String tableId,
    required StorageActionId actionId,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
  });
  Future<IResult<void>> drop(String tableId);

  Future<IResult<void>> removeOperation({
    required ITableRemoveStructA operation,
    required StorageActionId actionId,
  });
}

abstract mixin class IDatabaseStorageController implements IStorageController {
  IResult<IAppDatabaseApi> database();

  @override
  Future<IResult<void>> insertStorage(
      {required int storage,
      required String tableId,
      required StorageActionId actionId,
      int storageId = APPDatabaseConst.defaultStorageId,
      String? key,
      String? keyA,
      required List<int> value,
      DateTime? createdAt}) async {
    return await storageAction<void>(StorageActionWrite(
        actionId: actionId.id,
        data: TableStructAStorageData(
            column: TableStructAStorageColums.write(
                storageId: storageId, key: key, keyA: keyA),
            data: value,
            createdAt: createdAt),
        tableId: tableId,
        storage: storage));
  }

  @override
  Future<IResult<ITableDataStructA?>> queryStorage({
    required int storage,
    required String tableId,
    required StorageActionId actionId,
    int storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
  }) async {
    final data = await storageAction<ITableDataStructA?>(StorageActionRead(
        actionId: actionId.id,
        query: TableStrucAQuery(
            column: TableStructAStorageColums.read(
                storageId: storageId, key: key, keyA: keyA)),
        tableId: tableId,
        storage: storage));
    return data;
  }

  @override
  Future<IResult<List<ITableDataStructA>>> queriesStorage({
    required String tableId,
    required int storage,
    required StorageActionId actionId,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
    int? limit,
    int? offset,
    int? createdAtLt,
    int? createdAtGt,
    IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
  }) async {
    TableStrucAQuery query = TableStrucAQuery(
        column: TableStructAStorageColums.read(
          storageId: storageId,
          key: key,
          keyA: keyA,
        ),
        limit: limit,
        offset: offset,
        createdAtGt: createdAtLt,
        createdAtLt: createdAtGt,
        ordering: ordering);
    final data = await storageAction<List<ITableDataStructA>>(StorageActionReadAll(
        query: query, tableId: tableId, storage: storage, actionId: actionId.id));
    return data;
  }

  @override
  Future<IResult<void>> removeStorages({
    required int storage,
    required String tableId,
    required StorageActionId actionId,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
  }) async {
    return await storageAction<void>(StorageActionRemove(
        actionId: actionId.id,
        query: TableStrucAQuery(
            column: TableStructAStorageColums.remove(
                storageId: storageId, key: key, keyA: keyA)),
        tableId: tableId,
        storage: storage));
  }

  @override
  Future<IResult<List<ITableDataStructA>>> queriesTable(
      {required String tableId,
      int? storage,
      int? storageId = APPDatabaseConst.defaultStorageId,
      String? key,
      String? keyA,
      int? limit,
      int? offset,
      int? createdAtLt,
      int? createdAtGt,
      IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc}) async {
    TableStrucAQuery query = TableStrucAQuery(
        column: TableStructAStorageColums.read(
          storageId: storageId,
          key: key,
          keyA: keyA,
        ),
        limit: limit,
        offset: offset,
        createdAtGt: createdAtLt,
        createdAtLt: createdAtGt,
        ordering: ordering);
    final data = await tableAction<List<ITableDataStructA>>(
        TableActionReadAll(query: query, tableId: tableId, storage: storage));
    return data;
  }

  @override
  Future<IResult<List<dynamic>>> batchStorageAction(
      List<IStorageAction<Object?>> actions) async {
    final result = await IResult.anyError(actions.map((e) => storageAction(e)).toList());
    return result;
  }

  @override
  Future<IResult<T>> storageAction<T>(IStorageAction<T> action) async {
    return await database()
        .andThenAsync((database) async => await database.excuteStorage(action));
  }

  @override
  Future<IResult<T>> tableAction<T>(ITableAction<T> action) async {
    return await database()
        .andThenAsync((database) async => await database.excuteTable(action));
  }

  @override
  Future<IResult<void>> drop(String tableId) async {
    return await tableAction(TableActionDrop(tableId: tableId));
  }

  @override
  Future<IResult<void>> removeOperation({
    required ITableRemoveStructA operation,
    required StorageActionId actionId,
  }) async {
    return await removeStorages(
        storageId: operation.storageId,
        key: operation.key,
        keyA: operation.keyA,
        actionId: actionId,
        storage: operation.storage,
        tableId: operation.tableName);
  }
}

class StorageController with IDatabaseStorageController {
  // @override
  IAppDatabaseApi? _database;
  StorageController(this._database);

  @override
  IResult<IAppDatabaseApi> database() {
    final database = _database;
    if (database == null) {
      return ResultErr.fromException(WalletExceptionConst.storageIsNotAvailable);
    }
    return ResultOk(database);
  }

  void dispose() {
    _database = null;
  }
}

class StorageControllerDefault {
  final int storage;
  String? _tableId;
  final StorageController controller;
  String? get tableId => _tableId;
  StorageControllerDefault(
      {required String? tableId,
      required this.storage,
      required IAppDatabaseApi database})
      : _tableId = tableId,
        controller = StorageController(database);
  StorageControllerDefault.disposed(this.storage)
      : _tableId = null,
        controller = StorageController(null);

  Future<IResult<void>> insertStorage(
      {required StorageActionId actionId,
      int storageId = APPDatabaseConst.defaultStorageId,
      String? key,
      String? keyA,
      required AppSerialization value,
      DateTime? createdAt}) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return await controller.insertStorage(
          actionId: actionId,
          storage: storage,
          tableId: tableId,
          value: value.toCbor().encode(),
          createdAt: createdAt,
          key: key,
          keyA: keyA,
          storageId: storageId);
    });
  }

  Future<IResult<void>> insertStorageRaw(
      {required StorageActionId actionId,
      int storageId = APPDatabaseConst.defaultStorageId,
      String? key,
      String? keyA,
      required List<int> value,
      DateTime? createdAt}) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return await controller.insertStorage(
          actionId: actionId,
          storage: storage,
          tableId: tableId,
          value: value,
          createdAt: createdAt,
          key: key,
          keyA: keyA,
          storageId: storageId);
    });
  }

  Future<IResult<ITableDataStructA?>> queryStorage({
    required StorageActionId actionId,
    int storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
  }) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return controller.queryStorage(
          storage: storage,
          actionId: actionId,
          tableId: tableId,
          storageId: storageId,
          key: key,
          keyA: keyA);
    });
  }

  Future<IResult<List<int>?>> queryStorageData({
    required StorageActionId actionId,
    int storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
  }) async {
    final data = await queryStorage(
        key: key, keyA: keyA, storageId: storageId, actionId: actionId);
    return data.map((e) => e?.data);
  }

  Future<IResult<List<ITableDataStructA>>> _queriesStorage({
    required StorageActionId actionId,
    required int storage,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
    int? limit,
    int? offset,
    int? createdAtLt,
    int? createdAtGt,
    IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
  }) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return controller.queriesStorage(
          actionId: actionId,
          storage: storage,
          tableId: tableId,
          key: key,
          keyA: keyA,
          limit: limit,
          offset: offset,
          createdAtLt: createdAtLt,
          createdAtGt: createdAtGt,
          ordering: ordering,
          storageId: storageId);
    });
  }

  Future<IResult<List<ITableDataStructA>>> queriesStorage({
    required StorageActionId actionId,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
    int? limit,
    int? offset,
    int? createdAtLt,
    int? createdAtGt,
    IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
  }) async {
    return _queriesStorage(
        actionId: actionId,
        storage: storage,
        createdAtGt: createdAtGt,
        createdAtLt: createdAtLt,
        key: key,
        keyA: keyA,
        limit: limit,
        offset: offset,
        ordering: ordering,
        storageId: storageId);
  }

  Future<IResult<List<List<int>>>> queriesStorageData({
    required StorageActionId actionId,
    // required int storage,
    int? storageId = APPDatabaseConst.defaultStorageId,
    String? key,
    String? keyA,
    int? limit,
    int? offset,
    int? createdAtLt,
    int? createdAtGt,
    IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
  }) async {
    final data = await queriesStorage(
        actionId: actionId,
        createdAtGt: createdAtGt,
        createdAtLt: createdAtLt,
        key: key,
        keyA: keyA,
        limit: limit,
        offset: offset,
        ordering: ordering,
        storageId: storageId);
    return data
        .map((data) => data.where((e) => e.data != null).map((e) => e.data!).toList());
  }

  Future<IResult<void>> removeStorages(
      {int? storageId = APPDatabaseConst.defaultStorageId,
      required StorageActionId actionId,
      String? key,
      String? keyA}) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return controller.removeStorages(
        storage: storage,
        tableId: tableId,
        actionId: actionId,
        key: key,
        keyA: keyA,
        storageId: storageId,
      );
    });
  }

  Future<IResult<void>> _removeStorageData(
      {int? storageId = APPDatabaseConst.defaultStorageId,
      required StorageActionId actionId,
      required int storage,
      String? key,
      String? keyA}) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      if (key != null && keyA != null && storageId != null) {
        return await controller.storageAction(StorageActionWrite(
            data: TableStructAStorageData(
                data: null,
                column: TableStructAStorageColums.write(
                    storageId: storageId, key: key, keyA: keyA)),
            tableId: tableId,
            storage: storage,
            actionId: actionId.id));
      }
      final data = await _queriesStorage(
          actionId: actionId,
          storageId: storageId,
          key: key,
          keyA: keyA,
          storage: storage);
      return data.andThenAsync((data) {
        return batchStorageAction(data
            .where((e) => e.data != null)
            .map((e) => StorageActionWrite(
                data: TableStructAStorageData(
                    data: null,
                    column: TableStructAStorageColums.write(
                        storageId: e.storageId, key: e.key, keyA: e.keyA)),
                tableId: tableId,
                storage: e.storage,
                actionId: actionId.id))
            .toList());
      });
    });
  }

  Future<IResult<void>> removeStorageData(
      {int? storageId = APPDatabaseConst.defaultStorageId,
      required StorageActionId actionId,
      String? key,
      String? keyA}) async {
    return _removeStorageData(
        actionId: actionId, storage: storage, key: key, keyA: keyA, storageId: storageId);
  }

  Future<IResult<List<ITableDataStructA>>> queriesTable(
      {int? storage,
      int? storageId,
      String? key,
      String? keyA,
      int? limit,
      int? offset,
      int? createdAtLt,
      int? createdAtGt,
      IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc}) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return controller.queriesTable(
          tableId: tableId,
          storage: storage,
          key: key,
          keyA: keyA,
          limit: limit,
          offset: offset,
          createdAtLt: createdAtLt,
          createdAtGt: createdAtGt,
          ordering: ordering,
          storageId: storageId);
    });
  }

  Future<IResult<void>> drop() async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return await controller.drop(tableId);
    });
  }

  Future<IResult<List<dynamic>>> batchStorageAction(
      List<IStorageAction<Object?>> actions) async {
    return await controller.batchStorageAction(actions);
  }

  Future<IResult<List<dynamic>>> batchStorageRemove({
    required List<TableStructAStorageColums> actions,
    required StorageActionId actionId,
  }) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      return await controller.batchStorageAction(actions
          .map((e) => StorageActionRemove(
              query: TableStrucAQuery(column: e),
              actionId: actionId.id,
              tableId: tableId,
              storage: storage))
          .toList());
    });
  }

  Future<IResult<void>> removeTableOperation({
    required ITableRemoveStructA operation,
    required StorageActionId actionId,
  }) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      if (operation.tableName != tableId) {
        return ResultErr.fromException(
            AppInternalError.internalError("removeNetworkStorageOperation"));
      }
      return await _removeStorageData(
          storageId: operation.storageId,
          key: operation.key,
          keyA: operation.keyA,
          actionId: actionId,
          storage: operation.storage);
    });
  }

  Future<IResult<void>> removeStorageOperation({
    required ITableRemoveStructA operation,
    required StorageActionId actionId,
  }) async {
    final tableId = getTableId();
    return tableId.andThenAsync((tableId) async {
      if (operation.tableName != tableId || operation.storage != storage) {
        return ResultErr.fromException(
            AppInternalError.internalError("removeNetworkStorageOperation"));
      }
      return await _removeStorageData(
          storageId: operation.storageId,
          key: operation.key,
          keyA: operation.keyA,
          actionId: actionId,
          storage: storage);
    });
  }

  IResult<String> getTableId() {
    final id = _tableId;
    if (id == null) {
      return ResultErr.fromException(WalletExceptionConst.storageIsNotAvailable);
    }
    return ResultOk(id);
  }

  IResult<IAppDatabaseApi> getDatabase() {
    return controller.database();
  }

  void dispose() {
    controller.dispose();
    _tableId = null;
  }
}
