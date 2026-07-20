import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/core/app_crypto.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/types/zk_params_downloader.dart';
import 'package:zcash_dart/zcash.dart';

AppCryptoLibs getAppCrypto() => AppCryptoWeb._();

class AppCryptoWeb extends AppCryptoLibs {
  const AppCryptoWeb._();

  @override
  Future<IResult<AppCryptoLibsMonero>> moneroCrypto(
      AppContext context, List<MoneroAccountKeys> accounts) async {
    return ResultOk(AppCryptoMoneroWeb(accounts: accounts));
  }

  @override
  Future<IResult<AppCryptoLibsZcash>> zcashCrypto(AppContext context) async {
    return context.resourceApi.zcashCryptoWasm().andThenAsync((resource) async {
      final paramsLocation = context.resourceApi.zcashParamLocation();
      return paramsLocation.andThenCatchAsync(
        (params) async {
          final config = ZKLibConfig(
              saplingParamsDownloader:
                  ZcashParamDownloader(params: params, context: context),
              wasm:
                  ZKWasmConfig(moduleUrl: resource.moduleUrl, wasmUrl: resource.wasmUrl));
          final lib = await ZKLib.init(config);
          return ResultOk(AppCryptoLibsZcash(lib));
        },
        logging: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "zcashCrypto",
            err: exception,
            trace: trace.toString()),
      );
    });
  }
}

class AppCryptoMoneroWeb extends AppCryptoLibsMonero {
  const AppCryptoMoneroWeb({super.accounts});
  @override
  void close() {}
}
