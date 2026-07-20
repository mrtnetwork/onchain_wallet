import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/utils.dart';

class BCHUtils {
  static final BigRational maximumTokenCashTotalSupply =
      BigRational(BigInt.parse("9223372036854775807"));
  static final BigRational minimumTokenCashTotalSupply = BigRational.one;
  static const String hintIPFSUri =
      "bafkreihfrxykireezlcp2jstp7cjwx5nl7of3nuul3qnubxygwvwcjun44";
  static const String hintWebsite =
      "https://example.com/.well-known/bitcoin-cash-metadata-registry.json";
  static const int maxBCHOpReturnSize = 233;
  static const int maxCommitment = 40;
  static final BigInt minimumSatoshiTokenOutput = BigInt.from(900);
  static final BigInt minimumOutput = BigInt.from(900);
  static final BigInt maxTokenOutputNativAmount = BigInt.from(1000000);
  static const int decimal = 8;

  static String cleanUpBCMRUri(String uri) {
    if (uri.startsWith("https://ipfs.io/ipfs/")) {
      return "ipfs://${uri.replaceFirst("https://ipfs.io/ipfs/", "")}";
    }
    final parse = Uri.parse(uri);
    if (uri.endsWith("/.well-known/bitcoin-cash-metadata-registry.json")) {
      final subdomains = parse.host.split(".");
      if (subdomains.length > 2) {
        return "${parse.host}/";
      }
      return parse.host;
    }

    return uri;
  }

  static bool commitmentValidate(String? v) {
    if (v == null) return true;
    if (StringUtils.toBytes(v).length <= maxCommitment) {
      return true;
    }
    return false;
  }

  static CashToken createCashToken(
      {String? category,
      BigInt? amount,
      String? commitment,
      int? bitfield,
      CashTokenCapability? capability}) {
    return CashToken(
        category: category ?? "0" * 64,
        bitfield: bitfield ??
            CashTokenUtils.buildBitfield(
                hasAmount: amount != null,
                hasCommitmentLength: capability != null && commitment != null,
                capability: capability,
                hasNFT: capability != null),
        commitment: commitment == null ? null : StringUtils.toBytes(commitment),
        amount: amount);
  }
}
