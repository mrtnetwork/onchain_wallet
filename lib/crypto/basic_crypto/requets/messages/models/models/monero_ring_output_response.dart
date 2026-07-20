import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

class MoneroGenerateRingOutResponse with AppSerialization {
  final List<SpendablePayment<MoneroLockedPayment>> payments;
  const MoneroGenerateRingOutResponse(this.payments);
  factory MoneroGenerateRingOutResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return MoneroGenerateRingOutResponse(values
        .listAt<CborBytesValue>(0)
        .map((e) => SpendablePayment<MoneroLockedPayment>.deserialize(e.value))
        .toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject<Object?>?> get serializationItems => [
        AppSerialization.listFromObjects(
            payments.map((e) => e.serialize().toCborBytes()).toList())
      ];
}
