import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/exception/exception.dart';
import 'package:on_chain_wallet/context/web/utils/js_error.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/context/web/worker/utils.dart';

@JS("location")
external Location? get location;
@JS("init_script")
external JSPromise<ResultOrErrorJs<JSIsolateEncodedMessage, APPJSUint8Array>> init(
    JSWorkerMessage? config);
@JS("init_script")
external JSFunction? get initFunc;
@JS("close_script")
external JSPromise<JSAny?> closeScript();
@JS("close_script")
external JSFunction? get closeFunc;
@JS("onmessage")
external set onmessage(JSFunction? handler);
@JS("onscriptmessage")
external void onscriptmessage(MessageEvent<JSWorkerMessage> msg);
@JS("postMessage")
external void postMessage(JSAny? data);
@JS("postMessage")
external void postMessageWithTransferables(JSAny message, JSArray<JSAny> buffer);
void workerModuleExport() {
  final url = WokerUrl.fromUrl(location?.href);
  onmessage = (MessageEvent<JSWorkerMessage?> event) {
    url.excute().then((e) {
      e.mapErr((e) {
        postMessage(ErrJs(JsUtils.toAppJsUint8Array(e.exception.toCbor().encode())));
        onmessage = null;
        return e.exception;
      });
      init(event.data).toDart.then((e) {
        e.fold(
          onErr: (err) {
            onmessage = null;
            postMessageWithTransferables(ErrJs(err.buffer), [err.buffer].toJS);
          },
          onResult: (ok) {
            // final channel = ok.channel;
            postMessageWithTransferables(
                OkJs(ok.message), ok.transfableParams ?? <JSAny>[].toJS);
            onmessage = (MessageEvent<JSWorkerMessage> event) {
              if (event.isUndefinedOrNull || event.data.isUndefinedOrNull) {
                return;
              }
              if (event.data.isClosed()) {
                onmessage = null;
                if (closeFunc != null) {
                  closeScript().toDart.catchError((_) => null).then((_) {
                    postMessage(JSWorkerMessage.close(close: true.toJS));
                  });
                }
                return;
              }
              onscriptmessage(event);
            }.toJS;
          },
        );
      });
    });
  }.toJS;
}

class WokerUrl {
  final WasmModuleInfo? wasm;
  final String? module;
  final bool logging;
  WokerUrl({this.wasm, this.module, this.logging = false});
  factory WokerUrl.fromUrl(String? url) {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null) return WokerUrl();
    final params = uri.queryParameters;
    final bool logging = params.valueAsBool<bool?>("logging") ?? false;
    final String? wasmModuleUrl = params.valueAsString("wasm_module");
    final String? wasmUrl = params.valueAsString("wasm");
    final String? jsModule = params.valueAsString("module");
    final WasmModuleTarget? target =
        WasmModuleTarget.fromName(params.valueAsString("wasm_traget"));
    if (wasmModuleUrl != null && wasmUrl != null && target != null) {
      return WokerUrl(
          wasm:
              WasmModuleInfo(moduleUrl: wasmModuleUrl, wasmUrl: wasmUrl, target: target),
          logging: logging);
    }
    return WokerUrl(module: jsModule, logging: logging);
  }
  Map<String, String> toQueryParameters() {
    final wasm = this.wasm;
    final jsModule = module;
    return {
      "logging": logging.toString(),
      if (wasm != null) ...{
        "wasm_module": wasm.moduleUrl,
        "wasm": wasm.wasmUrl,
        "wasm_traget": wasm.target.name
      } else if (jsModule != null) ...{
        "module": jsModule
      }
    };
  }

  String toUrl(String excutablePath) {
    return Uri(path: excutablePath, queryParameters: toQueryParameters()).toString();
  }

  Future<IResult<void>> excute() async {
    final wasm = this.wasm;
    final moduleUrl = module;
    if (moduleUrl != null) {
      final result = await JsWorkerUtils.imortModule(moduleUrl);
      if (result.isErr) return result.cast();
    } else if (wasm != null) {
      final result = await JsWorkerUtils.importWasm(wasm);
      if (result.isErr) return result.cast();
    } else {
      return ResultErr.fromException(AppContextError.invalidConfig);
    }
    if (initFunc == null) {
      return ResultErr.fromException(AppContextError.wokerInitializationError(
          "Unknown module script. init method not initialized."));
    }
    return ResultOk(null);
  }
}
