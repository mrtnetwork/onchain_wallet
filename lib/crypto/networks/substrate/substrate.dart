import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateUtils {
  static List<int> callHash(List<int> call) {
    return QuickCrypto.blake2b256Hash(call);
  }

  static BigInt multisigDepositAmount(
      {required BigInt baseDeposit,
      required BigInt depositFactor,
      required int signers}) {
    final totalSigners = BigInt.from(signers);
    return baseDeposit + (depositFactor * totalSigners);
  }

  static BaseSubstrateAddress toAddress(
      {required List<int> publicKey,
      required int ss58Format,
      required EllipticCurveTypes curve,
      bool isEthereum = false}) {
    if (isEthereum) {
      if (curve != EllipticCurveTypes.secp256k1) {
        throw AppInternalError.internalError("SubstrateUtils.toAddress");
      }
      return SubstrateEthereumAddress.fromPublicKey(publicKey);
    }
    switch (curve) {
      case EllipticCurveTypes.ed25519:
        return SubstrateAddress.fromEddsa(publicKey, ss58Format: ss58Format);
      case EllipticCurveTypes.secp256k1:
        return SubstrateAddress.fromEcdsa(publicKey, ss58Format: ss58Format);
      case EllipticCurveTypes.sr25519:
        return SubstrateAddress.fromSr25519(publicKey, ss58Format: ss58Format);
      default:
        throw AppInternalError.internalError("SubstrateUtils.toAddress");
    }
  }

  static List<int> createPayload(List<int> bytes) {
    if (bytes.length > TransactionPalyloadConst.requiredHashDigestLength) {
      return QuickCrypto.blake2b256Hash(bytes);
    } else {
      return bytes;
    }
  }

  static List<int> createFakeSignature(EllipticCurveTypes algorithm) {
    return switch (algorithm) {
      EllipticCurveTypes.secp256k1 =>
        List<int>.filled(SubstrateConstant.ecdsaSignatureLength, 0),
      _ => List<int>.filled(SubstrateConstant.signatureLength, 0)
    };
  }
}
