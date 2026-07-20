import 'package:blockchain_utils/utils/utils.dart';

class APPSubstrateConst {
  static const List<int> supportedVersion = [14, 15, 16];
  static BigRational get feeRate => BigRational.parseDecimal("1.1");
  static const String utilityBatchVariantName = "batch";

  static const String extrinsicFailedMethodName = "ExtrinsicFailed";
  static const String systemRemarkVariantName = "remark";
  static const String existentialDepositStorageName = "existentialDeposit";
  static const int defaultEraPeriod = 155;
  static const int maxDecimals = 38;

  static const String depositBase = "DepositBase";
  static const String depositFactor = "DepositFactor";
  static const String maxSignatories = "MaxSignatories";
  static const String batchedCallsLimit = "batched_calls_limit";
}
