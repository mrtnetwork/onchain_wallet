import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class MoneroRingOutput with AppSerialization {
  final List<BigInt> orderedIndexes;
  final List<BigInt> indexes;
  MoneroRingOutput({required List<BigInt> orderedIndexes, required List<BigInt> indexes})
      : orderedIndexes = orderedIndexes.immutable,
        indexes = indexes.immutable;
  factory MoneroRingOutput.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.monerogenerateRingOutput);
    return MoneroRingOutput(
        orderedIndexes: values.listAt<CborBigIntValue>(0).map((e) => e.value).toList(),
        indexes: values.listAt<CborBigIntValue>(1).map((e) => e.value).toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.monerogenerateRingOutput;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(
            orderedIndexes.map((e) => CborBigIntValue(e)).toList()),
        AppSerialization.listFromObjects(indexes.map((e) => CborBigIntValue(e)).toList()),
      ];
}
