import 'dart:async';
import 'dart:js_interop';
import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/net_sdk/module/module.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/exception/exception.dart';

class JsWorkerUtils {
  static Future<IResult<JSObject>> imortModule(String url) async {
    try {
      final module = await importModule(url.toJS).toDart;
      return ResultOk(module);
    } catch (_) {
      return ResultErr.fromException(
          AppContextError.wokerInitializationError("importModule excution failed."));
    }
  }

  static Future<IResult<JSObject>> importWasm(WasmModuleInfo wasm) async {
    final module = await imortModule(wasm.moduleUrl);
    return module.andThenAsync((m) async {
      final data = await JSFetchApi.fetchJsBuffer(wasm.wasmUrl);
      return data
          .transformError((error) =>
              AppContextError.wokerInitializationError("Failed to get wasm buffer data."))
          .mapAsync((buffer) async {
        switch (wasm.target) {
          case WasmModuleTarget.dart:
            final module = m as NetSdkDartCompiledWasm;
            final compile = module.compile(buffer);
            final wasm = await module.instantiate(compile).toDart;
            module.invoke(wasm);
            break;
          case WasmModuleTarget.rust:
            final module = m as NetSdkRustCompiledWasm;
            module.initSync(buffer);
            break;
        }
        return m;
      });
    });
  }
}
