import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'global.dart';

class TonConst {
  static const int defaultSubWalletId = 698983191;
  static const int minTonMnemonicWords = 8;
  static const int maxTonMnemonicWords = 48;
  static const int defaultTonMnemonicWordsLength = 24;
  static const int deciaml = 9;
  static const int mainnetWokchainId = 0;
  static BigRational get maxTransferQueryId => BlockchainConst.maxSupply;
  static const int maximumSubWalletId = BinaryOps.mask32 - 1;
  static const int maximumWalletId = (1 << 31) - 1;
  static const int maximumV5SubWalletId = (1 << 15) - 1;
}
