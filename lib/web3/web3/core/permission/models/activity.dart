import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class Web3AccountAcitvity with AppSerialization, Equality {
  final String requestId;
  final String method;
  final DateTime date;
  final String? path;
  final String? address;
  final int? id;
  Web3AccountAcitvity({
    required this.method,
    required this.requestId,
    DateTime? date,
    required this.path,
    this.id,
    this.address,
  }) : date = date ?? DateTime.now();
  factory Web3AccountAcitvity.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.permissionActivityTag);
    return Web3AccountAcitvity(
        method: values.rawValueAt(0),
        requestId: values.rawValueAt(1),
        date: values.rawValueAt(2),
        path: values.rawValueAt(3),
        address: values.rawValueAt(4),
        id: values.rawValueAt(5));
  }

  @override
  List get variables => [method, requestId, date, path, address, id];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.permissionActivityTag;

  @override
  List<CborObject?> get serializationItems => [
        method.toCbor(),
        requestId.toCbor(),
        CborEpochFloatValue(date),
        path?.toCbor(),
        address?.toCbor(),
        id?.toCbor()
      ];
}
