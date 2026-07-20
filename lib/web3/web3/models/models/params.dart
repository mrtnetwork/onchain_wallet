import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

/// TODO
/// check model
class ExtentionRequestEvent with AppSerialization {
  final String id;
  final List<int> data;
  final String requestId;
  final String url;
  final int tabId;
  ExtentionRequestEvent({
    required this.id,
    required List<int> data,
    required this.requestId,
    required this.url,
    required this.tabId,
  }) : data = List<int>.unmodifiable(data);
  factory ExtentionRequestEvent.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return ExtentionRequestEvent(
        id: values.rawValueAt(0),
        data: values.rawValueAt(1),
        requestId: values.rawValueAt(2),
        url: values.rawValueAt(3),
        tabId: values.rawValueAt(4));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        CborBytesValue(data),
        requestId.toCbor(),
        url.toCbor(),
        tabId.toCbor()
      ];
}
