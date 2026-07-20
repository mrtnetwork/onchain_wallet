import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';

class SuiToken extends TokenCoreInteger {
  SuiToken._(
      {required super.balance,
      required super.token,
      required super.updated,
      required this.assetType,
      required bool isFreeze})
      : _isFreeze = isFreeze,
        super();
  factory SuiToken.create(
      {required BigInt balance,
      required Token token,
      required String assetType,
      bool isFreeze = false}) {
    return SuiToken._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        updated: DateTime.now(),
        assetType: assetType,
        isFreeze: isFreeze);
  }
  factory SuiToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.sui.tag);
    final Token token = Token.deserialize(object: values.objectAt<CborTagValue>(0));
    final IntegerBalance balance =
        IntegerBalance.token(values.rawValueAt(1), token, immutable: true);
    final DateTime updated = values.rawValueAt(2);
    final String assetType = values.rawValueAt(3);
    final bool isFreez = values.rawValueAt<bool>(4);
    return SuiToken._(
        balance: balance,
        token: token,
        updated: updated,
        assetType: assetType,
        isFreeze: isFreez);
  }
  @override
  SuiToken clone({BigInt? balance}) {
    return SuiToken.create(
        balance: balance ?? streamBalance.value.balance,
        token: token,
        assetType: assetType);
  }

  @override
  SuiToken updateToken(Token updateToken) {
    return SuiToken.create(
        balance: streamBalance.value.balance, token: updateToken, assetType: assetType);
  }

  final String assetType;
  bool _isFreeze;
  bool get isFreeze => _isFreeze;
  void setFreeze(bool freeze) {
    _isFreeze = freeze;
  }

  @override
  List get variables => [assetType];

  @override
  String? get issuer => assetType;

  @override
  late final String? type = "FATs";

  @override
  TokenCoreType get tokenType => TokenCoreType.sui;

  @override
  String get identifier => assetType;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated),
        assetType.toCbor(),
        _isFreeze.toCbor()
      ];
}
