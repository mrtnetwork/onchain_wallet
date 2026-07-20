import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';

class CW20Token extends TokenCoreInteger {
  CW20Token._(
      {required super.balance,
      required super.token,
      required super.updated,
      required this.denom})
      : super();
  factory CW20Token.create(
      {required BigInt balance, required Token token, required String denom}) {
    return CW20Token._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        updated: DateTime.now(),
        denom: denom);
  }
  factory CW20Token.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.cw20.tag);

    final Token token = Token.deserialize(object: values.objectAt<CborTagValue>(0));
    final IntegerBalance balance =
        IntegerBalance.token(values.rawValueAt(1), token, immutable: true);
    final DateTime updated = values.rawValueAt(2);
    final String denom = values.rawValueAt(3);
    return CW20Token._(balance: balance, token: token, updated: updated, denom: denom);
  }
  @override
  CW20Token clone({BigInt? balance}) {
    return CW20Token.create(
        balance: balance ?? streamBalance.value.balance, token: token, denom: denom);
  }

  @override
  CW20Token updateToken(Token updateToken) {
    return CW20Token.create(
        balance: streamBalance.value.balance, token: updateToken, denom: denom);
  }

  final String denom;

  @override
  List get variables => [denom];

  @override
  String? get issuer => denom;

  @override
  late final String? type = "CW20";

  @override
  TokenCoreType get tokenType => TokenCoreType.cw20;

  @override
  String get identifier => denom;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated),
        denom.toCbor()
      ];
}
