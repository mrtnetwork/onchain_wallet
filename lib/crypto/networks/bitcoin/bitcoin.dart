import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/utils.dart';

class BTCUtils {
  static int decimal = 8;
  static Script toOpreturn(List<String> data) {
    final dataHex = data
        .map((e) => BytesUtils.toHexString(StringUtils.toBytes(e)))
        .toList();
    return Script(script: ["OP_RETURN", ...dataHex]);
  }

  static String? opReturnToView(Script opReturn) {
    if (opReturn.script.isEmpty) return null;
    if (opReturn.script.length == 1) return opReturn.script.first;
    final opData = opReturn.script.sublist(1);
    final List<String> decodedData = [];
    for (final i in opData) {
      final toBytes = BytesUtils.fromHexString(i);
      try {
        final decode = StringUtils.decode(toBytes);
        decodedData.add(decode);
        continue;
      } catch (e) {
        decodedData.add(i);
      }
    }
    return [opReturn.script.first, ...decodedData].join(", ");
  }

  static String getAddressDetails(BitcoinAddressType addressType) {
    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return "Pay to Public Key Hash (P2PKH)";
      case SegwitAddressType.p2wpkh:
        return "Pay to Witness Public Key Hash (P2WPKH)";
      case SegwitAddressType.p2tr:
        return "Pay to Taproot (P2TR)";
      case SegwitAddressType.p2wsh:
        return "Pay to Witness Script Hash (P2WSH)";
      case P2shAddressType.p2wshInP2sh:
        return "Pay to Witness Script Hash in Pay to Script Hash (P2WSH-in-P2SH)";
      case P2shAddressType.p2wpkhInP2sh:
        return "Pay to Witness Public Key Hash in Pay to Script Hash (P2WPKH-in-P2SH)";
      case P2shAddressType.p2pkhInP2sh:
        return "Pay to Public Key Hash in Pay to Script Hash (P2PKH-in-P2SH)";
      case P2shAddressType.p2pkInP2sh:
        return "Pay to Public Key in Pay to Script Hash (P2PK-in-P2SH)";
      case P2shAddressType.p2pkhInP2sh32:
        return "Pay to Public Key Hash in Pay to Script Hash 32 (P2PKH-in-P2SH32)";
      case P2shAddressType.p2pkInP2sh32:
        return "Pay to Public Key in Pay to Script Hash 32 (P2PK-in-P2SH32)";
      case P2shAddressType.p2pkhInP2sh32wt:
        return "Pay to Public Key Hash in Pay to Script Hash 32 with Token (P2PKH-in-P2SH32 with Token)";
      case P2shAddressType.p2pkInP2sh32wt:
        return "Pay to Public Key in Pay to Script Hash 32 with Token (P2PK-in-P2SH32 with Token)";
      case P2shAddressType.p2pkhInP2shwt:
        return "Pay to Public Key Hash in Pay to Script Hash with Token (P2PKH-in-P2SH with Token)";
      case P2shAddressType.p2pkInP2shwt:
        return "Pay to Public Key in Pay to Script Hash with Token (P2PK-in-P2SH with Token)";
      case P2pkhAddressType.p2pkhwt:
        return "Pay to Public Key Hash with Token (P2PKH with Token)";
      default:
        return "Unknown Address Type";
    }
  }
}
