import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class Web3EncryptedMessage with AppSerialization {
  final List<int> message;
  final List<int> nonce;

  Web3EncryptedMessage({
    required this.message,
    required List<int> nonce,
  }) : nonce = nonce.asImmutableBytes;

  factory Web3EncryptedMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3EncryptedMessage);

    return Web3EncryptedMessage(
        message: values.rawValueAt(0), nonce: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3EncryptedMessage;
  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(message), CborBytesValue(nonce)];
}
