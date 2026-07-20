import 'package:blockchain_utils/bip/address/ada/ada.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain/ada/src/address/address.dart';

class CardanoUtils {
  static const int maxMultisigThresholdInt = 32;
  static final BigRational maxMultisigThreshold =
      BigRational.from(maxMultisigThresholdInt);
  static const int decimal = 6;
  static const int bip32StakeChangeLevel = 2;
  static const int bip32StakeAddressLevel = 0;
  static const int byronAddressHdPathKeyLengthBytes = 32;
  static const String hdPathHint = "m/1/2";
  static ADARewardAddress? extractRewardAddress(ADAAddress addr) {
    switch (addr.addressType) {
      case ADAAddressType.base:
        return (addr as ADABaseAddress).stakeAddress();
      case ADAAddressType.reward:
        return addr as ADARewardAddress;
      default:
        return null;
    }
  }
}
