import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/app/resources/resources/constants.dart';
import 'package:on_chain_wallet/context/api/resources.dart';

class AppResourceWeb extends AppResourcesApi {
  @override
  IResult<String> workerExecutorPath() =>
      ResultOk(AppResourceConst.web.workerExcuterPath);
  @override
  IResult<String> netSdkJsModule() => ResultOk(AppResourceConst.web.netSdkJsModule);
  @override
  IResult<WasmModuleInfo> contextModule() => ResultOk(AppResourceConst.web.context);
  @override
  IResult<WasmModuleInfo> netSdkWasm() => ResultOk(AppResourceConst.web.netSdk);
  @override
  IResult<WasmModuleInfo> netSdkRustWasm() => ResultOk(AppResourceConst.web.netSdkRust);
  @override
  IResult<String> cryptoJsModule() => ResultOk(AppResourceConst.web.cryptoJsModule);
  @override
  IResult<WasmModuleInfo> cryptoWasm() => ResultOk(AppResourceConst.web.cryptoWasm);
  @override
  IResult<String> cryptoStreamingJsModule() =>
      ResultOk(AppResourceConst.web.cryptoStreamingJsModule);
  @override
  IResult<WasmModuleInfo> streamCryptoWasm() =>
      ResultOk(AppResourceConst.web.streamCryptoWasm);
  @override
  IResult<WasmModuleInfo> zcashCryptoWasm() =>
      ResultOk(AppResourceConst.web.zcashCryptoWasm);
}
