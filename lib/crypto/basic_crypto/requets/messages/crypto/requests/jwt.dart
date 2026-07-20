import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

final class CryptoRequestGenerateJwt extends CryptoRequest<AppSerializationString> {
  final String aud;
  final DateTime expiry;
  CryptoRequestGenerateJwt({required this.aud, DateTime? expiry})
      : expiry = expiry ?? DateTime.now().add(const Duration(days: 1));

  factory CryptoRequestGenerateJwt.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: CryptoRequestMethod.jwt.tag);
    return CryptoRequestGenerateJwt(
        aud: values.rawValueAt(0), expiry: values.rawValueAt(1));
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.jwt;

  @override
  AppSerializationString parsResult(MessageArgsComplete result) {
    return AppSerializationString.deserialize(obj: result.result);
  }

  static String _ed25519PublicKeyToIssuer(Ed25519PublicKey key) {
    // Multicodec prefix for Ed25519 public key: 0xED01
    final prefix = [0xED, 0x01];

    // Combine prefix + public key
    final data = [...prefix, ...key.compressed.sublist(1)];

    // Base58btc encode (multibase with prefix "z")
    final base58Encoded = Base58Encoder.encode(data);

    // Return did:key:...
    return 'did:key:z$base58Encoded';
  }

  @override
  Future<AppSerializationString> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final key = Ed25519PrivateKey.fromBytes(QuickCrypto.generateRandom());
    final ait = DateTime.now().subtract(const Duration(minutes: 1));
    // final exp = DateTime.now().add(const Duration(days: 1));
    final jwt = Jwt(
      header: JwtHeader(alg: JwtSupportedAlgorithm.eddsa),
      payload: JwtPayload(
          iss: _ed25519PublicKeyToIssuer(key.publicKey),
          aud: [aud],
          sub: BytesUtils.toHexString(QuickCrypto.generateRandom()),
          iat: DateTimeUtils.secondsSinceEpoch(ait),
          exp: DateTimeUtils.secondsSinceEpoch(expiry)),
    );
    return AppSerializationString(jwt.sign(key: key.raw));
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [aud.toCbor(), expiry.toCbor()];
}
