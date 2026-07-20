import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';

class TronTRC10Token extends TronToken {
  TronTRC10Token._(
      {required super.balance,
      required super.token,
      required this.tokenID,
      required super.updated})
      : super();
  factory TronTRC10Token.create(
      {required BigInt balance, required Token token, required String tokenID}) {
    return TronTRC10Token._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        tokenID: tokenID,
        updated: DateTime.now());
  }
  factory TronTRC10Token.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.trc10.tag);
    final Token token = Token.deserialize(object: cbor.objectAt<CborTagValue>(0));
    final String tokenID = cbor.rawValueAt(1);
    final DateTime updated = cbor.rawValueAt(3);
    return TronTRC10Token._(
        balance: IntegerBalance.token(cbor.rawValueAt(2), token, immutable: true),
        token: token,
        tokenID: tokenID,
        updated: updated);
  }

  @override
  TronTRC10Token clone({BigInt? balance}) {
    return TronTRC10Token.create(
        balance: balance ?? streamBalance.value.balance, token: token, tokenID: tokenID);
  }

  @override
  TronTRC10Token updateToken(Token updateToken) {
    return TronTRC10Token.create(
        balance: streamBalance.value.balance, token: updateToken, tokenID: tokenID);
  }

  final String tokenID;

  @override
  List get variables => [tokenID];

  @override
  String get issuer => tokenID;

  @override
  late final String? type = tronTokenType.name;

  @override
  TronTokenTypes get tronTokenType => TronTokenTypes.trc10;

  @override
  TokenCoreType get tokenType => TokenCoreType.trc10;

  @override
  String get identifier => tokenID;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        tokenID.toCbor(),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated)
      ];
}
