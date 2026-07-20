import 'package:on_chain_wallet/app/models/models/image.dart';

class CoinGeckoUtils {
  static const String _coingeckoPublicCurrenciesAPI =
      "https://api.coingecko.com/api/v3/simple/price?ids=#ids&vs_currencies=#currencies";
  static const String coinGeckoCoinURL = "https://www.coingecko.com/en/coins/#id";
  static const String coinGeckoCoinListURL =
      "https://api.coingecko.com/api/v3/coins/list";
  static const APPImage logo = APPImage.local("assets/image/coingeko.png");
  static const int limitReachedStatusCode = 429;
  static String? getTokenCoinGeckoURL(String id) {
    return coinGeckoCoinURL.replaceFirst("#id", id);
  }

  static String toCoingeckoPriceUri(String currencies, String ids) {
    return _coingeckoPublicCurrenciesAPI
        .replaceFirst("#currencies", currencies)
        .replaceFirst("#ids", ids);
  }
}
