import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class BridgeException extends BaseAppException {
  final int? code;
  const BridgeException(super.message, {this.code});
  factory BridgeException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.walletConnectError,
    );
    return BridgeException(values.rawValueAt(0), code: values.rawValueAt(1));
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletConnectError;
  @override
  List<dynamic> get variables => [message, code];

  @override
  bool get localizedMessage => true;
}

class BridgeExceptionConst {
  static const BridgeException invalidPairUrl = BridgeException("invalid_pairing_url");
  static const BridgeException unsuportedPairingUrl =
      BridgeException("unsuported_pairing_url");
  static const BridgeException unsuportedMethod = BridgeException("unsuported_wc_method");

  static const BridgeException pairingCanceledByDapp =
      BridgeException("pairing_canceled_by_dapp");
  static const BridgeException requiredNamespacesNotSupported =
      BridgeException("unsuported_required_namespace");
  static const BridgeException internalError = BridgeException("wc_internal_error");
  static const BridgeException publishMessageExpired =
      BridgeException("wc_publis_message_timeout");
  static const BridgeException publishMessageReplaced =
      BridgeException("wc_message_replaced");
  static const BridgeException sessionRequestExpired =
      BridgeException("wc_client_request_timed_out");
  static const BridgeException pairingRequestTimeout =
      BridgeException("pairing_request_timeout");
  static const BridgeException connectionTerminated =
      BridgeException("connection_terminated");
  static const BridgeException badPublishMessageStatus =
      BridgeException("bad_publish_message_status");

  static const BridgeException clientNotFound = BridgeException("client_not_found");

  static const BridgeException tooManyWeb3Clients =
      BridgeException("too_many_web3_client");

  static const BridgeException publishMessageError =
      BridgeException("publish_message_error");
  static const BridgeException requestError = BridgeException("request_error");
  static const BridgeException topicSubscribtionTimeout =
      BridgeException("topic_subscribtion_timeout");
  static const BridgeException pairingDisconnected =
      BridgeException("pairing_disconnected");
}
