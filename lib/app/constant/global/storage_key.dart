import 'package:on_chain_bridge/database/models/table.dart';

class APPDatabaseConst {
  static const int defaultStorageId = 0;

  /// Main table name and storages
  static const String appTableName = "onchain";

  /// Wallet table storage ids
  // current wallet account storage id.
  static const int accountStorageId = 1000;
  // web3 related
  static const int web3AuthStorage = 100000;
  static const int walletConnectionStorage = 200000;

  /// public wallet table storages
  static const zcashSaplingSpendParams = TableStructAColums(
      tableName: APPDatabaseConst.appTableName,
      storage: 100,
      storageId: 0,
      encrypted: false);
  static const zcashSaplingOutputParams = TableStructAColums(
      tableName: APPDatabaseConst.appTableName,
      storage: 100,
      storageId: 1,
      encrypted: false);
}

enum MainTableDatabaseResources {
  appSetting(TableStructAColums(
      tableName: APPDatabaseConst.appTableName, storage: 1, storageId: 0)),
  appSwapSetting(TableStructAColums(
      tableName: APPDatabaseConst.appTableName, storage: 2, storageId: 0)),
  hdWalletStorage(TableStructAColums(
      tableName: APPDatabaseConst.appTableName, storage: 5, storageId: 0)),
  appWebViewStorage(TableStructAColums(
      tableName: APPDatabaseConst.appTableName, storage: 6, storageId: 0)),
  zcashSaplingSpendParams(APPDatabaseConst.zcashSaplingSpendParams),
  zcashSaplingOutputParams(APPDatabaseConst.zcashSaplingOutputParams),
  ;

  const MainTableDatabaseResources(this.column);
  final TableStructAColums column;

  String get tableId => column.tableName;
  int get storage => column.storage;
  int get storageId => column.storageId;
  String get key => column.key;
  String get keyA => column.keyA;
}
