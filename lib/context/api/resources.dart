import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_wallet/app/error/exception.dart';
import 'package:on_chain_wallet/app/resources/resources/constants.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';

abstract class AppResourcesApi {
  // =========================
  // Core
  // =========================
  String applicationId() => AppResourceConst.native.applicationId;
  String dbName() => AppResourceConst.native.dbName;
  String loggingTableName() => AppResourceConst.web.loggingTableName;
  int loggingStorageId() => AppResourceConst.web.loggingStorageId;
  int loggingActionId() => AppResourceConst.web.loggingActionId;
  int netSdkInstanceId(SyncWorkerMode? mode) {
    final firstId = AppResourceConst.native.netSdkMainInstanceId;
    if (mode == null) return firstId;
    return firstId + (mode.index + 1);
  }

  // =========================
  // Native resources
  // =========================
  IResult<String> netSdkLibName() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<String> sqliteLibName() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<RuntimeFileLocation> loggingFileLocation() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);

  IResult<TorParamsLocation> torParamsLocation() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<String> zcashLibName() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<String> moneroLibName() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<ZcashParamsLocation> zcashParamLocation() =>
      ResultOk(AppResourceConst.native.zcashParamsLocation);

  // =========================
  // Web resources
  // =========================
  IResult<String> workerExecutorPath() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);

  IResult<WasmModuleInfo> contextModule() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<WasmModuleInfo> cryptoWasm() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<WasmModuleInfo> streamCryptoWasm() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
  IResult<WasmModuleInfo> zcashCryptoWasm() =>
      ResultErr.from(AppExceptionConst.resourceNotSupported);
}

class DisabledResourcesApi extends AppResourcesApi {}
