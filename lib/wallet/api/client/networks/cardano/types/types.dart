import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain/ada/src/models/transaction/input/input.dart';
import 'package:on_chain/ada/src/models/transaction/output/models/transaction_output.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class ADATransactionWithTxId with AppSerialization {
  final TransactionInput txInput;
  final DateTime blockTime;
  final TransactionOutput output;
  const ADATransactionWithTxId(
      {required this.txInput, required this.blockTime, required this.output});
  factory ADATransactionWithTxId.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ADATransactionWithTxId(
        txInput: TransactionInput.deserialize(values.objectAt(0)),
        blockTime: values.rawValueAt(1),
        output: TransactionOutput.deserialize(values.objectAt(2)));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [txInput.toCbor(), blockTime.toCbor(), output.toCbor()];
}
