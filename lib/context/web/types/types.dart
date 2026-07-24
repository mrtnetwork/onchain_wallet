import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';

class AppContextMessageCreateConnectionResponse extends AppContextMessageResponse {
  final JSMessagePort port;
  const AppContextMessageCreateConnectionResponse({required this.port})
      : super(type: IsolateMessageTypes.createConnection);

  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageCreateConnectionResponse.serializationIdentifier");
  @override
  List<CborObject?> get serializationItems => throw AppInternalError.internalError(
      "AppContextMessageCreateConnectionResponse.serializationItems");
}

class AppContextConfigWeb with AppSerialization {
  final List<int>? contextKey;
  final SyncWorkerMode? mode;
  final LoggingConfig config;
  final String href;
  AppContextConfigWeb(
      {required this.config, this.mode, List<int>? contextKey, required this.href})
      : contextKey = contextKey?.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "AppContextConfigWeb",
          onErr: () => throw AppInternalError.internalError("Invalid context key"),
        );
  factory AppContextConfigWeb.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.appContextWebConfig,
        cborBytes: bytes,
        cborObject: object);
    return AppContextConfigWeb(
        contextKey: values.rawValueAt(0),
        mode: values.maybeRawValueAt<SyncWorkerMode, int>(
            1, (v) => SyncWorkerMode.fromValue(v)),
        config: LoggingConfig.deserialize(object: values.objectAt(2)),
        href: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appContextWebConfig;

  @override
  List<CborObject?> get serializationItems =>
      [contextKey?.toCborBytes(), mode?.value.toCbor(), config.toCbor(), href.toCbor()];
}

class AppContextConfigResponse with AppSerialization {
  final List<int> contextKey;
  AppContextConfigResponse({required List<int> contextKey})
      : contextKey = contextKey.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "AppContextConfigWeb",
          onErr: () => throw AppInternalError.internalError("Invalid context key"),
        );
  factory AppContextConfigResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.appContextWebConfig,
        cborBytes: bytes,
        cborObject: object);
    return AppContextConfigResponse(contextKey: values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appContextWebConfig;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(contextKey)];
}
