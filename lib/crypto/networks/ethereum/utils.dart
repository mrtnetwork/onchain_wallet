import 'package:blockchain_utils/utils/utils.dart';

class EthereumUtils {
  static const int decimal = 18;
  static const int gweiDecimal = 9;
  static final BigRational gWeiBigRatinal =
      BigRational(BigInt.from(10).pow(gweiDecimal));
  static const int baseGasLimit = 21000;

  static BigRational weiToGwei(BigInt wei) {
    final weiRational = BigRational(wei);
    return (weiRational / gWeiBigRatinal);
  }

  static BigInt gWeiDeciamlToWei(BigRational gwei) {
    final inWei = gwei * gWeiBigRatinal;
    return inWei.toBigInt();
  }
}
