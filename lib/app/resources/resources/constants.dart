import 'package:on_chain_bridge/models/path/path.dart';
import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_wallet/app/constant/global/storage_key.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';

class AppResourceConst {
  static const native = NativeAppConfigResources(
      applicationId: "com.mrtnetwork.on_chain_wallet",
      netSdkLibName: 'libnet_sdk',
      sqliteLibName: "libsqlite3mc",
      zcashLibName: 'libzk',
      moneroLibName: "libcrypto_c",
      loggingFileLocation: RuntimeFileLocation(
          location: 'logging/log.txt', directory: AppPathDirectory.support),
      netSdkMainInstanceId: 257,
      torParams: TorParamsLocation(
          cacheState: RuntimeDirectoryLocation(
              location: 'tor_state', directory: AppPathDirectory.cache),
          mainState: RuntimeDirectoryLocation(
              location: 'tor_state', directory: AppPathDirectory.support)),
      zcashParamsLocation: ZcashParamsLocation(
          spend: RuntimeResourceLocation(
              checksum: 1499441492,
              file: RuntimeFileLocation(
                  location: "zcash/sapling_spend.txt",
                  directory: AppPathDirectory.support),
              tableColumn: APPDatabaseConst.zcashSaplingSpendParams),
          output: RuntimeResourceLocation(
              checksum: 3427161169,
              file: RuntimeFileLocation(
                  location: "zcash/sapling_output.txt",
                  directory: AppPathDirectory.support),
              tableColumn: APPDatabaseConst.zcashSaplingOutputParams)),
      dbName: "onchaindatabase");

  static const web = WebAppConfigResources(
      workerExcuterPath: "/assets/assets/web_scripts/worker.js",
      netSdkJsModule: "/assets/assets/web_scripts/http.js",
      context: WasmModuleInfo(
        wasmUrl: '/assets/assets/web_scripts/context.wasm',
        moduleUrl: "/assets/assets/web_scripts/context.mjs",
        target: WasmModuleTarget.dart,
      ),

      ///
      netSdk: WasmModuleInfo(
        wasmUrl: "/assets/assets/web_scripts/http.wasm",
        moduleUrl: "/assets/assets/web_scripts/http.mjs",
        target: WasmModuleTarget.dart,
      ),
      netSdkRust: WasmModuleInfo(
        wasmUrl: "/assets/assets/web_scripts/net_sdk/net_sdk_bg.wasm",
        moduleUrl: "/assets/assets/web_scripts/net_sdk/net_sdk.js",
        target: WasmModuleTarget.rust,
      ),
      cryptoJsModule: "/assets/assets/web_scripts/crypto.js",
      cryptoWasm: WasmModuleInfo(
        wasmUrl: '/assets/assets/web_scripts/crypto.wasm',
        moduleUrl: "/assets/assets/web_scripts/crypto.mjs",
        target: WasmModuleTarget.dart,
      ),

      ////
      cryptoStreamingJsModule: '/assets/assets/web_scripts/stream_crypto.js',
      streamCryptoWasm: WasmModuleInfo(
        wasmUrl: "/assets/assets/web_scripts/stream_crypto.wasm",
        moduleUrl: "/assets/assets/web_scripts/stream_crypto.mjs",
        target: WasmModuleTarget.dart,
      ),
      loggingTableName: 'logging',
      loggingStorageId: 0,
      zcashCryptoWasm: WasmModuleInfo(
        wasmUrl: '/assets/assets/web_scripts/zk/zk_bg.wasm',
        moduleUrl: "/assets/assets/web_scripts/zk/zk.js",
        target: WasmModuleTarget.rust,
      ),
      loggingActionId: 0,
      dbName: "onchaindatabase");
}
