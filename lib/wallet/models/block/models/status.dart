import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

sealed class BlockSyncStatus with AppSerialization {
  const BlockSyncStatus();
  factory BlockSyncStatus.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      AppSerializationIdentifier.zcashSyncStatusOK,
      AppSerializationIdentifier.zcashSyncStatusErr,
      AppSerializationIdentifier.zcashSyncStatusPending
    ], cborBytes: bytes, cborObject: object);
    return switch (decode.identifier) {
      AppSerializationIdentifier.zcashSyncStatusOK => BlockSyncStatusSynced(),
      AppSerializationIdentifier.zcashSyncStatusPending => BlockSyncStatusPending(),
      _ => BlockSyncStatusError.deserialize(object: decode.tag)
    };
  }

  bool get synced => false;
  bool get isErr => false;

  T cast<T extends BlockSyncStatus>() {
    if (this is T) return this as T;
    throw AppInternalError.internalError("BlockSyncStatus.cast");
  }
}

class BlockSyncStatusSynced extends BlockSyncStatus {
  const BlockSyncStatusSynced();
  @override
  bool get synced => true;
  factory BlockSyncStatusSynced.deserialize({List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.zcashSyncStatusOK,
        cborBytes: bytes,
        cborObject: object);
    return BlockSyncStatusSynced();
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncStatusOK;

  @override
  List<CborObject?> get serializationItems => [];

  @override
  String toString() {
    return "BlockSyncStatusSynced()";
  }
}

class BlockSyncStatusError extends BlockSyncStatus {
  final IException error;
  const BlockSyncStatusError(this.error);

  factory BlockSyncStatusError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.zcashSyncStatusErr,
        cborBytes: bytes,
        cborObject: object);
    return BlockSyncStatusError(IExceptionUtils.deserialize(object: values.objectAt(0)));
  }
  @override
  bool get isErr => true;
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncStatusErr;

  @override
  List<CborObject?> get serializationItems => [error.toCbor()];

  @override
  String toString() {
    return "BlockSyncStatusError(${error.message})";
  }
}

class BlockSyncStatusPending extends BlockSyncStatus {
  const BlockSyncStatusPending();
  factory BlockSyncStatusPending.deserialize({List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.zcashSyncStatusPending,
        cborBytes: bytes,
        cborObject: object);
    return BlockSyncStatusPending();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashSyncStatusPending;

  @override
  List<CborObject?> get serializationItems => [];

  @override
  String toString() {
    return "BlockSyncStatusPending()";
  }
}
