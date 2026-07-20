// ignore_for_file: constant_identifier_names

import 'package:on_chain_wallet/app/utils/list/extension.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

enum Currency {
  BTC("Bitcoin", 8, coingeckoId: "bitcoin"),
  ETH("Ethereum", 18, coingeckoId: "ethereum"),
  LTC("Litecoin", 8, coingeckoId: "litecoin"),
  BCH("Bitcoin Cash", 8, coingeckoId: "bitcoin-cash"),
  BNB("Binance Coin", 18, coingeckoId: "binancecoin"),
  EOS("EOS", 4),
  XRP("XRP", 6, coingeckoId: "ripple"),
  XLM("Stellar", 7, coingeckoId: "stellar"),
  LINK("Chainlink", 18, coingeckoId: "chainlink"),
  DOT("Polkadot", 10, coingeckoId: "polkadot"),
  YFI("yearn.finance", 18),
  USD("United States Dollar", 2),
  AED("United Arab Emirates Dirham", 2),
  ARS("Argentine Peso", 2),
  AUD("Australian Dollar", 2),
  BDT("Bangladeshi Taka", 2),
  BHD("Bahraini Dinar", 3),
  BMD("Bermudian Dollar", 2),
  BRL("Brazilian Real", 2),
  CAD("Canadian Dollar", 2),
  CHF("Swiss Franc", 2),
  CLP("Chilean Peso", 2),
  CNY("Chinese Yuan", 2),
  CZK("Czech Koruna", 2),
  DKK("Danish Krone", 2),
  EUR("Euro", 2),
  GBP("British Pound Sterling", 2),
  GEL("Georgian Lari", 2),
  HKD("Hong Kong Dollar", 2),
  HUF("Hungarian Forint", 2),
  IDR("Indonesian Rupiah", 2),
  ILS("Israeli New Shekel", 2),
  INR("Indian Rupee", 2),
  JPY("Japanese Yen", 0),
  KRW("South Korean Won", 0),
  KWD("Kuwaiti Dinar", 3),
  LKR("Sri Lankan Rupee", 2),
  MMK("Myanmar Kyat", 2),
  MXN("Mexican Peso", 2),
  MYR("Malaysian Ringgit", 2),
  NGN("Nigerian Naira", 2),
  NOK("Norwegian Krone", 2),
  NZD("New Zealand Dollar", 2),
  PHP("Philippine Peso", 2),
  PKR("Pakistani Rupee", 2),
  PLN("Polish Złoty", 2),
  RUB("Russian Ruble", 2),
  SAR("Saudi Riyal", 2),
  SEK("Swedish Krona", 2),
  SGD("Singapore Dollar", 2),
  THB("Thai Baht", 2),
  TRY("Turkish Lira", 2),
  TWD("New Taiwan Dollar", 2),
  UAH("Ukrainian Hryvnia", 2),
  VEF("Venezuelan Bolívar", 2),
  VND("Vietnamese Đồng", 2),
  ZAR("South African Rand", 2),
  XDR("Special Drawing Rights (SDR)", 2),
  XAG("Silver (measured in troy ounces)", 2),
  XAU("Gold (measured in troy ounces)", 2);

  final String currencyName;
  final String? coingeckoId;
  final int decimal;

  const Currency(this.currencyName, this.decimal, {this.coingeckoId});

  static String toApiCall() {
    return values.map((e) => e.name).join(",");
  }

  Token toToken() {
    return Token(name: currencyName, symbol: name, decimal: decimal);
  }

  static Currency? fromName(String? name) {
    if (name == null) return null;
    name = name.toLowerCase();
    return values.firstWhereOrNull((element) => element.name.toLowerCase() == name);
  }
}
