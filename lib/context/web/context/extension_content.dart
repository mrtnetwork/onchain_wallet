import 'dart:js_interop';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/api/app_setting.dart';
import 'package:on_chain_wallet/context/web/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/disabled.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/repository/core/database.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

// extension type WebAssembly {}
@JS("WebAssembly")
extension type Reflect._(JSObject _) implements JSAny {
  external factory Reflect();
  @JS("get")
  external static JSAny? get(JSAny? object, JSAny? prop, JSAny? receiver);
  @JS("set")
  external static bool set(JSAny? object, JSAny? prop, JSAny? value, JSAny? receiver);
}

class DefaultAppContextExtensionContentScript extends MainAppContext {
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
  final AppResourcesApi resourceApi;

  @override
  final IAppContextConnectionApi connectionApi;
  @override
  final SafeAtomicLock sync = SafeAtomicLock();
  // final LogWriter logWriter;
  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  DefaultAppContextExtensionContentScript(
      {required this.netApi,
      required this.worker,
      required this.database,
      required this.cryptoLib,
      required this.setting,
      required this.platformCrypto,
      required this.platformUtls,
      required this.platform,
      required this.connectionApi,
      required this.resourceApi});
  static IResult<DefaultAppContextExtensionContentScript> init() {
    final resourceApi = DisabledResourcesApi();
    return ResultOk(DefaultAppContextExtensionContentScript(
        setting: DisabledAppSettingApi(),
        platform: AppPlatform.web,
        resourceApi: resourceApi,
        connectionApi: DisabledAppContextConnectionApi(),
        platformUtls: DisabledPlatformUtils(),
        platformCrypto: DisabledPlatformCryptoApi(),
        cryptoLib: DisabledAppBasicCryptoApi(),
        worker: DisabledWorkerWeb(),
        database: DisabledAppDatabaseApi(),
        netApi: DefaultNetApi(DefaultNetSdkApi(DefaultNetSdk(AppEnvironment.web)))));
  }

  @override
  AppContextMode get mode => AppContextMode.contentScript;

  @override
  final IAppContextUtils utils = DisabledAppContextUtils();
}
