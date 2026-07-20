import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/app/core.dart';

enum SuiSupportKeyScheme {
  ed25519(value: 0, name: "ED25519"),
  secp256k1(value: 1, name: "Secp256k1"),
  secp256r1(value: 2, name: "Secp256r1"),
  multisig(value: 3, name: "Multisig");

  final int value;
  final String name;

  const SuiSupportKeyScheme({required this.value, required this.name});
  static SuiSupportKeyScheme fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("SuiSupportKeyScheme"));
  }

  EllipticCurveTypes get curve {
    return switch (this) {
      SuiSupportKeyScheme.secp256k1 => EllipticCurveTypes.secp256k1,
      SuiSupportKeyScheme.secp256r1 => EllipticCurveTypes.nist256p1Hybrid,
      _ => EllipticCurveTypes.ed25519
    };
  }

  SuiKeyAlgorithm get suiKeyAlgorithm {
    return switch (this) {
      SuiSupportKeyScheme.secp256k1 => SuiKeyAlgorithm.secp256k1,
      SuiSupportKeyScheme.secp256r1 => SuiKeyAlgorithm.secp256r1,
      _ => SuiKeyAlgorithm.ed25519
    };
  }

  static SuiSupportKeyScheme fromCoin(Bip44Coins coin) {
    return switch (coin) {
      Bip44Coins.sui => SuiSupportKeyScheme.ed25519,
      Bip44Coins.suiSecp256k1 => SuiSupportKeyScheme.secp256k1,
      Bip44Coins.suiSecp256r1 => SuiSupportKeyScheme.secp256r1,
      _ => throw AppCryptoExceptionConst.invalidCoin
    };
  }
}
