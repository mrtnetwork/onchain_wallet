import 'dart:isolate';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';

abstract class IIsolateCryptoMessageNative extends IIsolateCryptoMessage {
  IIsolateCryptoMessageNative({required super.type, required super.id});
}

final class IsolateCryptoMessageNative extends IIsolateCryptoMessageNative {
  final TransferableTypedData message;
  final IsolateCryptoEncryptedMessageNative? encryptedPart;

  IsolateCryptoMessageNative({
    required this.message,
    required super.id,
    this.encryptedPart,
  }) : super(type: BasicCryptoMessageType.nonEncrypted);

  @override
  List<int> messageBytes() {
    return message.materialize().asUint8List();
  }

  @override
  IIsolateCryptoEncryptedMessage? encryptPart() {
    return encryptedPart;
  }
}

final class IsolateCryptoEncryptedMessageNative extends IIsolateCryptoEncryptedMessage
    implements IIsolateCryptoMessageNative {
  final TransferableTypedData nonce;
  final TransferableTypedData message;

  IsolateCryptoEncryptedMessageNative({
    required this.message,
    required this.nonce,
    required super.id,
  }) : super();

  @override
  List<int> messageBytes() {
    return message.materialize().asUint8List();
  }

  @override
  List<int> nonceBytes() {
    return nonce.materialize().asUint8List();
  }
}
