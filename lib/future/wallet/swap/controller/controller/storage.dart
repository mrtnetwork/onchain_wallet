import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/repository/repository.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/settings.dart';

class SwapControllerStorage {
  final StorageControllerDefault database;
  SwapControllerStorage(IAppDatabaseApi database)
      : database = StorageControllerDefault(
            tableId: MainTableDatabaseResources.appSwapSetting.tableId,
            storage: MainTableDatabaseResources.appSwapSetting.storage,
            database: database);
  Future<IResult<APPSwapSettings>> storageGetSwapSettings() async {
    final data = await database.queryStorage(
      storageId: APPDatabaseConst.defaultStorageId,
      actionId: StorageActionId.swapSettings,
    );
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(APPSwapSettings());
      final result = IResult.callSync(
        () => APPSwapSettings.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetSwapSettings",
            err: exception,
            trace: trace.toString()),
      );
      return result.and((identifier, _) => ResultOk(identifier ?? APPSwapSettings()));
    });
  }

  Future<IResult<void>> storageSaveSwapSettings(APPSwapSettings settings) async {
    return await database.insertStorage(
      storageId: MainTableDatabaseResources.appSwapSetting.storageId,
      value: settings,
      actionId: StorageActionId.swapSettings,
    );
  }
}
