import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class CoingeckoCoin with AppSerialization {
  final String apiId;
  final String? coinName;
  final String? symbol;
  const CoingeckoCoin({required this.apiId, this.coinName, this.symbol});
  factory CoingeckoCoin.fromJson(Map<String, dynamic> json) {
    return CoingeckoCoin(
        apiId: json["id"], coinName: json["name"], symbol: json["symbol"]);
  }

  factory CoingeckoCoin.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.coingeckoInfo);
    return CoingeckoCoin(
        apiId: cbor.rawValueAt(0),
        coinName: cbor.rawValueAt(1),
        symbol: cbor.rawValueAt(2));
  }

  String? get marketUri {
    if (coinName == null) return null;
    return CoinGeckoUtils.getTokenCoinGeckoURL(coinName!);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.coingeckoInfo;

  @override
  List<CborObject?> get serializationItems =>
      [apiId.toCbor(), coinName?.toCbor(), symbol?.toCbor()];
}
