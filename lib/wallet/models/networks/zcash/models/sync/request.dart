import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:zcash_dart/zcash.dart';

sealed class ZcashBlockTrackingRequest with AppSerialization, Equality {
  final BlockTrackingOffset offset;
  final List<Nullifier> utxoNullifiers;
  int get currentHeight => offset.currentHeight;
  int get startHeight => offset.startHeight;
  int get endHeight => offset.endHeight;
  int? get requestId;
  ZcashBlockTrackingRequest(
      {required this.offset, required List<Nullifier> utxoNullifiers})
      : utxoNullifiers = utxoNullifiers.immutable;
}

class ZcashBlockTrackingRequestOffset extends ZcashBlockTrackingRequest {
  @override
  final int? requestId;
  @override
  int get currentHeight => offset.currentHeight;
  @override
  int get startHeight => offset.startHeight;
  @override
  int get endHeight => offset.endHeight;
  ZcashBlockTrackingRequestOffset(
      {required super.offset, required this.requestId, required super.utxoNullifiers});
  factory ZcashBlockTrackingRequestOffset.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return ZcashBlockTrackingRequestOffset(
      offset: BlockTrackingOffset.deserialize(object: values.objectAt(0)),
      requestId: values.rawValueAt(1),
      utxoNullifiers: values
          .listAt<CborTagValue>(2)
          .map((e) => Nullifier.deserialize(obj: e))
          .toList(),
    );
  }

  @override
  List get variables => [offset, requestId, utxoNullifiers];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        offset.toCbor(),
        requestId?.toCbor(),
        AppSerialization.listFromObjects(utxoNullifiers.map((e) => e.toCbor()).toList()),
      ];

  @override
  String toString() {
    return "id: ${requestId ?? 'default'}, $offset";
  }
}

class ZcashBlockTrackingRequestNullifier extends ZcashBlockTrackingRequest {
  @override
  final int requestId;
  final ZcashNetwork network;

  ZcashBlockTrackingRequestNullifier(
      {required super.offset,
      required this.requestId,
      required super.utxoNullifiers,
      required this.network});
  factory ZcashBlockTrackingRequestNullifier.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return ZcashBlockTrackingRequestNullifier(
        offset: BlockTrackingOffset.deserialize(object: values.objectAt(0)),
        requestId: values.rawValueAt(1),
        utxoNullifiers: values
            .listAt<CborTagValue>(2)
            .map((e) => Nullifier.deserialize(obj: e))
            .toList(),
        network: ZcashNetwork.fromValue(values.rawValueAt(3)));
  }

  @override
  List get variables => [offset, requestId, utxoNullifiers, network];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        offset.toCbor(),
        requestId.toCbor(),
        AppSerialization.listFromObjects(utxoNullifiers.map((e) => e.toCbor()).toList()),
        network.value.toCbor()
      ];

  @override
  String toString() {
    return "id: $requestId, $offset";
  }
}
