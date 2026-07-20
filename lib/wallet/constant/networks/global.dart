import 'package:blockchain_utils/utils/utils.dart';

class BlockchainConst {
  static const int maxBip32LevelIndex = 5;
  static const int maxByronLegacyBip32LevelIndex = 2;
  static BigRational get maxSupply => BigRational(BinaryOps.maxU64);
  static const int minimumKeysLength = 16;
  static const int maxTokenDecimal = 255;
  static const String cip0019CoinsName = "CIP-0019";
}
