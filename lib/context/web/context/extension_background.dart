import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/dev/writer/db.dart';
import 'package:on_chain_bridge/native/net_sdk/types/config.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/web/net_sdk/core/net_sdk.dart';
import 'package:on_chain_bridge/web/net_sdk/module/module.dart';
import 'package:on_chain_bridge/web/storage/database/interface/interface.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/api/app_setting.dart';
import 'package:on_chain_wallet/context/database/sync.dart';
import 'package:on_chain_wallet/context/web/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/disabled.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/repository/core/database.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class DefaultAppContextExtensionBackgroundScript extends MainAppContext {
  @override
  final IAppDatabaseApi database;
  final WorkerApiWeb worker;
  @override
  final AppBasicCryptoApi cryptoLib;
  @override
  final INetApi netApi;
  @override
  final IAppSettingApi setting;

  @override
  final IPlatformCryptoApi platformCrypto;

  @override
  final IPlatformUtils platformUtls;
  @override
  final AppPlatform platform;

  @override
  final IAppContextConnectionApi connectionApi;
  @override
  final SafeAtomicLock sync = SafeAtomicLock();
  @override
  final AppResourcesApi resourceApi;

  final LogWriter logWriter;
  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  DefaultAppContextExtensionBackgroundScript(
      {required this.netApi,
      required this.worker,
      required this.database,
      required this.cryptoLib,
      required this.setting,
      required this.platformCrypto,
      required this.platformUtls,
      required this.platform,
      required this.connectionApi,
      required this.logWriter,
      required this.resourceApi});
  static Future<IResult<DefaultAppContextExtensionBackgroundScript>> init(
      NetSdkWebRustCompiledGlue module) async {
    final resourceApi = DisabledResourcesApi();
    final database = IDatabseInterfaceJS(resourceApi.dbName(), instanceId: 1);
    final init = (await database.openDatabase()).toResult();
    return init.andThenAsync((_) async {
      final backgroundSdk = await IResult.block(() async {
        return (await WebNetSdk.fromRustModule(module,
                NetCreateInstanceConfig(logging: true, mode: Logging.config.libs)))
            .transformError(
          (error) => NetSdkException(error),
        );
      });
      return backgroundSdk.andThenAsync((sdk) async {
        final logWriter = LogWriterDatabase(
            action: database.storageAction,
            storage: resourceApi.loggingStorageId(),
            tableId: resourceApi.loggingTableName(),
            storageActionId: resourceApi.loggingActionId(),
            mode: Logging.mode == LoggerMode.debug ? LoggerMode.debug : LoggerMode.error);
        return ResultOk(DefaultAppContextExtensionBackgroundScript(
            logWriter: logWriter,
            setting: DisabledAppSettingApi(),
            resourceApi: resourceApi,
            platform: AppPlatform.web,
            connectionApi: DisabledAppContextConnectionApi(),
            platformUtls: DisabledPlatformUtils(),
            platformCrypto: DisabledPlatformCryptoApi(),
            cryptoLib: DisabledAppBasicCryptoApi(),
            worker: DisabledWorkerWeb(),
            database: SyncAppDatabase(database),
            netApi: DefaultNetApi(DefaultNetSdkApi(sdk))));
      });
    });
  }

  static Future<IResult<DefaultAppContextExtensionBackgroundScript>> init_() async {
    final resourceApi = DisabledResourcesApi();
    final database = IDatabseInterfaceJS(resourceApi.dbName(), instanceId: 1);
    final init = (await database.openDatabase()).toResult();
    return init.andThenAsync((_) async {
      final logWriter = LogWriterDatabase(
          action: database.storageAction,
          storage: resourceApi.loggingStorageId(),
          tableId: resourceApi.loggingTableName(),
          storageActionId: resourceApi.loggingActionId(),
          mode: Logging.mode == LoggerMode.debug ? LoggerMode.debug : LoggerMode.error);
      return ResultOk(DefaultAppContextExtensionBackgroundScript(
          logWriter: logWriter,
          setting: DisabledAppSettingApi(),
          resourceApi: resourceApi,
          platform: AppPlatform.web,
          connectionApi: DisabledAppContextConnectionApi(),
          platformUtls: DisabledPlatformUtils(),
          platformCrypto: DisabledPlatformCryptoApi(),
          cryptoLib: DisabledAppBasicCryptoApi(),
          worker: DisabledWorkerWeb(),
          database: SyncAppDatabase(database),
          netApi: DefaultNetApi(DefaultNetSdkApi(DefaultNetSdk(AppEnvironment.web)))));
    });
  }

  @override
  AppContextMode get mode => AppContextMode.backgroundScript;

  @override
  final IAppContextUtils utils = DisabledAppContextUtils();
}
