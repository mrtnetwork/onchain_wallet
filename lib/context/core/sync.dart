import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/models/path/path.dart';
import 'package:on_chain_wallet/app/error/exception/wallet_ex.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/network/net_api/api/api.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/repository/core/database.dart';

class DefaultAppContext implements AppContext {
  final AppPath? path;
  @override
  final AppPlatform platform;
  @override
  final IAppDatabaseApi database;
  @override
  final INetApi netApi;
  @override
  final AppBasicCryptoApi cryptoLib;
  @override
  final AppResourcesApi resourceApi;

  @override
  final AppContextMode mode;
  @override
  final IAppContextUtils utils;

  DefaultAppContext(
      {required this.path,
      required this.platform,
      required this.database,
      required this.netApi,
      required this.cryptoLib,
      required this.resourceApi,
      required this.mode,
      required this.utils});

  @override
  final IPlatformCryptoApi platformCrypto = DisabledPlatformCryptoApi();

  @override
  final IAppContextConnectionApi connectionApi = DisabledAppContextConnectionApi();

  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<AppPath> platformPath() {
    final path = this.path;
    if (path == null) {
      return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
    }
    return ResultOk(path);
  }

  @override
  final SafeAtomicLock sync = SafeAtomicLock();

  @override
  final IPlatformUtils platformUtls = DisabledPlatformUtils();
}
