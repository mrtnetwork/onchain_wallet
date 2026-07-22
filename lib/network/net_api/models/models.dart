import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization/tags.dart';
import 'package:on_chain_wallet/network/net_api/models/stream.dart';

enum HTTPClientType {
  cached,
  single,
  perRequest;
}

typedef CbOnHttpStreamProgress = void Function(StreamProgress progress);

class ProviderRetryLogic with AppSerialization {
  final List<int> statusCodes;
  final Duration timeout;
  const ProviderRetryLogic({required this.statusCodes, required this.timeout});
  factory ProviderRetryLogic.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.providerRetryLogic,
        cborBytes: bytes,
        cborObject: object);
    return ProviderRetryLogic(
      statusCodes: values.listAt<CborIntValue>(0).map((e) => e.value).toList(),
      timeout: Duration(milliseconds: values.rawValueAt(1)),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.providerRetryLogic;

  @override
  List<CborObject<Object?>?> get serializationItems => [
        AppSerialization.listFromObjects(statusCodes.map((e) => e.toCbor()).toList()),
        timeout.inMilliseconds.toCbor()
      ];
}
