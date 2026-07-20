import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class NetworkClientError extends BaseAppException {
  const NetworkClientError(super.message);
  factory NetworkClientError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.networkClientError,
    );
    return NetworkClientError(values.rawValueAt(0));
  }

  @override
  bool get localizedMessage => false;

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.networkClientError;

  static const NetworkClientError protocolServiceChanged =
      NetworkClientError("service_provider_changed");
  static const NetworkClientError invalidServiceRequest =
      NetworkClientError("invalid_service_request");

  static const NetworkClientError noActiveServiceProvider =
      NetworkClientError('no_active_service_provider');
}
