import 'dart:async';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/core/app_crypto.dart';
import 'package:zcash_dart/zcash.dart';

class OnChainCryptoContext extends DefaultZcashCryptoContext {
  OnChainCryptoContext._();
  static final OnChainCryptoContext instance = OnChainCryptoContext._();
  static Future<IResult<(OnChainCryptoContext, AppCryptoLibsZcash)>> inst(
      AppContext context) async {
    final result = await instance.getZcashNativeCyrpto(context);
    return result.map((e) => (instance, e));
  }

  AppCryptoLibsZcash? _lib;
  @override
  ZKLib? get lib => _lib?.zklib;
  Future<IResult<AppCryptoLibsZcash>> getZcashNativeCyrpto(AppContext context) async {
    final lib = _lib;
    if (lib != null) return ResultOk(lib);
    final crypto = AppCryptoLibs.instance();
    final zkLib = await crypto.zcashCrypto(context);
    return zkLib.andThenAsync((e) async {
      await e.zklib
          .logging(true, level: ZKLibLogLevel.fromValue(Logging.config.libs.value));
      _lib = e;
      return ResultOk(e);
    });
  }
}
