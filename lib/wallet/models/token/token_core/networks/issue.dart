import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';

class RippleIssueToken extends TokenCoreDecimal {
  RippleIssueToken._(
      {required super.balance,
      required super.token,
      required this.issuer,
      required super.updated,
      required this.assetCode})
      : super();
  factory RippleIssueToken.create(
      {required String balance,
      required NonDecimalToken token,
      required String issuer,
      required String assetCode}) {
    return RippleIssueToken._(
        balance: DecimalBalance.fromString(balance, token, immutable: true),
        token: token,
        issuer: issuer,
        updated: DateTime.now(),
        assetCode: assetCode);
  }
  factory RippleIssueToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.ripple.tag);

    final NonDecimalToken token =
        NonDecimalToken.deserialize(object: cbor.objectAt<CborTagValue>(0));
    final String issuer = cbor.rawValueAt(1);
    final String assetCode = cbor.rawValueAt(2);
    final DecimalBalance balance =
        DecimalBalance.fromString(cbor.rawValueAt(3), token, immutable: true);
    final DateTime updated = cbor.rawValueAt(4);
    return RippleIssueToken._(
        balance: balance,
        token: token,
        issuer: issuer,
        updated: updated,
        assetCode: assetCode);
  }
  @override
  RippleIssueToken clone({BigRational? balance}) {
    return RippleIssueToken.create(
        balance: balance?.toDecimal() ?? streamBalance.value.price,
        token: token,
        issuer: issuer,
        assetCode: assetCode);
  }

  @override
  RippleIssueToken updateToken(Token updateToken) {
    return RippleIssueToken.create(
        balance: streamBalance.value.price,
        token: NonDecimalToken(
            name: updateToken.name,
            symbol: updateToken.symbol,
            assetLogo: updateToken.assetLogo,
            market: updateToken.market),
        issuer: issuer,
        assetCode: assetCode);
  }

  BigRational get currencyBalance => streamBalance.value.balance;

  @override
  final String issuer;
  final String assetCode;

  @override
  List get variables => [issuer, assetCode];

  @override
  final String? type = null;
  @override
  TokenCoreType get tokenType => TokenCoreType.ripple;
  @override
  String get identifier => '$issuer-$assetCode';

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        issuer.toCbor(),
        assetCode.toCbor(),
        streamBalance.value.balance.toDecimal().toCbor(),
        CborEpochIntValue(updated)
      ];
}
