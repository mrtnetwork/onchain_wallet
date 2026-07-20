import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

import 'package:on_chain_wallet/network/bridge/onchain/types/events.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/api/utils/utils.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart'
    show WCMActionSession;

sealed class WCMActionRequest<RESPONSE extends Object?>
    extends WCMActionSession<RESPONSE> {
  const WCMActionRequest(
      {required super.messageType,
      required super.storageType,
      required super.mode,
      super.requestId})
      : super(method: BridgeKnownMethods.sessionRequest);

  factory WCMActionRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.wcmActionVerifyPair,
          AppSerializationIdentifier.wcmActionNetworkClientRequest,
          AppSerializationIdentifier.wcmActionGetWalletInfo,
          AppSerializationIdentifier.wcmActionNetworkClientSocketSubscribe,
          AppSerializationIdentifier.wcmActionNetworkClientSocketUnsubscribe,
          AppSerializationIdentifier.wcmActionNetworkClientGrpcStream,
          AppSerializationIdentifier.wcmActionNetworkClientGrpcUnsubscribe
        ]);
    final WCMActionRequest requeest = switch (decode.identifier) {
      AppSerializationIdentifier.wcmActionVerifyPair =>
        WCMActionRequestVerifyPair.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmActionGetWalletInfo =>
        WCMActionRequestGetWalletInfo.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmActionNetworkClientRequest =>
        WCMActionRequestNetworkClientRequest.deserialize(object: decode.tag),
      // AppSerializationIdentifier.wcmActionNetworkClientSocketSubscribe =>
      //   WCMActionRequestNetworkClientSocketSubscribe.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmActionNetworkClientSocketUnsubscribe =>
        WCMActionRequestNetworkClientSocketUnsubscribe.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("WCMActionRequest")
    };
    return requeest.cast();
  }
}

class WCMActionRequestVerifyPair extends WCMActionRequest<bool> {
  final List<int> checksum;
  final int clientId;
  WCMActionRequestVerifyPair({required this.checksum, required this.clientId})
      : super(
            mode: PublishMessageMode.publishAndResult,
            storageType: PublishMessageStorageType.memory,
            messageType: WCMBridgeMessageType.wallet);
  factory WCMActionRequestVerifyPair.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmActionVerifyPair,
        cborBytes: bytes,
        cborObject: object);
    return WCMActionRequestVerifyPair(
        checksum: values.rawValueAt(0), clientId: values.rawValueAt(1));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmActionVerifyPair;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(checksum), clientId.toCbor()];

  @override
  bool onResponse(Object? _) {
    return true;
  }
}

class WCMActionRequestGetWalletInfo extends WCMActionRequest<WCMEventWalletUpdated> {
  WCMActionRequestGetWalletInfo()
      : super(
            mode: PublishMessageMode.publishAndResult,
            storageType: PublishMessageStorageType.memory,
            messageType: WCMBridgeMessageType.wallet);
  factory WCMActionRequestGetWalletInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmActionGetWalletInfo,
        cborBytes: bytes,
        cborObject: object);
    return WCMActionRequestGetWalletInfo();
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmActionGetWalletInfo;

  @override
  List<CborObject?> get serializationItems => [];

  @override
  WCMEventWalletUpdated onResponse(Object? message) {
    return WCMEventWalletUpdated.deserialize(bytes: JsonParser.valueAsBytes(message));
  }
}

sealed class WCMActionRequestNetwork<RESPONSE extends Object?>
    extends WCMActionRequest<RESPONSE> {
  final int? network;
  const WCMActionRequestNetwork(
      {required this.network,
      required super.mode,
      required super.messageType,
      required super.storageType});
}

sealed class WCMActionRequestNetworkClient<RESPONSE extends Object?>
    extends WCMActionRequestNetwork<RESPONSE> {
  WCMActionRequestNetworkClient({
    required super.network,
    required PublishMessageMode? mode,
    required PublishMessageStorageType? storageType,
  }) : super(
          messageType: WCMBridgeMessageType.client,
          mode: mode ?? PublishMessageMode.publishAndResult,
          storageType: storageType ?? PublishMessageStorageType.memory,
        );
}

class WCMActionRequestNetworkClientRequest
    extends WCMActionRequestNetworkClient<WCMResultNetworkClientRequest> {
  final String providerIdentifier;
  final IServiceRequestParams request;
  final BaseServiceSubscribtionRequest? subscribtionRequest;
  final bool isStream;
  WCMActionRequestNetworkClientRequest._({
    required super.network,
    required this.providerIdentifier,
    required this.request,
    required this.isStream,
    this.subscribtionRequest,
    super.mode,
    super.storageType,
  });
  factory WCMActionRequestNetworkClientRequest.socket(
      {required int? network,
      required BaseServiceRequestParams request,
      BaseServiceSubscribtionRequest? subscribtionRequest,
      required String identifier}) {
    return WCMActionRequestNetworkClientRequest._(
        network: network,
        providerIdentifier: identifier,
        request: request,
        subscribtionRequest: subscribtionRequest,
        isStream: subscribtionRequest != null);
  }
  factory WCMActionRequestNetworkClientRequest.grpc(
      {required int? network,
      required BaseGRPCServiceRequestParams request,
      required String identifier,
      bool isStream = false}) {
    return WCMActionRequestNetworkClientRequest._(
        network: network,
        providerIdentifier: identifier,
        request: request,
        isStream: isStream);
  }
  factory WCMActionRequestNetworkClientRequest.http(
      {required int? network,
      required BaseServiceRequestParams request,
      required String identifier}) {
    return WCMActionRequestNetworkClientRequest._(
        network: network,
        providerIdentifier: identifier,
        request: request,
        isStream: false);
  }

  factory WCMActionRequestNetworkClientRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmActionNetworkClientRequest,
        cborBytes: bytes,
        cborObject: object);
    return WCMActionRequestNetworkClientRequest._(
        mode: PublishMessageMode.fromValue(values.rawValueAt(0)),
        storageType: PublishMessageStorageType.fromValue(values.rawValueAt(1)),
        network: values.rawValueAt(2),
        providerIdentifier: values.rawValueAt(3),
        request: APIUtils.deserializeRequest(object: values.objectAt(4)),
        subscribtionRequest:
            values.maybeObjectAt<BaseServiceSubscribtionRequest, CborTagValue>(
                5, (e) => APIUtils.deserializationStreamRequest(object: e)),
        isStream: values.rawValueAt(6));
  }
  @override
  WCMResultNetworkClientRequest onResponse(Object? message) {
    return WCMResultNetworkClientRequest.deserialize(
        bytes: JsonParser.valueAsBytes(message));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmActionNetworkClientRequest;

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        storageType.value.toCbor(),
        network?.toCbor(),
        providerIdentifier.toCbor(),
        request.toCbor(),
        subscribtionRequest?.toCbor(),
        isStream.toCbor()
      ];
}

class WCMActionRequestNetworkClientConnect
    extends WCMActionRequestNetworkClient<NetworkApiProvider> {
  WCMActionRequestNetworkClientConnect({
    required int super.network,
    super.mode,
    super.storageType,
  });
  factory WCMActionRequestNetworkClientConnect.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmActionNetworkClientConnect,
        cborBytes: bytes,
        cborObject: object);
    return WCMActionRequestNetworkClientConnect(
      mode: PublishMessageMode.fromValue(values.rawValueAt(0)),
      storageType: PublishMessageStorageType.fromValue(values.rawValueAt(1)),
      network: values.rawValueAt(2),
    );
  }
  @override
  NetworkApiProvider onResponse(Object? message) {
    return NetworkApiProvider.deserialize(bytes: JsonParser.valueAsBytes(message));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmActionNetworkClientConnect;

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        storageType.value.toCbor(),
      ];
}

class WCMActionRequestNetworkClientSocketUnsubscribe
    extends WCMActionRequestNetworkClient<void> {
  final String id;
  WCMActionRequestNetworkClientSocketUnsubscribe({
    required super.network,
    required this.id,
    super.mode,
    super.storageType,
  }) : super();
  factory WCMActionRequestNetworkClientSocketUnsubscribe.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmActionNetworkClientSocketUnsubscribe,
        cborBytes: bytes,
        cborObject: object);
    return WCMActionRequestNetworkClientSocketUnsubscribe(
      mode: PublishMessageMode.fromValue(values.rawValueAt(0)),
      storageType: PublishMessageStorageType.fromValue(values.rawValueAt(1)),
      network: values.rawValueAt(2),
      id: values.rawValueAt(3),
    );
  }
  @override
  void onResponse(Object? _) {}

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmActionNetworkClientSocketUnsubscribe;

  @override
  List<CborObject?> get serializationItems =>
      [mode.value.toCbor(), storageType.value.toCbor(), network?.toCbor(), id.toCbor()];
}

class WCMResultNetworkClientRequest extends AppSerialization {
  final ServiceResponseType status;
  final int statusCode;
  final List<int>? body;
  final String? subscribtionId;
  WCMResultNetworkClientRequest._({
    required this.status,
    required this.statusCode,
    this.body,
    this.subscribtionId,
  });
  WCMResultNetworkClientRequest({
    required this.status,
    required this.statusCode,
    List<int>? body,
    this.subscribtionId,
  }) : body = body?.asImmutableBytes;
  factory WCMResultNetworkClientRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcmResponseNetworkClientRequest);
    return WCMResultNetworkClientRequest(
        statusCode: values.rawValueAt(0),
        body: values.rawValueAt(1),
        status: ServiceResponseType.fromValue(values.rawValueAt(2)),
        subscribtionId: values.rawValueAt(3));
  }

  WCMResultNetworkClientRequest withSubscribtionId(String subscribtionId) {
    return WCMResultNetworkClientRequest._(
        status: status,
        statusCode: statusCode,
        body: body,
        subscribtionId: subscribtionId);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmResponseNetworkClientRequest;

  @override
  List<CborObject?> get serializationItems => [
        statusCode.toCbor(),
        AppSerialization.bytesToCbor(body),
        status.value.toCbor(),
        subscribtionId?.toCbor()
      ];
}
