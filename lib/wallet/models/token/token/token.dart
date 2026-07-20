import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/models/token/coingecko/coin.dart';

class _TokenConst {
  static const String unknowTokenName = "Unknown";
}

abstract class APPToken with AppSerialization, Equality {
  final String name;
  final String symbol;
  final String nameView;
  final String symbolView;
  final CoingeckoCoin? market;
  final APPImage? assetLogo;
  const APPToken(
      {required this.name,
      required this.symbol,
      required this.nameView,
      required this.symbolView,
      required this.market,
      required this.assetLogo});
}

class Token extends APPToken {
  final int decimal;
  factory Token.deserialize({List<int>? bytes, CborObject? object}) {
    try {
      final CborListValue cbor = AppSerialization.decodeTaggedValue(
          cborBytes: bytes,
          cborObject: object,
          identifier: AppSerializationIdentifier.token);
      final String name = cbor.rawValueAt(0);
      final String symbol = cbor.rawValueAt(1);
      final int decimal = cbor.rawValueAt(2);
      final APPImage? image = cbor.maybeObjectAt<APPImage, CborTagValue>(
          3, (e) => APPImage.deserialize(object: e));
      final CoingeckoCoin? market = cbor.maybeObjectAt<CoingeckoCoin, CborTagValue>(
          4, (e) => CoingeckoCoin.deserialize(object: e));
      return Token(
          name: name, symbol: symbol, decimal: decimal, assetLogo: image, market: market);
    } catch (e) {
      throw WalletExceptionConst.invalidTokenInformation;
    }
  }
  const Token.unsafe(
      {required super.name,
      required super.symbol,
      required super.nameView,
      required super.symbolView,
      super.assetLogo,
      required this.decimal,
      super.market});
  factory Token(
      {required String? name,
      required String? symbol,
      APPImage? assetLogo,
      required int decimal,
      CoingeckoCoin? market}) {
    if (decimal < 0 || decimal > 255) {
      throw WalletExceptionConst.invalidTokenInformation;
    }
    name ??= symbol ?? _TokenConst.unknowTokenName;
    symbol ??= name;
    final String nameView = StrUtils.substring(name, length: 20);
    final String symbolView = StrUtils.substring(symbol, length: 5);
    return Token.unsafe(
        name: name,
        symbol: symbol,
        assetLogo: assetLogo,
        decimal: decimal,
        market: market,
        nameView: nameView,
        symbolView: symbolView);
  }
  Token copyWith({
    String? name,
    String? symbol,
    int? decimal,
    APPImage? assetLogo,
    CoingeckoCoin? market,
  }) {
    return Token(
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        decimal: decimal ?? this.decimal,
        assetLogo: assetLogo ?? this.assetLogo,
        market: market ?? this.market);
  }

  @override
  List get variables => [name, symbol, decimal];

  String? get marketUri {
    return market?.marketUri;
  }

  @override
  String toString() {
    return "Token: $name";
  }

  @override
  SerializationIdentifier get serializationIdentifier => AppSerializationIdentifier.token;

  @override
  List<CborObject?> get serializationItems => [
        name.toCbor(),
        symbol.toCbor(),
        decimal.toCbor(),
        assetLogo?.toCbor(),
        market?.toCbor()
      ];
}

class NonDecimalToken extends APPToken {
  factory NonDecimalToken.deserialize({List<int>? bytes, CborObject? object}) {
    try {
      final CborListValue cbor = AppSerialization.decodeTaggedValue(
          cborBytes: bytes,
          cborObject: object,
          identifier: AppSerializationIdentifier.decimalToken);
      final String name = cbor.rawValueAt(0);
      final String symbol = cbor.rawValueAt(1);
      final APPImage? image = cbor.maybeObjectAt<APPImage, CborTagValue>(
          2, (e) => APPImage.deserialize(object: e));
      final CoingeckoCoin? market = cbor.maybeObjectAt<CoingeckoCoin, CborTagValue>(
          3, (e) => CoingeckoCoin.deserialize(object: e));

      return NonDecimalToken(
          name: name, symbol: symbol, assetLogo: image, market: market);
    } catch (e) {
      throw WalletExceptionConst.invalidTokenInformation;
    }
  }
  const NonDecimalToken._(
      {required super.name,
      required super.symbol,
      required super.nameView,
      required super.symbolView,
      super.assetLogo,
      super.market});
  factory NonDecimalToken(
      {required String name,
      required String symbol,
      APPImage? assetLogo,
      CoingeckoCoin? market}) {
    final String nameView = StrUtils.substring(name, length: 20);
    final String symbolView = StrUtils.substring(symbol, length: 5);
    return NonDecimalToken._(
        name: name,
        symbol: symbol,
        assetLogo: assetLogo,
        market: market,
        nameView: nameView,
        symbolView: symbolView);
  }
  NonDecimalToken copyWith({
    String? name,
    String? symbol,
    APPImage? assetLogo,
    CoingeckoCoin? market,
  }) {
    return NonDecimalToken(
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        assetLogo: assetLogo ?? this.assetLogo,
        market: market ?? this.market);
  }

  @override
  List get variables => [name, symbol];

  String? get marketUri {
    return market?.marketUri;
  }

  @override
  String toString() {
    return "Token: $name";
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.decimalToken;

  @override
  List<CborObject?> get serializationItems =>
      [name.toCbor(), symbol.toCbor(), assetLogo?.toCbor(), market?.toCbor()];
}
