import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/utils.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';

sealed class WCMActionEvent extends WCMActionSession<bool> {
  const WCMActionEvent(
      {required super.messageType,
      required super.mode,
      required super.storageType,
      super.requestId})
      : super(method: BridgeKnownMethods.sessionEvent);
  factory WCMActionEvent.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.wcmEventStorage,
          AppSerializationIdentifier.wcmEventWalletUpdated,
          AppSerializationIdentifier.wcmEventWalletUnlocked,
          AppSerializationIdentifier.wcmEventNetworkClientStreamData,
          AppSerializationIdentifier.wcmEventNetworkClientStreamStatus
        ]);
    final WCMActionEvent requeest = switch (decode.identifier) {
      AppSerializationIdentifier.wcmEventStorage =>
        WCMEventStorage.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmEventWalletUpdated =>
        WCMEventWalletUpdated.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmEventWalletUnlocked =>
        WCMEventWalletUnlocked.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmEventNetworkClientStreamData =>
        WCMEventNetworkClientStreamData.deserialize(object: decode.tag),
      AppSerializationIdentifier.wcmEventNetworkClientStreamStatus =>
        WCMEventNetworkClientStreamStatus.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("WCMAction")
    };
    return requeest;
  }
  @override
  List<int> serialize() {
    return toCbor().encode();
  }

  @override
  bool onResponse(Object? _) {
    return true;
  }
}

class WCMEventStorage extends WCMActionEvent {
  final IStorageEvent event;
  WCMEventStorage({required this.event})
      : super(
            mode: PublishMessageMode.publishAndResult,
            storageType: PublishMessageStorageType.database,
            messageType: WCMBridgeMessageType.storage,
            requestId: BridgeUtils.createStorageRequestId(event));
  factory WCMEventStorage.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmEventStorage,
        cborBytes: bytes,
        cborObject: object);
    return WCMEventStorage(event: IStorageEvent.deserialize(obj: values.objectAt(0)));
  }
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmEventStorage;

  @override
  List<CborObject?> get serializationItems => [event.toCbor()];
}

class WCMEventWalletUpdated extends WCMActionEvent {
  final List<ViewImportedSecretKey> importedKeys;
  final List<ViewSubWalletKey> subWallets;

  WCMEventWalletUpdated({
    required List<ViewImportedSecretKey> importedKeys,
    required List<ViewSubWalletKey> subWallets,
  })  : importedKeys = importedKeys.immutable,
        subWallets = subWallets.immutable,
        super(
            mode: PublishMessageMode.publishAndResult,
            storageType: PublishMessageStorageType.memory,
            messageType: WCMBridgeMessageType.wallet);
  factory WCMEventWalletUpdated.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmEventWalletUpdated,
        cborBytes: bytes,
        cborObject: object);
    return WCMEventWalletUpdated(
      importedKeys: values
          .listAt<CborObject>(0)
          .map((e) => ViewImportedSecretKey.deserialize(object: e))
          .toList(),
      subWallets: values
          .listAt<CborObject>(1)
          .map((e) => ViewSubWalletKey.deserialize(object: e))
          .toList(),
    );
  }
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmEventWalletUpdated;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(importedKeys.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(subWallets.map((e) => e.toCbor()).toList())
      ];
  @override
  PublishMessageStorageType get storageType => PublishMessageStorageType.memory;
}

class WCMEventWalletUnlocked extends WCMActionEvent {
  final WCMEventWalletUpdated update;
  WCMEventWalletUnlocked(this.update)
      : super(
            mode: PublishMessageMode.publishAndResult,
            storageType: PublishMessageStorageType.memory,
            messageType: WCMBridgeMessageType.wallet);
  factory WCMEventWalletUnlocked.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmEventWalletUnlocked,
        cborBytes: bytes,
        cborObject: object);
    return WCMEventWalletUnlocked(
        WCMEventWalletUpdated.deserialize(object: values.objectAt(0)));
  }
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmEventWalletUnlocked;

  @override
  List<CborObject?> get serializationItems => [update.toCbor()];

  @override
  PublishMessageStorageType get storageType => PublishMessageStorageType.memory;
}

sealed class WCMEventNetwork extends WCMActionEvent {
  final int? network;
  const WCMEventNetwork(
      {required super.mode,
      required super.storageType,
      required this.network,
      required super.messageType});
}

sealed class WCMEventNetworkClient extends WCMEventNetwork {
  const WCMEventNetworkClient(
      {super.mode = PublishMessageMode.publishAndResult,
      super.storageType = PublishMessageStorageType.memory,
      required super.network})
      : super(messageType: WCMBridgeMessageType.client);
}

sealed class WCMEventNetworkClientStream extends WCMEventNetworkClient {
  final String id;
  const WCMEventNetworkClientStream(
      {required this.id,
      super.mode = PublishMessageMode.publish,
      super.storageType = PublishMessageStorageType.memory,
      required super.network});
}

class WCMEventNetworkClientProviderChanged extends WCMEventNetworkClient {
  final NetworkApiProvider provider;
  WCMEventNetworkClientProviderChanged(
      {required this.provider, super.mode, super.storageType, required super.network});
  factory WCMEventNetworkClientProviderChanged.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmEventNetworkClientProviderChanged,
        cborBytes: bytes,
        cborObject: object);
    return WCMEventNetworkClientProviderChanged(
        mode: PublishMessageMode.fromValue(values.rawValueAt(0)),
        storageType: PublishMessageStorageType.fromValue(values.rawValueAt(1)),
        network: values.rawValueAt(2),
        provider: NetworkApiProvider.deserialize(object: values.objectAt(3)));
  }
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmEventNetworkClientProviderChanged;

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        storageType.value.toCbor(),
        network?.toCbor(),
        provider.toCbor()
      ];
}

class WCMEventNetworkClientStreamData extends WCMEventNetworkClientStream {
  final List<int> data;
  WCMEventNetworkClientStreamData(
      {required List<int> data,
      required super.id,
      super.mode,
      super.storageType,
      required super.network})
      : data = data.asImmutableBytes;
  factory WCMEventNetworkClientStreamData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmEventNetworkClientStreamData,
        cborBytes: bytes,
        cborObject: object);
    return WCMEventNetworkClientStreamData(
        mode: PublishMessageMode.fromValue(values.rawValueAt(0)),
        storageType: PublishMessageStorageType.fromValue(values.rawValueAt(1)),
        network: values.rawValueAt(2),
        data: values.rawValueAt(3),
        id: values.rawValueAt(4));
  }
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmEventNetworkClientStreamData;

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        storageType.value.toCbor(),
        network?.toCbor(),
        CborBytesValue(data),
        id.toCbor()
      ];
}

enum WCMEventNetworkClientStreamStatusType {
  error(0),
  disconnect(1),
  complete(2);

  final int value;
  const WCMEventNetworkClientStreamStatusType(this.value);
  bool get isError => this == error;
  static WCMEventNetworkClientStreamStatusType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () =>
          throw AppInternalError.internalError("WCMEventNetworkClientStreamStatusType"),
    );
  }
}

class WCMEventNetworkClientStreamStatus extends WCMEventNetworkClientStream {
  final WCMEventNetworkClientStreamStatusType status;
  final IException? error;
  WCMEventNetworkClientStreamStatus(
      {super.mode,
      super.storageType,
      required super.network,
      required this.status,
      required super.id,
      this.error});
  factory WCMEventNetworkClientStreamStatus.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmEventNetworkClientStreamStatus,
        cborBytes: bytes,
        cborObject: object);
    return WCMEventNetworkClientStreamStatus(
        mode: PublishMessageMode.fromValue(values.rawValueAt(0)),
        storageType: PublishMessageStorageType.fromValue(values.rawValueAt(1)),
        network: values.rawValueAt(2),
        status: WCMEventNetworkClientStreamStatusType.fromValue(values.rawValueAt(3)),
        id: values.rawValueAt(4),
        error: values.maybeObjectAt<IException, CborTagValue>(
            5, (e) => IExceptionUtils.deserialize(object: e)));
  }
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmEventNetworkClientStreamStatus;

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        storageType.value.toCbor(),
        network?.toCbor(),
        status.value.toCbor(),
        id.toCbor(),
        error?.toCbor()
      ];
}
