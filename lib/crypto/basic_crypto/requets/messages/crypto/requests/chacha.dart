import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/chacha.dart';

class CryptoRequestEncryptChacha extends CryptoRequest<CryptoEncryptChachaResponse> {
  final List<int> message;
  final List<int> key;
  final int nonceLength;
  final List<int>? nonce;
  CryptoRequestEncryptChacha._(
      {required this.message,
      required this.key,
      required this.nonce,
      required this.nonceLength});

  factory CryptoRequestEncryptChacha(
      {required List<int> message,
      required List<int> key,
      List<int>? nonce,
      int nonceLength = 12}) {
    return CryptoRequestEncryptChacha._(
      message: message.asImmutableBytes,
      key: key.asImmutableBytes,
      nonce: nonce?.asImmutableBytes,
      nonceLength: nonceLength,
    );
  }

  factory CryptoRequestEncryptChacha.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.encryptChacha.tag);
    return CryptoRequestEncryptChacha(
      message: values.rawValueAt(0),
      key: values.rawValueAt(1),
      nonce: values.rawValueAt(2),
      nonceLength: values.rawValueAt(3),
    );
  }

  static (List<int>, List<int>) encrypt(
      {required List<int> key,
      required int nonceLength,
      required List<int> message,
      List<int>? nonce}) {
    final chacha = ChaCha20Poly1305(key);
    nonce ??= QuickCrypto.generateRandom(nonceLength);
    final encrypt = chacha.encrypt(nonce, message);
    return (encrypt, nonce);
  }

  @override
  CryptoEncryptChachaResponse parsResult(MessageArgsComplete result) {
    return CryptoEncryptChachaResponse.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.encryptChacha;

  @override
  Future<CryptoEncryptChachaResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final data =
        encrypt(key: key, nonceLength: nonceLength, message: message, nonce: nonce);
    return CryptoEncryptChachaResponse(encrypted: data.$1, nonce: data.$2);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(message),
        CborBytesValue(key),
        nonce?.toCborBytes(),
        nonceLength.toCbor()
      ];
}

class CryptoRequestDecryptChacha extends CryptoRequest<CryptoDecryptChachaResponse> {
  final List<int> message;
  final List<int> key;
  final List<int> nonce;
  CryptoRequestDecryptChacha({
    required List<int> message,
    required List<int> key,
    required List<int> nonce,
  })  : message = message.asImmutableBytes,
        key = key.asImmutableBytes,
        nonce = nonce.asImmutableBytes;
  CryptoRequestDecryptChacha.fromHex({
    required String message,
    required String key,
    required String nonce,
  })  : message = BytesUtils.fromHexString(message).immutable,
        key = BytesUtils.fromHexString(key).immutable,
        nonce = BytesUtils.fromHexString(nonce).immutable;

  factory CryptoRequestDecryptChacha.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.decryptChacha.tag);
    return CryptoRequestDecryptChacha(
        message: values.rawValueAt(0),
        key: values.rawValueAt(1),
        nonce: values.rawValueAt(2));
  }

  static List<int> decrypt(
      {required List<int> key, required List<int> nonce, required List<int> message}) {
    final chacha = ChaCha20Poly1305(key);
    final decrypted = chacha.decrypt(nonce, message);
    if (decrypted == null) {
      throw WalletExceptionConst.decryptionFailed;
    }
    return decrypted;
  }

  @override
  CryptoDecryptChachaResponse parsResult(MessageArgsComplete result) {
    return CryptoDecryptChachaResponse.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.decryptChacha;

  @override
  Future<CryptoDecryptChachaResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final decryptData = decrypt(key: key, nonce: nonce, message: message);
    return CryptoDecryptChachaResponse(decryptData);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(message), CborBytesValue(key), CborBytesValue(nonce)];
}
