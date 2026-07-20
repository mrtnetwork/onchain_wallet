import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';

class BtcConst {
  static const int decimal = 8;
  static final BigInt minFeePerKb = BigInt.from(1024);
  static final BigRational minMultiSigThresholdRational =
      BigRational.from(minMultiSigThreshold);
  static final BigRational maxMultiSigThresholdRational =
      BigRational.from(maxMultiSigThreshold);
  static const int minMultiSigThreshold = 2;
  static const int maxMultiSigThreshold = 16;
  static const int minCoinbaseConfirmation = 100;
}
