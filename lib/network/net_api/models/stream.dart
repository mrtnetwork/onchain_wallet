import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

class StreamProgress with AppSerialization {
  final String identifier;
  final int loaded;
  final int? total;
  const StreamProgress(
      {required this.loaded, required this.total, required this.identifier})
      : super();
  bool get isValid {
    final total = this.total;
    return total != null && loaded <= total;
  }

  factory StreamProgress.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.iprogress,
        cborBytes: bytes,
        cborObject: object);
    return StreamProgress(
      identifier: values.rawValueAt(0),
      loaded: values.rawValueAt(1),
      total: values.rawValueAt(2),
    );
  }
  @override
  List<CborObject<Object?>?> get serializationItems =>
      [identifier.toCbor(), loaded.toCbor(), total?.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.iprogress;
}
