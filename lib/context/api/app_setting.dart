import 'package:on_chain_bridge/models/device/models/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/repository/repository.dart';

abstract class IAppSettingApi {
  APPSetting get setting;
  Future<IResult<void>> updateAppSetting(APPSetting setting);

  void updateAppSettingSync(APPSetting setting);

  bool get supportBarcodeScanner;
  bool get supportWebView;
  bool get isExtension;
}

class DisabledAppSettingApi implements IAppSettingApi {
  @override
  final APPSetting setting = APPSetting.defaultSetting();

  @override
  bool get supportBarcodeScanner => false;

  @override
  bool get supportWebView => false;

  @override
  Future<IResult<void>> updateAppSetting(APPSetting setting) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  void updateAppSettingSync(APPSetting setting) {}

  @override
  bool get isExtension => false;
}

class DefaultAppSettingApi implements IAppSettingApi {
  final StorageControllerDefault storage;
  final PlatformConfig config;
  APPSetting _setting;
  @override
  APPSetting get setting => _setting;
  DefaultAppSettingApi(
      {required this.storage, required APPSetting setting, required this.config})
      : _setting = setting;
  static Future<IResult<DefaultAppSettingApi>> init(
      {required IAppDatabaseApi database, required PlatformConfig config}) async {
    final column = MainTableDatabaseResources.appSetting;
    final storage = StorageControllerDefault(
        tableId: column.tableId, storage: column.storage, database: database);
    final result = await storage.queryStorage(
        actionId: StorageActionId.appSettings, storageId: column.storageId);
    return result.map((e) {
      final setting = IResult.callSync(
        () => APPSetting.deserialize(e?.data),
        onError: (exception, trace) => AppLogData(
            msg: "Failed to deserialize app settings.",
            err: exception,
            trace: trace.toString()),
      );
      return DefaultAppSettingApi(
          storage: storage,
          setting: setting.unwrapOr((_) => APPSetting.defaultSetting()),
          config: config);
    });
  }

  @override
  bool get supportBarcodeScanner => config.hasBarcodeScanner;
  @override
  bool get supportWebView => config.hasWebview;
  Future<IResult<void>> _update(APPSetting setting) async {
    final column = MainTableDatabaseResources.appSetting;
    return await storage.insertStorage(
        actionId: StorageActionId.appSettings,
        storageId: column.storageId,
        value: setting);
  }

  @override
  Future<IResult<void>> updateAppSetting(APPSetting setting) async {
    final result = await _update(setting);
    return result.map((_) {
      _setting = setting;
    });
  }

  @override
  void updateAppSettingSync(APPSetting setting) {
    _setting = setting;
    _update(setting);
  }

  @override
  bool get isExtension => config.isExtension;
}
