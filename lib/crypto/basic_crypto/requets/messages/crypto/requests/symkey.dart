import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/wc_sym_key.dart';

final class CryptoRequestGenerateWalletConnectSymKeyInfo
    extends CryptoRequest<GeneratedSharedKey> {
  final List<int> publicKey;
  final List<int> privateKey;
  CryptoRequestGenerateWalletConnectSymKeyInfo(
      {required List<int> publicKey, required List<int> privateKey})
      : publicKey = publicKey.asImmutableBytes,
        privateKey = privateKey.asImmutableBytes;
  factory CryptoRequestGenerateWalletConnectSymKeyInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: CryptoRequestMethod.symkey.tag);
    return CryptoRequestGenerateWalletConnectSymKeyInfo(
        publicKey: values.rawValueAt(0), privateKey: values.rawValueAt(1));
  }

  @override
  GeneratedSharedKey parsResult(MessageArgsComplete result) {
    return GeneratedSharedKey.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.symkey;

  @override
  Future<GeneratedSharedKey> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final kp = X25519Keypair.generate(seed: privateKey);
    final sharedKey1 = X25519.scalarMult(kp.privateKey, publicKey);
    final hdkf = HKDF(
        ikm: sharedKey1, hash: () => SHA256(), length: Ed25519KeysConst.privKeyByteLen);
    final symKey = hdkf.derive().asImmutableBytes;
    return GeneratedSharedKey(
        topic: QuickCrypto.sha256Hash(symKey), publicKey: kp.publicKey, symkey: symKey);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [publicKey.toCborBytes(), privateKey.toCborBytes()];
}

final class CryptoRequestGenerateX25519Key extends CryptoRequest<GeneratedX25519Key> {
  final List<int>? seed;
  CryptoRequestGenerateX25519Key({this.seed});

  factory CryptoRequestGenerateX25519Key.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: CryptoRequestMethod.x25519.tag);
    return CryptoRequestGenerateX25519Key(seed: values.rawValueAt(0));
  }

  @override
  GeneratedX25519Key parsResult(MessageArgsComplete result) {
    return GeneratedX25519Key.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.x25519;

  @override
  Future<GeneratedX25519Key> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final kp = X25519Keypair.generate(
        seed:
            seed == null ? QuickCrypto.generateRandom() : QuickCrypto.sha256Hash(seed!));
    return GeneratedX25519Key(publicKey: kp.publicKey, privateKey: kp.privateKey);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [seed?.toCborBytes()];
}
