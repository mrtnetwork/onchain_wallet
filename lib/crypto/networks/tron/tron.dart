import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain/tron/tron.dart';

class TronUtils {
  static const int decimal = 6;
  static const int signatureLength = 65;
  static const int tronFeeRequiredSize = 64;
  static const int maxPermissionThreshhold = 9007199254740991;
  static const Duration defaultTronTrasactionExpiration = Duration(hours: 1);
  static const String defaultActivePermissionOperation =
      "7fff1fc0033ec30f000000000000000000000000000000000000000000000000";
  static const int maxWitnessPermissionKeyLength = 1;
  static const int maxPermissionKeyLength = 5;
  static final BigInt maxTronFeeLimit = BigInt.from(15000000000);
  static final BigRational maxDelegatedLockPeriod =
      BigRational(BigInt.from(864000));
  static final BigRational defaultDelegateLockPeriod =
      BigRational(BigInt.from(86400));
  static const List<ResourceCode> tronFrozenReosurce = [
    ResourceCode.bandWidth,
    ResourceCode.energy
  ];
  static DateTime delegatedLockPeriodToDateTime(BigInt lockPeriod) {
    return DateTime.now()
        .add(Duration(seconds: (lockPeriod * BigInt.from(3)).toInt()));
  }

  static const List<int> disabledOperation = [51, 52, 53];
  static final List<TransactionContractType> supportedOperations =
      List<TransactionContractType>.unmodifiable(TransactionContractType.values
          .where((e) => !disabledOperation.contains(e.value)));
}
