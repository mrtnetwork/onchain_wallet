import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/repository/repository.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/controller/chain/controller.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

abstract mixin class IWalletStorageManager {
  Future<IResult<List<Chain>>> readAccounts(InChainWalletController controller);
  Future<IResult<IMainWallet?>> mainWallet();
  Future<IResult<void>> insertMainWallet(IMainWallet mainWallet);
  Future<IResult<List<int>?>> getMemoryKey();
  Future<IResult<void>> saveMemoryKey(List<int> key);
  Future<IResult<void>> removeChain(Chain chain);
  Future<IResult<void>> removeWallet();
  void dispose();
  Future<IResult<void>> removeWalletOperation(ITableRemoveStructA operation);
}

class WalletStorageManager implements IWalletStorageManager {
  static const int keyStorageId = 1000003;
  static const int inMemoryKeyStorageId = 1;
  final StorageControllerDefault database;

  WalletStorageManager(String id, IAppDatabaseApi database)
      : database = StorageControllerDefault(
            storage: keyStorageId, tableId: id, database: database);

  @override
  Future<IResult<void>> removeWalletOperation(ITableRemoveStructA operation) async {
    return await database.removeStorageData(
      storageId: operation.storageId,
      key: operation.key,
      keyA: operation.keyA,
      actionId: StorageActionId.web3,
    );
  }

  @override
  Future<IResult<List<Chain>>> readAccounts(InChainWalletController controller) async {
    final data = await database.queriesTable(
        storage: null, storageId: APPDatabaseConst.accountStorageId);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => Chain.deserialize(controller, bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "readAccounts",
                  err: exception,
                  data: e,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  database.removeTableOperation(
                      operation: e.toRemoveOperation(), actionId: StorageActionId.chain);
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<Chain>().toList());
  }

  Future<IResult<List<WalletNetwork>>> readNetworks() async {
    final data = await database.queriesTable(
        storage: null, storageId: APPDatabaseConst.accountStorageId);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () {
                final CborListValue values = AppSerialization.decodeTaggedValue(
                    cborBytes: data, identifier: AppSerializationIdentifier.iAccount);
                WalletNetwork network =
                    WalletNetwork.deserialize(object: values.objectAt<CborTagValue>(1));
                return network;
              },
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "readAccounts",
                  err: exception,
                  data: e,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  database.removeTableOperation(
                      operation: e.toRemoveOperation(), actionId: StorageActionId.chain);
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<WalletNetwork>().toList());
  }

  @override
  Future<IResult<IMainWallet?>> mainWallet() async {
    final data = await database.queryStorage(
      storageId: APPDatabaseConst.defaultStorageId,
      actionId: StorageActionId.wallet,
    );
    return data.andThenAsync((e) {
      final data = e?.data;
      if (e == null || data == null) return ResultOk(null);
      final result = IResult.callSync(
        () => IMainWallet.deserialize(bytes: data),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "mainWallet",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((result, err) async {
        if (err != null) {
          final remove = await database.removeStorageOperation(
              operation: e.toRemoveOperation(), actionId: StorageActionId.wallet);
          return remove.map((e) => null);
        }
        return ResultOk(result);
      });
    });
  }

  Future<IResult<bool>> storageExists() async {
    final data = await database.queryStorage(
      actionId: StorageActionId.wallet,
      storageId: APPDatabaseConst.defaultStorageId,
    );
    return data.map((data) => data?.data != null);
  }

  @override
  Future<IResult<void>> insertMainWallet(IMainWallet mainWallet) async {
    return await database.insertStorage(
        actionId: StorageActionId.wallet,
        storageId: APPDatabaseConst.defaultStorageId,
        value: mainWallet);
  }

  @override
  Future<IResult<List<int>?>> getMemoryKey() async {
    return await database.queryStorageData(
        storageId: inMemoryKeyStorageId, actionId: StorageActionId.walletRuntime);
  }

  @override
  Future<IResult<void>> saveMemoryKey(List<int> key) async {
    return await database.insertStorageRaw(
        value: key,
        storageId: inMemoryKeyStorageId,
        actionId: StorageActionId.walletRuntime);
  }

  @override
  Future<IResult<void>> removeChain(Chain chain) async {
    final tableId = database.getTableId();
    return tableId.andThenAsync((tableId) async {
      final database = this.database.getDatabase();
      return database.andThenAsync((database) async {
        final storage = NetworkStorageManager(
            network: chain.network, id: tableId, database: database);
        final result = await storage.removeAccount(chain);
        storage.dispose();
        return result;
      });
    });
  }

  @override
  Future<IResult<void>> removeWallet() async {
    return await database.drop();
  }

  @override
  void dispose() {
    database.dispose();
  }
}
