import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class CoingeckoCoinInfo {
  final String id;
  final Map<Currency, dynamic> prices;
  final DateTime expire;

  bool isExpired() {
    return expire.isBefore(DateTime.now());
  }

  CoingeckoCoinInfo({required this.id, required this.prices})
      : expire = DateTime.now().add(const Duration(minutes: 10));
  factory CoingeckoCoinInfo.fromJson(Map<String, dynamic> json, String id) {
    final Map<Currency, dynamic> prices = {};
    for (final i in json.entries) {
      final currency = Currency.fromName(i.key);
      if (currency == null) continue;
      prices[currency] = i.value.toString();
    }
    return CoingeckoCoinInfo(id: id, prices: prices);
  }

  BigRational? getPrice(Currency currency) {
    if (!prices.containsKey(currency)) return null;
    final val = prices[currency]!;
    if (val is String) {
      prices[currency] = BigRational.parseDecimal(val);
    }
    return prices[currency];
  }
}

class CoingeckoPriceHandler {
  Map<String, CoingeckoCoinInfo?> _coins;
  CoingeckoPriceHandler(this._coins);
  List<String> _supportIds = [];
  bool get hasCoinList => _supportIds.isNotEmpty;
  bool get inited => _coins.isNotEmpty;
  void updateSupportIds(List<String> ids) {
    _supportIds = ids;
    if (hasCoinList) {
      _coins.removeWhere((k, _) => !_supportIds.contains(k));
    }
  }

  factory CoingeckoPriceHandler.fromJson(Map<String, dynamic> json) {
    return CoingeckoPriceHandler(
        json.map((key, value) => MapEntry(key, CoingeckoCoinInfo.fromJson(value, key))));
  }
  final Map<String, IntegerBalance> _caches = {};
  IntegerBalance? getPrice(
      {required Currency baseCurrency, required String amount, required APPToken token}) {
    final String? coingeckoId = token.market?.apiId;
    if (coingeckoId == null || amount.startsWith("-")) {
      return null;
    }
    if (coingeckoId == baseCurrency.coingeckoId) {
      return null;
    }
    final name = "${baseCurrency.name}_${coingeckoId}_$amount";
    final BigRational? basePrice = _coins[coingeckoId]?.getPrice(baseCurrency);
    if (basePrice == null) return null;
    _caches[name] ??= _getPrice(
        basePrice: basePrice, token: token, amount: amount, baseCurrency: baseCurrency);
    return _caches[name];
  }

  IntegerBalance _getPrice(
      {required BigRational basePrice,
      required APPToken token,
      required String amount,
      required Currency baseCurrency}) {
    return IntegerBalance.convertRational2(
        basePrice: basePrice,
        // token: token,
        amount: amount,
        newToken: baseCurrency.toToken(),
        decimalPlaces: baseCurrency.decimal,
        allowNegative: false,
        immutable: true);
  }

  // IntegerBalance _getDecimalPrice(
  //     {required BigRational basePrice,
  //     required NonDecimalToken token,
  //     required String amount,
  //     required Currency baseCurrency}) {
  //   return IntegerBalance.convertRational(
  //       basePrice: basePrice,
  //       token: token,
  //       amount: amount,
  //       newToken: baseCurrency.toToken(),
  //       decimalPlaces: baseCurrency.decimal,
  //       allowNegative: false,
  //       immutable: true);
  // }

  void addCoin(CoingeckoCoinInfo newCoin) {
    _coins[newCoin.id] = newCoin;
  }

  void clearCache() {
    _caches.clear();
  }

  CoingeckoCoinInfo? getCoin(String id) {
    return _coins[id];
  }

  List<String> getIds() {
    final ids = _coins.keys.where((k) => _coins[k]?.isExpired() ?? true).toList();
    return ids;
  }

  void merge(CoingeckoPriceHandler other) {
    _coins.addAll(other._coins);
  }

  void addCoinsIds(List<String> ids) {
    if (hasCoinList) {
      ids = ids.where((e) => _supportIds.contains(e)).toList();
    }
    for (final i in ids) {
      if (!_coins.containsKey(i)) {
        _coins[i] = null;
      }
    }
  }
}
