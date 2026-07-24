import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/app/resources/resources/constants.dart';
import 'package:on_chain_wallet/context/api/resources.dart';

class AppResourceWeb extends AppResourcesApi {
  final WebAssetPathResolver resolver;
  AppResourceWeb(this.resolver);

  WasmModuleInfo _fixWasmModulePath(WasmModuleInfo path) {
    // if (base.isEmpty) return path;
    return WasmModuleInfo(
        moduleUrl: resolver.resolve(path.moduleUrl),
        wasmUrl: resolver.resolve(path.wasmUrl),
        target: path.target);
  }

  @override
  IResult<String> workerExecutorPath() =>
      ResultOk(resolver.resolve(AppResourceConst.web.workerExcuterPath));
  @override
  IResult<WasmModuleInfo> contextModule() =>
      ResultOk(_fixWasmModulePath(AppResourceConst.web.context));

  @override
  IResult<WasmModuleInfo> cryptoWasm() =>
      ResultOk(_fixWasmModulePath(AppResourceConst.web.cryptoWasm));

  @override
  IResult<WasmModuleInfo> streamCryptoWasm() =>
      ResultOk(_fixWasmModulePath(AppResourceConst.web.streamCryptoWasm));
  @override
  IResult<WasmModuleInfo> zcashCryptoWasm() =>
      ResultOk(_fixWasmModulePath(AppResourceConst.web.zcashCryptoWasm));
}

class WebAssetPathResolver {
  final String href;
  final bool isExtension;
  const WebAssetPathResolver({required this.href, this.isExtension = false});
  String resolve(String path) {
    if (href.isEmpty) return path;
    return OnChainBridgeUtils.joinPathWithRoot([href, path]);
  }
}
