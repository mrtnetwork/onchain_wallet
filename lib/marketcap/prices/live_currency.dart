import 'dart:async';

import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/marketcap/prices/coingecko.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class LiveCurrencies {
  final INetApi netApi;
  LiveCurrencies(this.netApi);
  final _syncRequest = SafeAtomicLock();
  final CoingeckoPriceHandler _currenciesPrice = CoingeckoPriceHandler({});
  bool get inited => _currenciesPrice.inited;
  StreamSubscription? _prices;
  late final StreamValue<Currency> _currency =
      StreamValue<Currency>(Currency.USD, name: "LiveCurrencies");
  StreamValue<Currency> get currency => _currency;
  Currency get currencyToken => _currency.value;

  Future<IResult<void>> _getCoinList() async {
    if (_currenciesPrice.hasCoinList) return ResultOk(null);
    Future<IResult<List<String>>> getCoinList() async {
      final json = await netApi.httpGet<List<Map<String, dynamic>>>(
          CoinGeckoUtils.coinGeckoCoinListURL,
          headers: {"User-Agent": "on_chain_wallet"},
          logError: false,
          responseType: StreamEncoding.listOfMap);
      return json.map(
          (e) => e.map((e) => CoingeckoCoin.fromJson(e)).map((e) => e.apiId).toList());
    }

    final ids = await getCoinList();
    return ids.map((ids) => _currenciesPrice.updateSupportIds(ids));
  }

  // WalletCore get wallet;
  Future<IResult<CoingeckoPriceHandler>> _getCoinPrices(List<String> coins) async {
    final url = CoinGeckoUtils.toCoingeckoPriceUri(Currency.toApiCall(), coins.join(","));
    final json = await netApi.httpGet<Map<String, dynamic>>(url,
        responseType: StreamEncoding.map,
        headers: {"User-Agent": "on_chain_wallet"},
        logError: false);
    return json.map((json) => CoingeckoPriceHandler.fromJson(json));
  }

  Future<IResult<CoingeckoCoinInfo?>> _getCoinPrice(String id) async {
    final url = CoinGeckoUtils.toCoingeckoPriceUri(Currency.toApiCall(), id);
    final json = await netApi.httpGet<Map<String, dynamic>>(url,
        responseType: StreamEncoding.map,
        headers: {"User-Agent": "on_chain_wallet"},
        logError: false);
    return json.map((json) {
      final result = json.valueAsMap<Map<String, dynamic>?>(id);
      if (result == null) return null;
      return CoingeckoCoinInfo.fromJson(result, id);
    });
  }

  IntegerBalance? amount(String amount, APPToken token) {
    // if (token is NonDecimalToken) return null;
    return _currenciesPrice.getPrice(
        baseCurrency: currencyToken, token: token, amount: amount);
  }

  IntegerBalance? getTokenPrice({required String amount, required APPToken? token}) {
    if (token == null) return null;
    return _currenciesPrice.getPrice(
        baseCurrency: currencyToken, token: token, amount: amount);
  }

  Future<IResult<CoingeckoCoinInfo?>> getCoinPrice(String id) async {
    CoingeckoCoinInfo? coin = _currenciesPrice.getCoin(id);
    if (coin == null) {
      final updateCoin = await _getCoinPrice(id);
      return updateCoin.map((coin) {
        if (coin != null) {
          _currenciesPrice.addCoin(coin);
        }
        return coin;
      });
    }
    return ResultOk(coin);
  }

  void _onUpdatePrices(CoingeckoPriceHandler result) {
    _currenciesPrice.merge(result);
    _currency.notify();
  }

  Future<void> _onPredioc(dynamic _) async {
    await _syncRequest.run(() async {
      await _getCoinList();

      if (_currenciesPrice.hasCoinList) {
        final remindIds = _currenciesPrice.getIds();
        if (remindIds.isEmpty) return;
        final prices = await _getCoinPrices(remindIds.take(400).toList());
        prices.watch(onOk: (value) => _onUpdatePrices(value));
      }
      await Future.delayed(const Duration(seconds: 10));
    });
  }

  Future<void> dispose() async {
    await _syncRequest.run(() {
      _prices?.cancel();
      _prices = null;
    });
  }

  Future<void> streamPrices(List<String> ids) async {
    await _syncRequest.run(() {
      _prices ??= Stream.periodic(const Duration(seconds: 15)).listen(_onPredioc);
      _currenciesPrice.addCoinsIds(ids);
    });
  }

  void changeCurrency(Currency? currency) {
    if (currency == null || currency == _currency.value) return;
    _currenciesPrice.clearCache();
    _currency.value = currency;
  }
}
