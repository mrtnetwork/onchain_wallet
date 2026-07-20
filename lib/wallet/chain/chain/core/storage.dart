part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class ChainStorageManager {
  final StorageControllerDefault database;
  final List<DefaultChainStorageId> chainStorageIds;

  /// use [NetworkType.id] for storage
  final NetworkType networkType;
  ChainStorageManager({
    required String id,
    required this.networkType,
    required IAppDatabaseApi database,
  })  : database = StorageControllerDefault(
            tableId: id, storage: networkType.id, database: database),
        chainStorageIds = switch (networkType) {
          NetworkType.monero => MoneroChainStorageId.values,
          NetworkType.zcash => ZcashChainStorageId.values,
          _ => DefaultChainStorageId.values,
        };

  Future<IResult<List<int>?>> queryChainStorageData({
    required DefaultChainStorageId storage,
    String? key,
    String? keyA,
  }) async {
    return database.queryStorageData(
        storageId: storage.storageId,
        actionId: StorageActionId.network,
        key: key,
        keyA: keyA);
  }

  Future<IResult<ITableDataStructA?>> queryChainStorage({
    required DefaultChainStorageId storage,
    String? key,
    String? keyA,
  }) async {
    return database.queryStorage(
        storageId: storage.storageId,
        actionId: StorageActionId.network,
        key: key,
        keyA: keyA);
  }

  Future<IResult<void>> insertChainStorage(
      {required AppSerialization value,
      required DefaultChainStorageId storage,
      String? key,
      String? keyA}) async {
    return database.insertStorage(
        actionId: StorageActionId.network,
        storageId: storage.storageId,
        key: key,
        keyA: keyA,
        value: value);
  }

  Future<IResult<void>> removeChainStorage(
      {StorageId? storage, String? key, String? keyA}) async {
    return await database.removeStorageData(
      storageId: storage?.storageId,
      key: key,
      keyA: keyA,
      actionId: StorageActionId.network,
    );
  }

  Future<IResult<void>> removeChainStorageOperation(ITableRemoveStructA operation) async {
    return await database.removeStorageOperation(
      operation: operation,
      actionId: StorageActionId.network,
    );
  }

  Future<IResult<List<WalletBackupChainRepository>>> readAllChainRepositories(
      {List<String> web3Identifier = const []}) async {
    final shared = await database.queriesStorage(actionId: StorageActionId.backup);
    return shared.map((shared) {
      List<WalletBackupChainRepository> chainRepositories = [];
      for (final i in shared) {
        if (i.storageId == DefaultChainStorageId.web3.storageId &&
            !web3Identifier.contains(i.key)) {
          continue;
        }
        final storage =
            chainStorageIds.firstWhereOrNull((e) => e.storageId == i.storageId);
        assert(storage != null, "unknow storage key ${i.storageId}");
        if (storage == null) continue;
        final data = i.data;
        if (data == null) continue;
        final repository = WalletBackupChainRepository(
            storageID: storage.storageId,
            value: data,
            identifier: i.key,
            identifier2: i.keyA,
            createdAt: i.createdAt,
            chainID: networkType.id);
        chainRepositories.add(repository);
      }

      return chainRepositories;
    });
  }

  void dispose() {
    database.dispose();
  }

  static List<StorageActionWrite> createRestoreBackupTableOperations({
    required List<WalletBackupNetworkRepository> repositories,
    required List<WalletBackupChainRepository> chainRepositories,
    required List<Web3ApplicationAuthentication> dapps,
    required Map<int, BackupChain> chains,
    required String id,
  }) {
    final int actionId = StorageActionId.restoreBackup.id;
    final actions = chains.values
        .expand((c) => [
              StorageActionWrite(
                  actionId: actionId,
                  data: TableStructAStorageData(
                      data: c.toChainCbor(id).encode(),
                      column: TableStructAStorageColums.write(
                          storageId: DefaultNetworkStorageId.account.storageId)),
                  tableId: id,
                  storage: c.network.value),
              ...c.addresses.map((e) => StorageActionWrite(
                  actionId: actionId,
                  data: TableStructAStorageData(
                      data: e.toCbor().encode(),
                      column: TableStructAStorageColums.write(
                        key: e.identifier,
                        storageId: DefaultNetworkStorageId.address.storageId,
                      )),
                  tableId: id,
                  storage: c.network.value)),
              ...repositories.where((e) => e.networkID == c.network.value).map((e) =>
                  StorageActionWrite(
                      actionId: actionId,
                      data: TableStructAStorageData(
                          createdAt: e.createdAt == null
                              ? null
                              : DateTimeUtils.fromSecondsSinceEpoch(e.createdAt!),
                          data: e.value,
                          column: TableStructAStorageColums.write(
                            key: e.identifier,
                            storageId: e.storageID,
                            keyA: e.identifier2,
                          )),
                      tableId: id,
                      storage: c.network.value))
            ])
        .toList();
    for (final type in NetworkType.values) {
      final repositories = chainRepositories.where((e) => e.chainID == type.id).toList();
      if (repositories.isEmpty) continue;
      for (final i in repositories) {
        final chainStorageIds = DefaultChainStorageId.fromNetwork(type);
        final storageKey =
            chainStorageIds.firstWhereOrNull((e) => e.storageId == i.storageID);
        if (storageKey == null) continue;
        final param = TableStructAStorageData(
          data: i.value,
          column: TableStructAStorageColums.write(
            storageId: i.storageID,
            key: i.identifier,
            keyA: i.identifier2,
          ),
          createdAt: i.createdAt == null
              ? null
              : DateTimeUtils.fromSecondsSinceEpoch(i.createdAt!),
        );
        actions.add(StorageActionWrite(
            data: param, tableId: id, storage: type.id, actionId: actionId));
      }
    }
    actions.addAll(dapps.map((e) => StorageActionWrite(
        data: TableStructAStorageData(
            data: e.toCbor().encode(),
            column: TableStructAStorageColums.write(
                storageId: APPDatabaseConst.defaultStorageId, key: e.applicationId)),
        tableId: id,
        storage: APPDatabaseConst.web3AuthStorage,
        actionId: actionId)));
    return actions;
  }
}

class NetworkStorageManager {
  final ChainStorageManager chainStorage;
  final StorageControllerDefault database;
  static const int maxAddressItemLimit = 300;
  final String id;
  final int storage;
  NetworkStorageManager._({
    required this.storage,
    required this.id,
    required NetworkType networkType,
    required IAppDatabaseApi database,
  })  : chainStorage =
            ChainStorageManager(id: id, networkType: networkType, database: database),
        database =
            StorageControllerDefault(tableId: id, storage: storage, database: database);
  factory NetworkStorageManager(
      {required WalletNetwork network,
      required String id,
      required IAppDatabaseApi database}) {
    return NetworkStorageManager._(
        storage: network.value, networkType: network.type, id: id, database: database);
  }

  Future<IResult<List<ITableDataStructA>>> queriesNetworkStorage(
      {required DefaultNetworkStorageId storage,
      String? keyA,
      int? offset,
      int? limit,
      IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc}) async {
    return await database.queriesStorage(
        key: null,
        storageId: storage.storageId,
        keyA: keyA,
        offset: offset,
        limit: limit,
        ordering: ordering,
        actionId: StorageActionId.chain);
  }

  Future<IResult<ITableDataStructA?>> queryNetworkStorage({
    required DefaultNetworkStorageId storage,
    String? keyA,
  }) async {
    return await database.queryStorage(
        actionId: StorageActionId.chain,
        storageId: storage.storageId,
        key: null,
        keyA: keyA);
  }

  Future<IResult<void>> insertNetworkStorage(
      {required AppSerialization value,
      required DefaultNetworkStorageId storage,
      String? keyA,
      DateTime? createdAt}) async {
    return await database.insertStorage(
        actionId: StorageActionId.chain,
        storageId: storage.storageId,
        key: null,
        keyA: keyA,
        value: value,
        createdAt: createdAt);
  }

  Future<IResult<void>> insertNetworkStorageRaw(
      {required List<int> value,
      required DefaultNetworkStorageId storage,
      String? keyA,
      DateTime? createdAt}) async {
    return await database.insertStorageRaw(
        actionId: StorageActionId.chain,
        storageId: storage.storageId,
        key: null,
        keyA: keyA,
        value: value,
        createdAt: createdAt);
  }

  Future<IResult<void>> removeNetworkStorage(
      {DefaultNetworkStorageId? storage, String? keyA}) async {
    return await database.removeStorageData(
      storageId: storage?.storageId,
      key: null,
      keyA: keyA,
      actionId: StorageActionId.chain,
    );
  }

  TableStructAColums createTableCulumn(
      {required DefaultNetworkStorageId storage, String? keyA}) {
    return TableStructAColums(
        tableName: id,
        storage: this.storage,
        storageId: storage.storageId,
        keyA: keyA ?? "");
  }

  Future<IResult<void>> removeNetworkStorageOperation(
      ITableRemoveStructA operation) async {
    return await database.removeStorageOperation(
      operation: operation,
      actionId: StorageActionId.chain,
    );
  }

  Future<IResult<List<WalletBackupNetworkRepository>>> readAllRepositories() async {
    final storages = DefaultNetworkStorageId.fromNetwork(chainStorage.networkType);
    final keys =
        await database.queriesStorage(actionId: StorageActionId.backup, storageId: null);
    return keys.map((keys) {
      List<WalletBackupNetworkRepository> chainRepositories = [];
      for (final i in keys) {
        final storage = storages.firstWhereOrNull((e) => e.storageId == i.storageId);
        if (storage == null || !storage.allowInBackup) {
          continue;
        }
        final data = i.data;
        if (data == null) continue;
        final repository = WalletBackupNetworkRepository(
            identifier: i.key,
            storageID: storage.storageId,
            value: data,
            networkID: database.storage,
            identifier2: i.keyA,
            createdAt: i.createdAt);
        chainRepositories.add(repository);
      }
      return chainRepositories;
    });
  }

  Future<IResult<void>> removeAccount(Chain chain) async {
    return await removeNetworkStorage();
  }

  Future<IResult<ITableDataStructA?>> queryChainStorage({
    required DefaultChainStorageId storage,
    String? key,
    String? keyA,
  }) async {
    return chainStorage.queryChainStorage(storage: storage, key: key, keyA: keyA);
  }

  Future<IResult<void>> insertChainStorage(
      {required AppSerialization value,
      required DefaultChainStorageId storage,
      String? key,
      String? keyA}) async {
    return await chainStorage.insertChainStorage(
      storage: storage,
      value: value,
      key: key,
      keyA: keyA,
    );
  }

  void dispose() {
    database.dispose();
    chainStorage.dispose();
  }
}

class NetworkAddressStorageManager {
  final StorageControllerDefault database;
  final String identifier;
  static const int maxAddressItemLimit = 300;
  NetworkAddressStorageManager._({
    required this.identifier,
    required this.database,
  });
  factory NetworkAddressStorageManager(
      {required WalletNetwork network,
      required String? id,
      required String identifier,
      required IAppDatabaseApi? database}) {
    return NetworkAddressStorageManager._(
        identifier: identifier,
        database: database == null
            ? StorageControllerDefault.disposed(network.value)
            : StorageControllerDefault(
                tableId: id, storage: network.value, database: database));
  }

  Future<IResult<List<ITableDataStructA>>> queriesNetworkStorage(
      {required DefaultNetworkStorageId storage,
      String? keyA,
      int? offset,
      int? limit,
      IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc}) async {
    return await database.queriesStorage(
        key: identifier,
        storageId: storage.storageId,
        keyA: keyA,
        offset: offset,
        limit: limit,
        ordering: ordering,
        actionId: StorageActionId.chain);
  }

  Future<IResult<ITableDataStructA?>> queryNetworkStorage({
    required DefaultNetworkStorageId storage,
    String? keyA,
  }) async {
    return await database.queryStorage(
        actionId: StorageActionId.chain,
        storageId: storage.storageId,
        key: identifier,
        keyA: keyA);
  }

  Future<IResult<void>> insertNetworkStorage(
      {required AppSerialization value,
      required DefaultNetworkStorageId storage,
      String? keyA,
      DateTime? createdAt}) async {
    return await database.insertStorage(
        actionId: StorageActionId.chain,
        storageId: storage.storageId,
        key: identifier,
        keyA: keyA,
        value: value,
        createdAt: createdAt);
  }

  Future<IResult<void>> insertNetworkStorageRaw(
      {required List<int> value,
      required DefaultNetworkStorageId storage,
      String? keyA,
      DateTime? createdAt}) async {
    return await database.insertStorageRaw(
        actionId: StorageActionId.chain,
        storageId: storage.storageId,
        key: identifier,
        keyA: keyA,
        value: value,
        createdAt: createdAt);
  }

  Future<IResult<void>> removeNetworkStorage(
      {DefaultNetworkStorageId? storage, String? keyA}) async {
    return await database.removeStorageData(
      storageId: storage?.storageId,
      key: identifier,
      keyA: keyA,
      actionId: StorageActionId.chain,
    );
  }

  Future<IResult<void>> removeNetworkStorageOperation(
      ITableRemoveStructA operation) async {
    if (operation.key != identifier) {
      return ResultErr.fromException(
          AppInternalError.internalError("removeNetworkStorageOperation"));
    }
    return await database.removeStorageOperation(
        // storageId: operation.storageId,
        // key: operation.key,
        // keyA: operation.keyA,
        actionId: StorageActionId.chain,
        operation: operation);
  }

  void dispose() {
    database.dispose();
  }
}
