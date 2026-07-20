import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/constant/constant.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleUtils {
  static List<XRPLMemo> toXrplMemos(List<XRPLMemo> memos) {
    final List<XRPLMemo> hexMemoms = [];
    for (final i in memos) {
      String? memoData;
      String? memoFormat;
      String? memoType;
      if (i.memoData != null) {
        memoData = QuickBytesUtils.ensureIsHex(i.memoData!);
      }
      if (i.memoFormat != null) {
        memoFormat = QuickBytesUtils.ensureIsHex(i.memoFormat!);
      }
      if (i.memoType != null) {
        memoType = QuickBytesUtils.ensureIsHex(i.memoType!);
      }
      hexMemoms
          .add(XRPLMemo(memoData: memoData, memoFormat: memoFormat, memoType: memoType));
    }
    return hexMemoms;
  }

  static BigRational? validateQuilityInOutTrustSet(BigRational? val) {
    if (val == null ||
        val.isNegative ||
        val.isDecimal ||
        val > RippleConst.max32UnsignedRational) {
      return null;
    }
    return val;
  }

  static BigRational? validateTrustSetLimit(BigRational? val) {
    if (val == null || val.precision > RippleConst.maxIouPrecision) {
      return null;
    }
    return val;
  }

  static String? validateCurrencyCode(String? val) {
    if (val == null || !RippleConst.currencyCodeRegex.hasMatch(val)) {
      return null;
    }
    return val;
  }

  static BigRational? validateAccoutSetTransferRate(BigRational? val) {
    if (val == null) return null;
    if (val == BigRational.zero) return val;
    if (val.isNegative || val.isDecimal) return null;
    if (val >= RippleConst.rippleAccountTransferRateMin &&
        val <= RippleConst.rippleAccountTransferRateMax) {
      return val;
    }
    return null;
  }

  static BigRational? validateAccoutSetTickSize(BigRational? val) {
    if (val == null) return null;
    if (val == BigRational.zero) return val;
    if (val.isNegative || val.isDecimal) return null;
    if (val >= RippleConst.rippleAccountSetTickSizeMin &&
        val <= RippleConst.rippleAccountSetTickSizeMax) {
      return val;
    }
    return null;
  }

  static String? validateRipplePublicKey(String? val) {
    if (val == null) return null;
    try {
      final keyBytes = BytesUtils.fromHexString(val);
      if (keyBytes.length != RippleKeyConst.publicKeyLength) return null;
      if (Secp256k1PublicKey.isValidBytes(keyBytes)) {
        return val;
      } else if (Ed25519PublicKey.isValidBytes(keyBytes)) {
        return val;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static BigInt calculateFee(BigInt netFee, SubmittableTransactionType transactionType,
      {String? fulfillment, int multiSigners = 0}) {
    BigInt baseFee = netFee;

    /// Check if the transaction type is ESCROW_FINISH.
    if (transactionType == SubmittableTransactionType.escrowFinish) {
      /// Cast the transaction as an EscrowFinish to access specific properties.

      if (fulfillment != null) {
        /// Calculate the length of the fulfillment in bytes.
        final fulfillmentBytesLength = fulfillment.codeUnits.length;

        /// Adjust the base fee based on the fulfillment length.
        baseFee = (netFee * BigInt.from((33 + (fulfillmentBytesLength / 16)).ceil()));
      }
    }

    // /// Adjust the base fee if the transaction involves multi-signers.
    if (multiSigners > 0) {
      baseFee += netFee * BigInt.from((1 + multiSigners));
    }
    return baseFee;
  }

  static String? ensureIsRippleAddress(String? address) {
    try {
      if (address == null) return null;
      XRPAddressUtils.ensureClassicAddress(address);
      return address;
    } catch (e) {
      return null;
    }
  }

  static String ensureClassicAddress(String address) {
    return XRPAddressUtils.ensureClassicAddress(address);
  }

  static XRPKeyAlgorithm? findXRPPrivateKeyAlgorithm(String keyHex) {
    try {
      return XRPPrivateKey.findAlgorithm(BytesUtils.fromHexString(keyHex));
    } catch (e) {
      return null;
    }
  }

  static XRPKeyAlgorithm? findXrpSeedAlgorithm(String seed) {
    try {
      return XrpSeedUtils.decodeSeed(seed).$2;
    } catch (e) {
      return null;
    }
  }

  static XRPPrivateKey seedToPrivateKey(String seed) {
    try {
      return XRPPrivateKey.fromSeed(seed);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static XRPPrivateKey entropyToPrivateKey(String entropy, XRPKeyAlgorithm algorithm) {
    try {
      return XRPPrivateKey.fromEntropy(entropy, algorithm: algorithm);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static List<int> privateKeyToKeypairBytes(
      {required List<int> privateKey, required CryptoCoins coin}) {
    try {
      final ripplePrivateKey = XRPPrivateKey.fromBytes(privateKey,
          algorithm: coin.conf.type == EllipticCurveTypes.ed25519
              ? XRPKeyAlgorithm.ed25519
              : XRPKeyAlgorithm.secp256k1);

      return ripplePrivateKey.toBytes();
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }

  static XRPBaseAddress publicKeyToRippleAddress(List<int> keyBytes,
      {XRPKeyAlgorithm? algorithm, int? tag, bool? isTenstNet}) {
    final publicKey = XRPPublicKey.fromBytes(keyBytes, algorithm: algorithm);
    if (tag != null && isTenstNet != null) {
      return publicKey.toXAddress(isTenstNet ? ChainType.testnet : ChainType.mainnet);
    }
    return publicKey.toClassicAddress();
  }

  static List<int> toXrplPublicKeyBytes(
    List<int> keyBytes,
    XRPKeyAlgorithm algorithm,
  ) {
    if (algorithm == XRPKeyAlgorithm.ed25519) {
      final withPrefixLength =
          Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.xrpPubKeyPrefix.length;
      if (keyBytes.length == withPrefixLength) {
        return [...Ed25519KeysConst.xrpPubKeyPrefix, ...keyBytes.sublist(1)];
      }
      if (keyBytes.length != Ed25519KeysConst.pubKeyByteLen) {
        throw AppCryptoExceptionConst.invalidEncodedKeyData;
      }
      return [
        ...Ed25519KeysConst.xrpPubKeyPrefix,
        ...keyBytes,
      ];
    }
    if (keyBytes.length != EcdsaKeysConst.pubKeyCompressedByteLen &&
        keyBytes.length != EcdsaKeysConst.pubKeyUncompressedByteLen) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
    return keyBytes;
  }

  static XRPBaseAddress strPublicKeyToRippleAddress(String keyHex) {
    final publicKey = XRPPublicKey.fromHex(keyHex);
    return publicKey.toClassicAddress();
  }

  static String toRipplePublicKey(String bip32PublicKey) {
    final keyBytes = XRPPublicKey.fromHex(bip32PublicKey);
    return keyBytes.toHex();
  }

  static String toRipplePrivateKey(String bip32PrivateKey, EllipticCurveTypes keyType) {
    final algorithm = XRPKeyAlgorithm.values.firstWhere((e) => e.curveType == keyType);
    final keyBytes = XRPPrivateKey.fromHex(bip32PrivateKey, algorithm: algorithm);
    return keyBytes.toHex();
  }
}
