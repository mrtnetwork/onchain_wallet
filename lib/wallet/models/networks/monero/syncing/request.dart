import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';

sealed class MoneroBlockTrackingRequest with AppSerialization, Equality {
  final BlockTrackingOffset offset;
  int get currentHeight => offset.currentHeight;
  int get startHeight => offset.startHeight;
  int get endHeight => offset.endHeight;
  int? get requestId;
  MoneroBlockTrackingRequest({required this.offset});
}

class MoneroBlockTrackingRequestOffset extends MoneroBlockTrackingRequest {
  @override
  final int? requestId;
  @override
  int get currentHeight => offset.currentHeight;
  @override
  int get startHeight => offset.startHeight;
  @override
  int get endHeight => offset.endHeight;
  final MoneroNetwork network;
  final List<TxKeyImage> keyImages;
  MoneroBlockTrackingRequestOffset(
      {required super.offset,
      required this.requestId,
      required this.network,
      required List<TxKeyImage> keyImages})
      : keyImages = keyImages.immutable;
  factory MoneroBlockTrackingRequestOffset.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return MoneroBlockTrackingRequestOffset(
        offset: BlockTrackingOffset.deserialize(object: values.objectAt(0)),
        requestId: values.rawValueAt(1),
        network: MoneroNetwork.fromValue(values.rawValueAt(2)),
        keyImages: values
            .listAt<CborObject>(3)
            .map((e) => TxKeyImage.deserialize(obj: e))
            .toList());
  }

  @override
  List get variables => [offset, requestId];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        offset.toCbor(),
        requestId?.toCbor(),
        network.value.toCbor(),
        AppSerialization.listFromObjects(keyImages.map((e) => e.toCbor()).toList())
      ];

  @override
  String toString() {
    return "id: ${requestId ?? 'default'}, $offset";
  }
}
