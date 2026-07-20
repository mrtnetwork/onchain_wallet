import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/app_setting.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/disabled.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';
import 'package:on_chain_wallet/repository/repository.dart';

enum AppContextMode {
  main,
  background,
  backgroundContextController,
  backgroundScript,
  contentScript,
  disabled;

  bool get isBackgroundScript => this == backgroundScript;
}

abstract class AppContext {
  abstract final AppBasicCryptoApi cryptoLib;
  abstract final IAppDatabaseApi database;
  abstract final INetApi netApi;
  abstract final IPlatformCryptoApi platformCrypto;
  abstract final IPlatformUtils platformUtls;
  abstract final AppPlatform platform;
  abstract final SafeAtomicLock sync;
  abstract final IAppContextConnectionApi connectionApi;
  abstract final AppResourcesApi resourceApi;
  abstract final AppContextMode mode;
  abstract final IAppContextUtils utils;
  IResult<IOnChainBridgeInterface> platformInterface();
  IResult<AppPath> platformPath();
}

abstract class MainAppContext extends AppContext {
  IAppSettingApi get setting;
}

class DisabledAppContext implements AppContext {
  @override
  final AppPlatform platform;
  DisabledAppContext(this.platform);
  @override
  final AppBasicCryptoApi cryptoLib = DisabledAppBasicCryptoApi();

  @override
  final IAppDatabaseApi database = DisabledAppDatabaseApi();

  @override
  final INetApi netApi = DisabledNetApi();

  @override
  final IPlatformCryptoApi platformCrypto = DisabledPlatformCryptoApi();

  @override
  final IPlatformUtils platformUtls = DisabledPlatformUtils();
  @override
  final IAppContextUtils utils = DisabledAppContextUtils();

  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  final SafeAtomicLock sync = SafeAtomicLock();

  @override
  final IAppContextConnectionApi connectionApi = DisabledAppContextConnectionApi();

  @override
  final AppResourcesApi resourceApi = DisabledResourcesApi();

  @override
  AppContextMode get mode => AppContextMode.disabled;
}

class DisabledMainAppContext extends MainAppContext {
  @override
  final AppPlatform platform;
  DisabledMainAppContext(this.platform);
  @override
  final AppBasicCryptoApi cryptoLib = DisabledAppBasicCryptoApi();

  @override
  final IAppDatabaseApi database = DisabledAppDatabaseApi();

  @override
  final INetApi netApi = DisabledNetApi();

  @override
  final IAppSettingApi setting = DisabledAppSettingApi();

  @override
  final IPlatformCryptoApi platformCrypto = DisabledPlatformCryptoApi();
  @override
  final IPlatformUtils platformUtls = DisabledPlatformUtils();
  @override
  final SafeAtomicLock sync = SafeAtomicLock();

  @override
  final IAppContextUtils utils = DisabledAppContextUtils();

  @override
  final IAppContextConnectionApi connectionApi = DisabledAppContextConnectionApi();
  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  final AppResourcesApi resourceApi = DisabledResourcesApi();

  @override
  AppContextMode get mode => AppContextMode.disabled;
}

abstract class BackgroundAppContext extends AppContext {
  Future<void> shutdown();
  abstract final String connectionId;
}
