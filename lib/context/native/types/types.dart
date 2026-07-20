import 'dart:isolate';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/models/path/path.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';

class AppContextMessageCreateConnectionResponseNative extends AppContextMessageResponse {
  final SendPort port;
  const AppContextMessageCreateConnectionResponseNative(this.port)
      : super(type: IsolateMessageTypes.createConnection);
  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageCreateConnectionResponse.serializationIdentifier");

  @override
  List<CborObject?> get serializationItems => throw AppInternalError.internalError(
      "AppContextMessageCreateConnectionResponse.serializationItems");
}

class AppContextMessageStablishConnectionRequestNative extends AppContextMessageRequest {
  final SendPort port;
  final List<int> contextKey;
  AppContextMessageStablishConnectionRequestNative(
      {required this.port, required List<int> contextKey})
      : contextKey = contextKey.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "",
          onErr: () => throw AppInternalError.internalError(
              "AppContextMessageStablishConnectionRequestNative.contextKey"),
        ),
        super(
            section: AppContextMessageSection.isolateConnection,
            type: IsolateMessageTypes.stablishConnection);

  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageStablishConnectionRequestNative.serializationIdentifier");
  @override
  List<CborObject?> get serializationItems => throw AppInternalError.internalError(
      "AppContextMessageStablishConnectionRequestNative.serializationItems");
}

class AppContextConfigNative {
  final AppPath path;
  final String? dbKey;
  final LoggingConfig loggingConfig;
  final AppPlatform platform;
  final List<int>? contextKey;
  final SyncWorkerMode? mode;
  AppContextConfigNative(
      {required this.path,
      this.dbKey,
      required this.loggingConfig,
      required this.platform,
      this.mode,
      List<int>? contextKey})
      : contextKey = contextKey?.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "IsolateNetSdkNativeConfig",
          onErr: () => throw AppInternalError.internalError("Invalid context key"),
        );
}

class IsolateNetSdkNativeConfig {
  final List<NetMode> modes;
  final NetApiTarget target;
  final String databaseKey;
  final List<int> contextKey;
  IsolateNetSdkNativeConfig(
      {required this.modes,
      required this.target,
      required this.databaseKey,
      required List<int> contextKey})
      : contextKey = contextKey.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "IsolateNetSdkNativeConfig",
          onErr: () => throw AppInternalError.internalError("Invalid context key"),
        );
}

class AppContextMessageCryptoResponseNative
    extends AppContextMessageCryptoResponse<IIsolateCryptoMessageNative> {
  const AppContextMessageCryptoResponseNative(IIsolateCryptoMessageNative message)
      : super(message: message, type: IsolateMessageTypes.crypto);
  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageCryptoResponseNative.serializationIdentifier");

  @override
  List<CborObject?> get serializationItems => throw AppInternalError.internalError(
      "AppContextMessageCryptoResponseNative.serializationItems");
}

class AppContextMessageCryptoRequestNative
    extends AppContextMessageCryptoRequest<IIsolateCryptoMessageNative> {
  const AppContextMessageCryptoRequestNative(IIsolateCryptoMessageNative message)
      : super(message: message, type: IsolateMessageTypes.crypto);

  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageCryptoRequestNative.serializationIdentifier");
  @override
  List<CborObject?> get serializationItems => throw AppInternalError.internalError(
      "AppContextMessageCryptoRequestNative.serializationItems");
}
