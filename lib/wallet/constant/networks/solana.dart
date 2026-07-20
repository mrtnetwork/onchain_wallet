import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain_wallet/app/core.dart';

class SolanaConst {
  static const int memoLength = (566 * 2) - 1;
  static const int systemProgramAccountSpace = 129;
  static BigInt get systemProgramRent => BigInt.from(890880);
  static BigInt get solanaDefaultTxFeePerSignature => BigInt.from(5000);
  static String get systemProgramRentSol =>
      PriceUtils.encodePrice(systemProgramRent, decimal,
          amoutDecimal: APPConst.defaultDecimalPlaces);
  static const int decimal = 9;
  static BigRational get maximumAccountSizeBytes => BigRational.from(10240);
  static BigRational get maxSPLTokenDecimalPlaces => BigRational.from(18);
  static const int minimumSolanaBase58SecretKey = 87;
  static const String mainnetGenesis = "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d";
  static const String testnetGenesis = "4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY";
  static const String devnetGenesis = "EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG";
  static const String tokenListUri =
      "https://cdn.jsdelivr.net/gh/solana-labs/token-list@latest/src/tokens/solana.tokenlist.json";
}
