import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:on_chain_wallet/app/core.dart';

class CoinsUtils {
  static T getSerializationCoin<T extends CryptoCoins>(int serialize) {
    final coin = CryptoCoins.fromIdentifier(serialize);
    if (coin == null || coin is! T) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    return coin;
  }
}

extension ExtCryptoCoinsCasting on CryptoCoins {
  T cast<T extends CryptoCoins>() {
    final coin = this;
    if (coin is T) return coin;
    throw AppInternalError.internalError("Casting coin failed.");
  }
}
