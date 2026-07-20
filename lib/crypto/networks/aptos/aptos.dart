import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain/on_chain.dart';

class AptosUtils {
  static AptosAnySignature generateSignature(
      List<int> signature, EllipticCurveTypes scheme) {
    return switch (scheme) {
      EllipticCurveTypes.ed25519 => AptosEd25519AnySignature(signature),
      EllipticCurveTypes.secp256k1 => AptosSecp256k1AnySignature(signature),
      _ => throw AppCryptoException("invalid_signature")
    };
  }

  static List<int> createSignatureBitMap(List<int> indexes) {
    List<int> bitmap = [0, 0, 0, 0];
    const int bit = 128;
    for (final index in indexes) {
      int offset = (index / 8).floor();
      bitmap[offset] |= bit >> index % 8;
    }
    return bitmap;
  }
}
