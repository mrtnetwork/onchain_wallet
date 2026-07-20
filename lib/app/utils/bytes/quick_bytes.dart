import 'dart:typed_data';

import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';

class QuickBytesUtils {
  static String ensureIsHex(String data) {
    if (StringUtils.isHexBytes(data)) {
      return data;
    }
    return BytesUtils.toHexString(StringUtils.encode(data));
  }

  static String stringToHexWithLength(String data, int strWidth) {
    assert(strWidth.isEven, "invalid hex length");
    final toHex = BytesUtils.toHexString(StringUtils.toBytes(data));
    final hex = toHex.padLeft(strWidth, "0");
    return hex;
  }

  static String tryAsUtf8String(String hex) {
    if (!StringUtils.isHexBytes(hex)) {
      return hex;
    }
    final bytes = BytesUtils.fromHexString(hex);
    final toString = StringUtils.tryDecode(bytes);
    return toString ?? hex;
  }

  static String? ensureIsHash256(String? hex) {
    if (hex != null &&
        StringUtils.isHexBytes(hex, lengthInBytes: QuickCrypto.sha256DigestSize)) {
      return hex;
    }
    return null;
  }

  static double bytesToMb(int length) {
    return length / (1024 * 1024);
  }

  static Uint8List asUint8List(List<int> bytes) {
    return switch (bytes) {
      Uint8List bytes => bytes,
      List<int> bytes => Uint8List.fromList(bytes)
    };
  }
}
