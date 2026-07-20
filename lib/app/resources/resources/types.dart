import 'package:on_chain_bridge/models/path/path.dart';
import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';

class NativeAppConfigResources {
  final String netSdkLibName;
  final String sqliteLibName;
  final TorParamsLocation torParams;
  final RuntimeFileLocation loggingFileLocation;
  final int netSdkMainInstanceId;
  final String zcashLibName;
  final ZcashParamsLocation zcashParamsLocation;
  final String moneroLibName;
  final String dbName;
  final String applicationId;
  const NativeAppConfigResources({
    required this.netSdkLibName,
    required this.sqliteLibName,
    required this.dbName,
    required this.applicationId,
    required this.zcashParamsLocation,
    required this.torParams,
    required this.loggingFileLocation,
    required this.netSdkMainInstanceId,
    required this.zcashLibName,
    required this.moneroLibName,
  });
}

class WebAppConfigResources {
  final String loggingTableName;
  final int loggingStorageId;
  final int loggingActionId;
  final String workerExcuterPath;
  final String netSdkJsModule;
  final WasmModuleInfo netSdk;
  final WasmModuleInfo netSdkRust;
  final String cryptoJsModule;
  final WasmModuleInfo context;
  final WasmModuleInfo cryptoWasm;
  final String cryptoStreamingJsModule;
  final WasmModuleInfo streamCryptoWasm;
  final WasmModuleInfo zcashCryptoWasm;
  final String dbName;
  const WebAppConfigResources({
    required this.workerExcuterPath,
    required this.dbName,
    required this.netSdkJsModule,
    required this.cryptoJsModule,
    required this.cryptoWasm,
    required this.cryptoStreamingJsModule,
    required this.loggingTableName,
    required this.loggingStorageId,
    required this.loggingActionId,
    required this.zcashCryptoWasm,
    required this.netSdk,
    required this.netSdkRust,
    required this.streamCryptoWasm,
    required this.context,
  });
}

class RuntimeFileLocation with AppSerialization {
  final String location;
  final AppPathDirectory directory;
  const RuntimeFileLocation({required this.location, required this.directory});
  factory RuntimeFileLocation.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeFileResourceLocation,
        cborBytes: bytes,
        cborObject: object);
    return RuntimeFileLocation(
      location: values.rawValueAt(0),
      directory: AppPathDirectory.fromValue(values.rawValueAt(1)),
    );
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeFileResourceLocation;

  @override
  List<CborObject<Object?>?> get serializationItems =>
      [location.toCbor(), directory.value.toCbor()];

  String getAbsolutePath(AppPath path) =>
      path.toFilePath(directory: directory, relativePath: location);
}

class RuntimeResourceLocation with AppSerialization {
  final RuntimeFileLocation? file;
  final TableStructAColums? tableColumn;
  final int? checksum;
  const RuntimeResourceLocation(
      {required this.file, required this.tableColumn, this.checksum});
  factory RuntimeResourceLocation.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeResourceLocation,
        cborBytes: bytes,
        cborObject: object);
    return RuntimeResourceLocation(
        file: values.maybeObjectAt<RuntimeFileLocation, CborTagValue>(
            0, (e) => RuntimeFileLocation.deserialize(object: e)),
        tableColumn: values.maybeObjectAt<TableStructAColums, CborTagValue>(
            1, (e) => TableStructAColums.deserialize(obj: e)),
        checksum: values.rawValueAt(2));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeResourceLocation;

  @override
  List<CborObject<Object?>?> get serializationItems =>
      [file?.toCbor(), tableColumn?.toCbor(), checksum?.toCbor()];
  IResult<RuntimeFileLocation> getFileLocation() {
    final location = file;
    if (location == null) {
      return ResultErr.fromException(AppExceptionConst.resourceNotSupported);
    }
    return ResultOk(location);
  }

  IResult<TableStructAColums> getTableLocation() {
    final location = tableColumn;
    if (location == null) {
      return ResultErr.fromException(AppExceptionConst.resourceNotSupported);
    }
    return ResultOk(location);
  }
}

class ZcashParamsLocation {
  final RuntimeResourceLocation spend;
  final RuntimeResourceLocation output;
  const ZcashParamsLocation({required this.spend, required this.output});
}

class TorParamsLocation {
  final RuntimeDirectoryLocation cacheState;
  final RuntimeDirectoryLocation mainState;
  const TorParamsLocation({required this.cacheState, required this.mainState});
}

class RuntimeDirectoryLocation with AppSerialization {
  final String location;
  final AppPathDirectory directory;
  const RuntimeDirectoryLocation({required this.location, required this.directory});
  factory RuntimeDirectoryLocation.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeDirectoryResourceLocation,
        cborBytes: bytes,
        cborObject: object);
    return RuntimeDirectoryLocation(
      location: values.rawValueAt(0),
      directory: AppPathDirectory.fromValue(values.rawValueAt(1)),
    );
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeDirectoryResourceLocation;

  @override
  List<CborObject<Object?>?> get serializationItems =>
      [location.toCbor(), directory.value.toCbor()];

  String getAbsolutePath(AppPath path) =>
      path.toDirectoryPath(directory: directory, relativePath: location);
}
