import 'package:blockchain_utils/blockchain_utils.dart';

final class CryptoPersonalSignResponse {
  final String signatureHex;
  final List<int> signature;
  CryptoPersonalSignResponse({
    required this.signatureHex,
    required List<int> signature,
  }) : signature = signature.asImmutableBytes;
}

final class CryptoBitcoinPersonalSignResponse {
  final String signatureBase64;
  final List<int> digest;
  CryptoBitcoinPersonalSignResponse({
    required this.signatureBase64,
    required List<int> digest,
  }) : digest = digest.asImmutableBytes;
}
