import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';
import 'package:stellar_dart/stellar_dart.dart';

class StellarIssueToken extends TokenCoreInteger {
  StellarIssueToken._(
      {required super.balance,
      required super.token,
      required this.issuer,
      required super.updated,
      required this.assetType,
      required this.assetCode})
      : super();
  factory StellarIssueToken.create(
      {required BigInt balance,
      required Token token,
      required String issuer,
      required AssetType assetType,
      required String assetCode}) {
    return StellarIssueToken._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        issuer: issuer,
        updated: DateTime.now(),
        assetType: assetType,
        assetCode: assetCode);
  }
  factory StellarIssueToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.stellar.tag);
    final Token token = Token.deserialize(object: values.objectAt<CborTagValue>(0));
    final String issuer = values.rawValueAt(1);
    final IntegerBalance balance =
        IntegerBalance.token(values.rawValueAt(2), token, immutable: true);
    final DateTime updated = values.rawValueAt(3);
    final AssetType assetType = AssetType.fromName(values.rawValueAt(4));
    final String assetCode = values.rawValueAt(5);
    return StellarIssueToken._(
        balance: balance,
        token: token,
        issuer: issuer,
        updated: updated,
        assetType: assetType,
        assetCode: assetCode);
  }
  @override
  StellarIssueToken clone({BigInt? balance}) {
    return StellarIssueToken.create(
        balance: balance ?? this.balance.balance,
        token: token,
        issuer: issuer,
        assetType: assetType,
        assetCode: assetCode);
  }

  @override
  StellarIssueToken updateToken(Token updateToken) {
    if (updateToken.decimal != token.decimal) {
      throw WalletExceptionConst.invalidTokenInformation;
    }
    return StellarIssueToken._(
        balance: balance,
        token: updateToken,
        issuer: issuer,
        updated: updated,
        assetType: assetType,
        assetCode: assetCode);
  }

  final AssetType assetType;
  @override
  final String issuer;

  final String assetCode;

  @override
  List get variables => [issuer, assetType.name, assetCode];

  @override
  String? get type => assetType.name;

  StellarAsset toStellarAsset() {
    switch (assetType) {
      case AssetType.creditAlphanum4:
        return StellarAssetCreditAlphanum4(
            issuer: StellarPublicKey.fromAddress(StellarAddress.fromBase32Addr(issuer)),
            code: assetCode);
      case AssetType.creditAlphanum12:
        return StellarAssetCreditAlphanum12(
            issuer: StellarPublicKey.fromAddress(StellarAddress.fromBase32Addr(issuer)),
            code: assetCode);
      default:
        throw WalletExceptionConst.invalidTokenInformation;
    }
  }

  @override
  TokenCoreType get tokenType => TokenCoreType.stellar;

  @override
  String get identifier => "$issuer-$assetCode-$assetType";

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        issuer.toCbor(),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated),
        assetType.name.toCbor(),
        assetCode.toCbor()
      ];
}
