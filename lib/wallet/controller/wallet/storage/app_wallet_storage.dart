import 'dart:async';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/repository/repository.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/storage/wallet_storage.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

class AppWalletStorageManager {
  final StorageControllerDefault database;
  // final MainTableDatabaseResources storage = MainTableDatabaseResources.hdWalletStorage;
  AppWalletStorageManager(IAppDatabaseApi database)
      : database = StorageControllerDefault(
            tableId: MainTableDatabaseResources.hdWalletStorage.tableId,
            storage: MainTableDatabaseResources.hdWalletStorage.storage,
            database: database);

  Future<IResult<HDWalletsKeys>> _verifyWalletKeys(HDWalletsKeys keys) async {
    if (keys.wallets.isEmpty) return ResultOk(keys);
    final database = this.database.getDatabase();
    return database.andThenAsync((database) async {
      final storages =
          keys.wallets.map((e) => WalletStorageManager(e.key, database)).toList();
      try {
        final exitWallets =
            await IResult.anyError(storages.map((e) => e.storageExists()));
        return exitWallets.map((exitWallets) {
          List<HdWalletKey> currentKeys = keys.wallets;
          assert(
              exitWallets.length == currentKeys.length, "Unexpected database response.");
          List<HdWalletKey> existsWallets = [];
          for (final i in exitWallets.indexed) {
            if (i.$2) {
              existsWallets.add(currentKeys.elementAt(i.$1));
            }
          }
          return HDWalletsKeys(wallets: existsWallets, currentWallet: keys.currentWallet);
        });
      } finally {
        for (final i in storages) {
          i.dispose();
        }
      }
    });
  }

  Future<IResult<HDWalletsKeys>> saveHdWalletKeys(HDWalletsKeys keys) async {
    final storage = MainTableDatabaseResources.hdWalletStorage;
    final result = await database.insertStorage(
        storageId: storage.storageId, actionId: StorageActionId.walletKeys, value: keys);
    return result.map((_) => keys);
  }

  Future<IResult<HDWalletsKeys>> readWallet() async {
    final storage = MainTableDatabaseResources.hdWalletStorage;
    final result = await database.queryStorage(
      storageId: storage.storageId,
      key: storage.key,
      keyA: storage.keyA,
      actionId: StorageActionId.walletKeys,
    );
    return result.andThenAsync((e) {
      final data = e?.data;
      if (e == null || data == null) return ResultOk(HDWalletsKeys());
      final result = IResult.callSync(
        () => HDWalletsKeys.deserialize(bytes: data),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "readWallet",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((result, err) async {
        if (err != null) {
          final remove = await database.removeStorageOperation(
              operation: e.toRemoveOperation(), actionId: StorageActionId.walletKeys);
          return remove.map((e) => HDWalletsKeys());
        }
        return _verifyWalletKeys(result!);
      });
    });
  }

  Future<IResult<void>> dropWalletStorage(IMainWallet wallet) async {
    final database = this.database.getDatabase();
    return database.andThenAsync((database) async {
      final storage = WalletStorageManager(wallet.key, database);
      final result = await storage.removeWallet();
      storage.dispose();
      return result;
    });
  }

  Future<IResult<void>> setupNewWallet(IMainWallet wallet,
      {VerifiedWalletBackup? backup}) async {
    final database = this.database.getDatabase();
    return database.andThenAsync((database) async {
      final storage = WalletStorageManager(wallet.key, database);
      final insert = await storage.insertMainWallet(wallet);
      final result = insert.andThenAsync((e) async {
        if (backup != null) {
          final operations = ChainStorageManager.createRestoreBackupTableOperations(
              repositories: backup.networks.expand((e) => e.repositories).toList(),
              chainRepositories: backup.chains,
              dapps: backup.dapps,
              chains: Map<int, BackupChain>.fromEntries(backup.networks
                  .map((e) => MapEntry<int, BackupChain>(e.network.value, e))),
              id: wallet.key);
          return await storage.database.batchStorageAction(operations);
        }
        return ResultOk.okVoid;
      });
      storage.dispose();
      return result;
    });
  }

  void dispose() {
    database.dispose();
  }
}
