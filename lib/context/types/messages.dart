import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';
import 'package:on_chain_wallet/network/net_api/models/stream.dart';

enum AppContextMessageSection {
  netSdk(0),
  database(1),
  isolateConnection(2),
  logging(3),
  crypto(4),
  shutdown(5),
  lockingTask(6),
  utils(7);

  final int value;
  const AppContextMessageSection(this.value);
  static AppContextMessageSection fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("AppContextMessageSection"),
    );
  }
}

sealed class ISolateMessage with AppSerialization {
  final int id;
  const ISolateMessage({required this.id});
  IsolateMessageTypes get type;
}

class ISolateMessageRequest<T extends AppContextMessageRequest> extends ISolateMessage {
  final T message;
  const ISolateMessageRequest({required super.id, required this.message});
  factory ISolateMessageRequest.deserialize(
      {List<int>? bytes,
      CborObject? object,
      AppContextMessage? Function(CborTagValue obj)? decode}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmIsolateMessageRequest,
        cborBytes: bytes,
        cborObject: object);
    AppContextMessage? message;
    if (decode != null) message = decode(values.objectAt(1));

    message ??= AppContextMessage.deserialize(object: values.objectAt(1));
    return ISolateMessageRequest(id: values.rawValueAt(0), message: message.cast<T>());
  }
  ISolateMessageRequest<E> as<E extends AppContextMessageRequest>() {
    if (this is ISolateMessageRequest<E>) return this as ISolateMessageRequest<E>;
    if (message is! E) throw AppInternalError.internalError("ISolateMessage");
    return ISolateMessageRequest<E>(id: id, message: message as E);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmIsolateMessageRequest;

  @override
  List<CborObject?> get serializationItems => [id.toCbor(), message.toCbor()];

  @override
  IsolateMessageTypes get type => message.type;

  @override
  String toString() {
    return "ISolateMessageRequest($message)";
  }
}

class ISolateMessageResponse<T extends AppContextMessageResponse> extends ISolateMessage {
  final IResult<T> message;
  @override
  final IsolateMessageTypes type;
  final AppContextMessageSection section;
  const ISolateMessageResponse(
      {required super.id,
      required this.message,
      required this.section,
      required this.type});
  factory ISolateMessageResponse.from(
      {required ISolateMessageRequest<AppContextMessageRequest> request,
      required IResult<T> response,
      int? id}) {
    return ISolateMessageResponse(
        id: id ?? request.id,
        message: response,
        section: request.message.section,
        type: response.ok()?.type ?? request.message.type);
  }

  factory ISolateMessageResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmIsolateMessageResponse,
        cborBytes: bytes,
        cborObject: object);
    final error = values.objectAt<CborTagValue?>(1);
    return ISolateMessageResponse(
        id: values.rawValueAt(0),
        message: switch (error) {
          CborTagValue v =>
            ResultErr.fromException(IExceptionUtils.deserialize(object: v)),
          _ => ResultOk(AppContextMessage.deserialize(object: values.objectAt(2)).cast())
        },
        section: AppContextMessageSection.fromValue(values.rawValueAt(3)),
        type: IsolateMessageTypes.fromValue(values.rawValueAt(4)));
  }

  ISolateMessageResponse<E> as<E extends AppContextMessageResponse>() {
    if (this is ISolateMessageResponse<E>) return this as ISolateMessageResponse<E>;
    return ISolateMessageResponse<E>(
        id: id, message: message.cast<E>(), section: section, type: type);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmIsolateMessageResponse;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        message.err()?.exception.toCbor(),
        message.ok()?.toCbor(),
        section.value.toCbor(),
        type.value.toCbor()
      ];
}

sealed class AppContextMessage with AppSerialization {
  final IsolateMessageTypes type;
  const AppContextMessage({required this.type});
  T cast<T extends AppContextMessage>() {
    if (this is T) return this as T;
    throw AppInternalError.internalError("AppContextMessage");
  }

  factory AppContextMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      AppSerializationIdentifier.acmNetSdkResponseTransport,
      AppSerializationIdentifier.acmNetSdkResponseStream,
      AppSerializationIdentifier.acmNetSdkResponseRequest,
      AppSerializationIdentifier.acmNetSdkRequestTransport,
      AppSerializationIdentifier.acmNetSdkRequestRequest,
      AppSerializationIdentifier.acmDatabaseRequestIStorageAction,
      AppSerializationIdentifier.acmDatabaseRequestITableAction,
      AppSerializationIdentifier.acmDatabaseSerializableResponse,
      AppSerializationIdentifier.acmCreateConnection,
      AppSerializationIdentifier.acmStablishConnectionResponse,
      AppSerializationIdentifier.acmStablishConnectionRequest,
      AppSerializationIdentifier.acmLoggingRequest,
      AppSerializationIdentifier.acmShutdownReuest,
      AppSerializationIdentifier.acmCryptoRequest,
      AppSerializationIdentifier.acmCryptoResponse,
      AppSerializationIdentifier.acmLockingTaskRequest,
      AppSerializationIdentifier.acmLockingTaskResponse,
      AppSerializationIdentifier.acmReleaseTaskRequest,
      AppSerializationIdentifier.acmUtilsRequestGetAndStoreBinary,
      AppSerializationIdentifier.acmUtilsResponseStreamProgress,
      AppSerializationIdentifier.acmUtilsRequestGetData,
      // AppSerializationIdentifier.acmUtilsResponseGetData,
      AppSerializationIdentifier.acmUtilsRequestStoreData,
      AppSerializationIdentifier.acmUtilsRequestVerifyData,
      AppSerializationIdentifier.acmUtilsResponseVerifyData,
      AppSerializationIdentifier.acmResponseSuccess,
      AppSerializationIdentifier.acmUtilsRequestStopStreaming
    ], cborBytes: bytes, cborObject: object);
    final obj = decode.tag;
    final identifier = decode.identifier;
    return switch (identifier) {
      AppSerializationIdentifier.acmNetSdkResponseTransport =>
        AppContextMessageNetSdkResponseTransport.deserialize(object: obj),
      AppSerializationIdentifier.acmNetSdkResponseStream =>
        AppContextMessageNetSdkResponseStream.deserialize(object: obj),
      AppSerializationIdentifier.acmNetSdkResponseRequest =>
        AppContextMessageNetSdkResponseRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmNetSdkRequestTransport =>
        AppContextMessageNetSdkRequestTransport.deserialize(object: obj),
      AppSerializationIdentifier.acmNetSdkRequestRequest =>
        AppContextMessageNetSdkRequestRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmDatabaseRequestIStorageAction =>
        AppContextMessageDatabaseRequestIStorageAction.deserialize(object: obj),
      AppSerializationIdentifier.acmDatabaseRequestITableAction =>
        AppContextMessageDatabaseRequestITableAction.deserialize(object: obj),
      AppSerializationIdentifier.acmDatabaseSerializableResponse =>
        AppContextMessageDatabaseSerializableResult.deserialize(object: obj),
      AppSerializationIdentifier.acmCreateConnection =>
        AppContextMessageCreateConnectionRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmStablishConnectionResponse =>
        AppContextMessageStablishConnectionResponse.deserialize(object: obj),
      AppSerializationIdentifier.acmStablishConnectionRequest =>
        AppContextMessageStablishConnection.deserialize(object: obj),
      AppSerializationIdentifier.acmLoggingRequest =>
        AppContextMessageLoggingRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmShutdownReuest =>
        AppContextMessageShutdownRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmCryptoRequest =>
        AppContextMessageCryptoRequestDefault.deserialize(object: obj),
      AppSerializationIdentifier.acmCryptoResponse =>
        AppContextMessageCryptoResponseDefault.deserialize(object: obj),
      AppSerializationIdentifier.acmLockingTaskRequest =>
        AppContextMessageLockingTaskRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmLockingTaskResponse =>
        AppContextMessageLockingTaskResponse.deserialize(object: obj),
      AppSerializationIdentifier.acmReleaseTaskRequest =>
        AppContextMessageReleaseTaskRequest.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsRequestGetAndStoreBinary =>
        AppContextMessageUtilsRequestFetchAndStoreBinary.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsResponseStreamProgress =>
        AppContextMessageUtilsResponseStreamProgress.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsRequestGetData =>
        AppContextMessageUtilsRequestGetData.deserialize(object: obj),
      // AppSerializationIdentifier.acmUtilsResponseGetData =>
      //   AppContextMessageUtilsResponseGetData.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsRequestStoreData =>
        AppContextMessageUtilsRequestStoreOrRemoveData.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsRequestVerifyData =>
        AppContextMessageUtilsRequestVerifyData.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsResponseVerifyData =>
        AppContextMessageUtilsResponseVerifyData.deserialize(object: obj),
      AppSerializationIdentifier.acmResponseSuccess =>
        AppContextMessageResponseSuccess.deserialize(object: obj),
      AppSerializationIdentifier.acmUtilsRequestStopStreaming =>
        AppContextMessageUtilsRequestStopStreaming.deserialize(object: obj),
      _ => throw AppInternalError.internalError("AppContextMessage.deserialize",
          details: {"tags": obj.tags.join(",")})
    };
  }
}

abstract class AppContextMessageResponse extends AppContextMessage {
  const AppContextMessageResponse({required super.type});
}

abstract class AppContextMessageRequest extends AppContextMessage {
  const AppContextMessageRequest({required this.section, required super.type});
  final AppContextMessageSection section;

  @override
  String toString() {
    return "AppContextMessageRequest($section/$type)";
  }
}

sealed class AppContextMessageNetSdkResponse extends AppContextMessageResponse {
  const AppContextMessageNetSdkResponse({required super.type});
}

class AppContextMessageStablishConnection extends AppContextMessageRequest {
  final List<int> contextKey;
  AppContextMessageStablishConnection(List<int> contextKey)
      : contextKey = contextKey.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "AppContextMessageStablishConnection",
          onErr: () => throw AppInternalError.internalError("Invalid context key"),
        ),
        super(
            section: AppContextMessageSection.isolateConnection,
            type: IsolateMessageTypes.stablishConnection);

  factory AppContextMessageStablishConnection.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmStablishConnectionRequest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageStablishConnection(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmStablishConnectionRequest;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(contextKey)];
  @override
  String toString() {
    return "AppContextMessageNetSdkResponseTransport()";
  }
}

class AppContextMessageNetSdkResponseTransport extends AppContextMessageNetSdkResponse {
  final Result<int, NetResultStatus> transportId;
  const AppContextMessageNetSdkResponseTransport({
    required this.transportId,
  }) : super(type: IsolateMessageTypes.netSdkTransport);
  factory AppContextMessageNetSdkResponseTransport.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmNetSdkResponseTransport,
        cborBytes: bytes,
        cborObject: object);
    final transportId = values.rawValueAt<int?>(0);
    return AppContextMessageNetSdkResponseTransport(
      transportId: switch (transportId) {
        null => Err(NetResultStatus.fromValue(values.rawValueAt(1))),
        int id => Ok(id)
      },
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmNetSdkResponseTransport;

  @override
  List<CborObject?> get serializationItems =>
      [transportId.ok()?.toCbor(), transportId.err()?.value.toCbor()];
  @override
  String toString() {
    return "NetResponseStream({result:$transportId})";
  }
}

class AppContextMessageNetSdkResponseStream extends AppContextMessageNetSdkResponse {
  final NetResponseStream messages;
  final int transportId;
  const AppContextMessageNetSdkResponseStream(
      {required this.messages, required this.transportId})
      : super(type: IsolateMessageTypes.netSdkStream);
  factory AppContextMessageNetSdkResponseStream.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmNetSdkResponseStream,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageNetSdkResponseStream(
        messages: NetResponseStream.deserialize(object: values.objectAt(0)),
        transportId: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmNetSdkResponseStream;

  @override
  List<CborObject?> get serializationItems => [messages.toCbor(), transportId.toCbor()];

  @override
  String toString() {
    return "NetResponseStream(result:$messages})";
  }
}

class AppContextMessageNetSdkResponseRequest extends AppContextMessageNetSdkResponse {
  final Result<NetResponse, NetResultStatus> result;
  const AppContextMessageNetSdkResponseRequest({required this.result})
      : super(type: IsolateMessageTypes.netSdkRequest);
  factory AppContextMessageNetSdkResponseRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmNetSdkResponseRequest,
        cborBytes: bytes,
        cborObject: object);
    final error = values.rawValueAt<int?>(1);
    return AppContextMessageNetSdkResponseRequest(
      result: switch (error) {
        null => Ok(NetResponse.deserialize(object: values.objectAt(0))),
        int id => Err(NetResultStatus.fromValue(id))
      },
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmNetSdkResponseRequest;

  @override
  List<CborObject?> get serializationItems =>
      [result.ok()?.toCbor(), result.err()?.value.toCbor()];
  @override
  String toString() {
    return "NetSdkWorkerMessageRequest({result:$result})";
  }
}

sealed class AppContextMessageNetSdkRequest<T extends Object>
    extends AppContextMessageRequest {
  final T request;
  const AppContextMessageNetSdkRequest({required this.request, required super.type})
      : super(section: AppContextMessageSection.netSdk);
}

class AppContextMessageNetSdkRequestTransport
    extends AppContextMessageNetSdkRequest<NetConfigRequest> {
  AppContextMessageNetSdkRequestTransport({required super.request})
      : super(type: IsolateMessageTypes.netSdkTransport);
  factory AppContextMessageNetSdkRequestTransport.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmNetSdkRequestTransport,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageNetSdkRequestTransport(
        request: NetConfigRequest.deserialize(object: values.objectAt(0)));
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmNetSdkRequestTransport;
}

class AppContextMessageNetSdkRequestRequest
    extends AppContextMessageNetSdkRequest<NetRequest> {
  AppContextMessageNetSdkRequestRequest({required super.request})
      : super(type: IsolateMessageTypes.netSdkRequest);

  factory AppContextMessageNetSdkRequestRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmNetSdkRequestRequest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageNetSdkRequestRequest(
        request: NetRequest.deserialize(object: values.objectAt(0)));
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmNetSdkRequestRequest;
}

sealed class AppContextMessageDatabase extends AppContextMessage {
  const AppContextMessageDatabase({required super.type});
}

sealed class AppContextMessageDatabaseRequest extends AppContextMessageRequest
    implements AppContextMessageDatabase {
  const AppContextMessageDatabaseRequest({required super.type})
      : super(section: AppContextMessageSection.database);
}

class AppContextMessageDatabaseRequestIStorageAction
    extends AppContextMessageDatabaseRequest {
  final IStorageAction action;
  const AppContextMessageDatabaseRequestIStorageAction({
    required this.action,
  }) : super(type: IsolateMessageTypes.databaseIStorageAction);
  factory AppContextMessageDatabaseRequestIStorageAction.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmDatabaseRequestIStorageAction,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageDatabaseRequestIStorageAction(
        action: IStorageAction.deserialize(obj: values.objectAt(0)));
  }

  @override
  List<CborObject?> get serializationItems => [action.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmDatabaseRequestIStorageAction;
}

class AppContextMessageDatabaseRequestITableAction
    extends AppContextMessageDatabaseRequest {
  final ITableAction action;
  const AppContextMessageDatabaseRequestITableAction({
    required this.action,
  }) : super(type: IsolateMessageTypes.databaseITableAction);

  factory AppContextMessageDatabaseRequestITableAction.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmDatabaseRequestITableAction,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageDatabaseRequestITableAction(
        action: ITableAction.deserialize(obj: values.objectAt(0)));
  }

  @override
  List<CborObject?> get serializationItems => [action.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmDatabaseRequestITableAction;
}

sealed class AppContextMessageDatabaseResponse extends AppContextMessageDatabase
    implements AppContextMessageResponse {
  const AppContextMessageDatabaseResponse({required super.type});
}

class AppContextMessageDatabaseResult extends AppContextMessageDatabaseResponse {
  final Object? response;
  const AppContextMessageDatabaseResult({required this.response})
      : super(type: IsolateMessageTypes.databaseResponse);

  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageDatabaseResult.serializationIdentifier");

  @override
  List<CborObject?> get serializationItems => throw AppInternalError.internalError(
      "AppContextMessageDatabaseResult.serializationItems");
}

class AppContextMessageDatabaseSerializableResult
    extends AppContextMessageDatabaseResponse {
  final CborObject response;
  const AppContextMessageDatabaseSerializableResult({required this.response})
      : super(type: IsolateMessageTypes.databaseResponse);

  factory AppContextMessageDatabaseSerializableResult.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmDatabaseSerializableResponse,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageDatabaseSerializableResult(response: values.objectAt(0));
  }

  @override
  List<CborObject?> get serializationItems => [response];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmDatabaseSerializableResponse;
}

class AppContextMessageCreateConnectionRequest extends AppContextMessageRequest {
  const AppContextMessageCreateConnectionRequest()
      : super(
            section: AppContextMessageSection.isolateConnection,
            type: IsolateMessageTypes.createConnection);
  factory AppContextMessageCreateConnectionRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmCreateConnection,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageCreateConnectionRequest();
  }

  @override
  List<CborObject?> get serializationItems => [];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmCreateConnection;
}

class AppContextMessageStablishConnectionResponse extends AppContextMessageResponse {
  AppContextMessageStablishConnectionResponse(
      {required this.modes,
      required this.netApiTarget,
      required this.connectionId,
      required List<int> contextKey})
      : contextKey = contextKey.asImmutableBytes.exc(
          length: Ed25519KeysConst.privKeyByteLen,
          operation: "AppContextMessageStablishConnectionResponse",
          onErr: () => throw AppInternalError.internalError("Invalid context key"),
        ),
        super(type: IsolateMessageTypes.stablishConnection);
  final List<NetMode> modes;
  final NetApiTarget netApiTarget;
  final String connectionId;
  final List<int> contextKey;
  factory AppContextMessageStablishConnectionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmStablishConnectionResponse,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageStablishConnectionResponse(
        modes: values
            .listAt<CborIntValue>(0)
            .map((e) => NetMode.fromValue(e.value))
            .toList(),
        netApiTarget: NetApiTarget.fromValue(values.rawValueAt(1)),
        connectionId: values.rawValueAt(2),
        contextKey: values.rawValueAt(3));
  }

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(
            modes.map((e) => CborIntValue(e.value)).toList()),
        netApiTarget.value.toCbor(),
        connectionId.toCbor(),
        CborBytesValue(contextKey)
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmStablishConnectionResponse;
}

abstract class AppContextMessageCryptoRequest<MSG extends IIsolateCryptoMessage>
    extends AppContextMessageRequest {
  final MSG message;
  const AppContextMessageCryptoRequest({required this.message, required super.type})
      : super(section: AppContextMessageSection.crypto);
}

class AppContextMessageCryptoRequestDefault
    extends AppContextMessageCryptoRequest<IIsolateCryptoSerializableMessage> {
  const AppContextMessageCryptoRequestDefault(IIsolateCryptoSerializableMessage message)
      : super(type: IsolateMessageTypes.crypto, message: message);
  factory AppContextMessageCryptoRequestDefault.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmCryptoRequest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageCryptoRequestDefault(
        IIsolateCryptoSerializableMessage.deserialize(object: values.objectAt(0)));
  }

  @override
  List<CborObject?> get serializationItems => [message.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmCryptoRequest;
}

abstract class AppContextMessageCryptoResponse<MSG extends IIsolateCryptoMessage>
    extends AppContextMessageResponse {
  final MSG message;
  const AppContextMessageCryptoResponse({required this.message, required super.type});
}

class AppContextMessageCryptoResponseDefault
    extends AppContextMessageCryptoResponse<IIsolateCryptoSerializableMessage> {
  const AppContextMessageCryptoResponseDefault(IIsolateCryptoSerializableMessage message)
      : super(type: IsolateMessageTypes.crypto, message: message);
  factory AppContextMessageCryptoResponseDefault.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmCryptoResponse,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageCryptoResponseDefault(
        IIsolateCryptoSerializableMessage.deserialize(object: values.objectAt(0)));
  }

  @override
  List<CborObject?> get serializationItems => [message.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmCryptoResponse;
}

class AppContextMessageLoggingRequest extends AppContextMessageRequest {
  final LogMessageMessage message;
  AppContextMessageLoggingRequest(this.message)
      : super(
            section: AppContextMessageSection.logging, type: IsolateMessageTypes.logging);
  factory AppContextMessageLoggingRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmLoggingRequest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageLoggingRequest(
        LogMessageMessage.deserialize(object: values.objectAt(0)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmLoggingRequest;

  @override
  List<CborObject?> get serializationItems => [message.toCbor()];
}

class AppContextMessageShutdownRequest extends AppContextMessageRequest {
  final String connectionId;
  AppContextMessageShutdownRequest(this.connectionId)
      : super(
            section: AppContextMessageSection.shutdown,
            type: IsolateMessageTypes.shutdown);
  factory AppContextMessageShutdownRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmShutdownReuest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageShutdownRequest(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmShutdownReuest;

  @override
  List<CborObject?> get serializationItems => [connectionId.toCbor()];
}

class AppContextMessageLockingTaskRequest extends AppContextMessageRequest {
  final String identifier;
  final Duration timeout;
  final Duration releaseTimeout;
  AppContextMessageLockingTaskRequest(
      {required this.identifier, required this.timeout, required this.releaseTimeout})
      : super(
            section: AppContextMessageSection.lockingTask,
            type: IsolateMessageTypes.lockingTask);
  factory AppContextMessageLockingTaskRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmLockingTaskRequest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageLockingTaskRequest(
        identifier: values.rawValueAt(0),
        timeout: Duration(seconds: values.rawValueAt(1)),
        releaseTimeout: Duration(seconds: values.rawValueAt(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmLockingTaskRequest;

  @override
  List<CborObject?> get serializationItems => [
        identifier.toCbor(),
        timeout.inSeconds.toCbor(),
        releaseTimeout.inSeconds.toCbor()
      ];
}

class AppContextMessageReleaseTaskRequest extends AppContextMessageRequest {
  final String identifier;
  final int id;
  AppContextMessageReleaseTaskRequest({required this.identifier, required this.id})
      : super(
            section: AppContextMessageSection.lockingTask,
            type: IsolateMessageTypes.releaseTask);
  factory AppContextMessageReleaseTaskRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmReleaseTaskRequest,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageReleaseTaskRequest(
        identifier: values.rawValueAt(0), id: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmReleaseTaskRequest;

  @override
  List<CborObject?> get serializationItems => [identifier.toCbor(), id.toCbor()];
}

class AppContextMessageLockingTaskResponse extends AppContextMessageResponse {
  final int lockingId;
  AppContextMessageLockingTaskResponse(this.lockingId)
      : super(type: IsolateMessageTypes.lockingTask);
  factory AppContextMessageLockingTaskResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmLockingTaskResponse,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageLockingTaskResponse(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmLockingTaskResponse;

  @override
  List<CborObject?> get serializationItems => [lockingId.toCbor()];
}

extension ExtAppContextResponseFilter
    on Stream<ISolateMessageResponse<AppContextMessageResponse>> {
  Stream<ISolateMessageResponse<T>> filterMessage<T extends AppContextMessageResponse>(
      AppContextMessageSection type) {
    return where((e) => e.section == type).map((e) => e.as<T>());
  }

  Stream<ISolateMessageResponse<AppContextMessageResponse>> filterMessages(
      List<AppContextMessageSection> types) {
    return where((e) => types.contains(e.section));
  }
}

extension ExtAppContextRequestFilter
    on Stream<ISolateMessageRequest<AppContextMessageRequest>> {
  Stream<ISolateMessageRequest<T>> filterMessage<T extends AppContextMessageRequest>(
      AppContextMessageSection type) {
    return where((e) => e.message.section == type).map((e) => e.as<T>());
  }
}

abstract class AppContextMessageUtilsRequest extends AppContextMessageRequest {
  const AppContextMessageUtilsRequest({required super.type})
      : super(section: AppContextMessageSection.utils);
}

abstract class AppContextMessageUtilsResponse extends AppContextMessageResponse {
  const AppContextMessageUtilsResponse({required super.type});
}

class AppContextMessageUtilsRequestFetchAndStoreBinary
    extends AppContextMessageUtilsRequest {
  final List<String> urls;
  final RuntimeResourceLocation location;
  final Duration timeout;
  final Duration streamTimeout;
  final String? streamTrackerId;
  final Map<String, String> headers;
  AppContextMessageUtilsRequestFetchAndStoreBinary(
      {required List<String> urls,
      required this.location,
      required this.timeout,
      required this.streamTimeout,
      required this.streamTrackerId,
      required this.headers})
      : urls = urls.immutable,
        super(type: IsolateMessageTypes.utilsFetchAndStoreBinary);
  factory AppContextMessageUtilsRequestFetchAndStoreBinary.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsRequestGetAndStoreBinary,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsRequestFetchAndStoreBinary(
        urls: values.listAt<CborStringValue>(0).map((e) => e.value).toList(),
        location: RuntimeResourceLocation.deserialize(object: values.objectAt(1)),
        timeout: Duration(seconds: values.rawValueAt(2)),
        streamTimeout: Duration(seconds: values.rawValueAt(3)),
        streamTrackerId: values.rawValueAt(4),
        headers: values.rawMapAt<String, String>(5));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsRequestGetAndStoreBinary;

  @override
  List<CborObject<Object?>?> get serializationItems => [
        urls.toCbor(),
        location.toCbor(),
        timeout.inSeconds.toCbor(),
        streamTimeout.inSeconds.toCbor(),
        streamTrackerId?.toCbor(),
        headers.toCbor()
      ];
}

class AppContextMessageUtilsResponseStreamProgress
    extends AppContextMessageUtilsResponse {
  final String identifier;
  final StreamProgress progress;
  const AppContextMessageUtilsResponseStreamProgress({
    required this.progress,
    required this.identifier,
  }) : super(type: IsolateMessageTypes.utilsStreamProgress);
  factory AppContextMessageUtilsResponseStreamProgress.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsResponseStreamProgress,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsResponseStreamProgress(
        progress: StreamProgress.deserialize(object: values.objectAt(0)),
        identifier: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsResponseStreamProgress;

  @override
  List<CborObject<Object?>?> get serializationItems =>
      [progress.toCbor(), identifier.toCbor()];
}

class AppContextMessageUtilsRequestGetData extends AppContextMessageUtilsRequest {
  final RuntimeResourceLocation location;
  const AppContextMessageUtilsRequestGetData({
    required this.location,
  }) : super(type: IsolateMessageTypes.utilsGetData);
  factory AppContextMessageUtilsRequestGetData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsRequestGetData,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsRequestGetData(
      location: RuntimeResourceLocation.deserialize(object: values.objectAt(0)),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsRequestGetData;

  @override
  List<CborObject<Object?>?> get serializationItems => [
        location.toCbor(),
      ];
}

class AppContextMessageUtilsResponseGetData extends AppContextMessageUtilsResponse {
  final ICrossFile? data;
  AppContextMessageUtilsResponseGetData(this.data)
      : super(type: IsolateMessageTypes.utilsGetData);
  // factory AppContextMessageUtilsResponseGetData.deserialize(
  //     {List<int>? bytes, CborObject? object}) {
  //   final values = AppSerialization.decodeTaggedValue(
  //       identifier: AppSerializationIdentifier.acmUtilsResponseGetData,
  //       cborBytes: bytes,
  //       cborObject: object);
  //   return AppContextMessageUtilsResponseGetData(values.rawValueAt(0));
  // }

  @override
  SerializationIdentifier get serializationIdentifier =>
      throw AppInternalError.internalError(
          "AppContextMessageDatabaseResult.serializationIdentifier");

  @override
  List<CborObject<Object?>?> get serializationItems =>
      throw AppInternalError.internalError(
          "AppContextMessageDatabaseResult.serializationIdentifier");
}

class AppContextMessageUtilsRequestStoreOrRemoveData
    extends AppContextMessageUtilsRequest {
  final RuntimeResourceLocation location;
  final List<int>? data;

  AppContextMessageUtilsRequestStoreOrRemoveData({
    required this.location,
    required List<int>? data,
  })  : data = data?.immutable,
        super(type: IsolateMessageTypes.utilsStoreData);
  factory AppContextMessageUtilsRequestStoreOrRemoveData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsRequestStoreData,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsRequestStoreOrRemoveData(
        location: RuntimeResourceLocation.deserialize(object: values.objectAt(0)),
        data: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsRequestStoreData;

  @override
  List<CborObject<Object?>?> get serializationItems =>
      [location.toCbor(), data?.toCborBytes()];
}

class AppContextMessageUtilsRequestVerifyData extends AppContextMessageUtilsRequest {
  final RuntimeResourceLocation location;
  AppContextMessageUtilsRequestVerifyData({required this.location})
      : super(type: IsolateMessageTypes.utilsVerifyData);
  factory AppContextMessageUtilsRequestVerifyData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsRequestVerifyData,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsRequestVerifyData(
        location: RuntimeResourceLocation.deserialize(object: values.objectAt(0)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsRequestVerifyData;

  @override
  List<CborObject<Object?>?> get serializationItems => [location.toCbor()];
}

class AppContextMessageUtilsResponseVerifyData extends AppContextMessageUtilsResponse {
  final bool verify;
  AppContextMessageUtilsResponseVerifyData(this.verify)
      : super(type: IsolateMessageTypes.utilsVerifyData);
  factory AppContextMessageUtilsResponseVerifyData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsResponseVerifyData,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsResponseVerifyData(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsResponseVerifyData;

  @override
  List<CborObject<Object?>?> get serializationItems => [verify.toCbor()];
}

class AppContextMessageUtilsRequestStoreFile extends AppContextMessageUtilsRequest {
  final RuntimeResourceLocation location;
  final ICrossFile file;
  AppContextMessageUtilsRequestStoreFile({required this.location, required this.file})
      : super(type: IsolateMessageTypes.utilsStoreFile);

  factory AppContextMessageUtilsRequestStoreFile.deserialize(ICrossFile file,
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsRequestStoreFile,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsRequestStoreFile(
        location: RuntimeResourceLocation.deserialize(object: values.objectAt(0)),
        file: file);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsRequestStoreFile;

  @override
  List<CborObject<Object?>?> get serializationItems => [location.toCbor()];
}

class AppContextMessageResponseSuccess extends AppContextMessageResponse {
  AppContextMessageResponseSuccess._({required super.type});
  factory AppContextMessageResponseSuccess.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmResponseSuccess,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageResponseSuccess._(
        type: IsolateMessageTypes.fromValue(values.rawValueAt(0)));
  }
  factory AppContextMessageResponseSuccess.storeFile() =>
      AppContextMessageResponseSuccess._(type: IsolateMessageTypes.utilsStoreFile);
  factory AppContextMessageResponseSuccess.storeOrRemoveData() =>
      AppContextMessageResponseSuccess._(type: IsolateMessageTypes.utilsStoreData);
  factory AppContextMessageResponseSuccess.releaseTask() =>
      AppContextMessageResponseSuccess._(type: IsolateMessageTypes.releaseTask);
  factory AppContextMessageResponseSuccess.fetchAndStoreBinary() =>
      AppContextMessageResponseSuccess._(
          type: IsolateMessageTypes.utilsFetchAndStoreBinary);
  factory AppContextMessageResponseSuccess.stopStreaming() =>
      AppContextMessageResponseSuccess._(type: IsolateMessageTypes.stopStreaming);
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmResponseSuccess;

  @override
  List<CborObject<Object?>?> get serializationItems => [type.value.toCbor()];
}

class AppContextMessageUtilsRequestStopStreaming extends AppContextMessageUtilsRequest {
  final String identifier;
  AppContextMessageUtilsRequestStopStreaming({
    required this.identifier,
  }) : super(type: IsolateMessageTypes.stopStreaming);
  factory AppContextMessageUtilsRequestStopStreaming.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.acmUtilsRequestStopStreaming,
        cborBytes: bytes,
        cborObject: object);
    return AppContextMessageUtilsRequestStopStreaming(identifier: values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.acmUtilsRequestStopStreaming;

  @override
  List<CborObject<Object?>?> get serializationItems => [identifier.toCbor()];
}
