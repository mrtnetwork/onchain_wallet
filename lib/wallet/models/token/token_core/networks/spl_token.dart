import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain/solana/src/address/sol_address.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';

class SolanaSPLToken extends TokenCoreInteger {
  SolanaSPLToken._(
      {required super.balance,
      required super.token,
      required this.mint,
      required this.tokenAccount,
      required super.updated,
      required this.tokenOwner})
      : super();
  factory SolanaSPLToken.create({
    required BigInt balance,
    required Token token,
    required SolAddress mint,
    required SolAddress tokenAccount,
    required SolAddress tokenOwner,
  }) {
    return SolanaSPLToken._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        mint: mint,
        tokenAccount: tokenAccount,
        updated: DateTime.now(),
        tokenOwner: tokenOwner);
  }
  factory SolanaSPLToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.spl.tag);
    final Token token = Token.deserialize(object: cbor.objectAt<CborTagValue>(0));
    final IntegerBalance balance =
        IntegerBalance.token(cbor.rawValueAt(2), token, immutable: true);
    final DateTime updated = cbor.rawValueAt(3);
    return SolanaSPLToken._(
        balance: balance,
        token: token,
        mint: SolAddress.deserializeIAddress(bytes: cbor.rawValueAt(1)),
        tokenAccount: SolAddress.deserializeIAddress(bytes: cbor.rawValueAt(4)),
        updated: updated,
        tokenOwner: SolAddress.deserializeIAddress(bytes: cbor.rawValueAt(5)));
  }
  @override
  SolanaSPLToken clone({BigInt? balance}) {
    return SolanaSPLToken.create(
        balance: balance ?? streamBalance.value.balance,
        token: token,
        mint: mint,
        tokenAccount: tokenAccount,
        tokenOwner: tokenOwner);
  }

  @override
  SolanaSPLToken updateToken(Token updateToken) {
    return SolanaSPLToken.create(
        balance: streamBalance.value.balance,
        token: updateToken,
        mint: mint,
        tokenAccount: tokenAccount,
        tokenOwner: tokenOwner);
  }

  final SolAddress mint;
  final SolAddress tokenAccount;
  final SolAddress tokenOwner;

  @override
  List get variables => [mint.address, tokenAccount.address];

  @override
  String? get issuer => mint.address;

  @override
  late final String? type = "SPL";
  @override
  TokenCoreType get tokenType => TokenCoreType.spl;

  @override
  String get identifier => mint.address;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        CborBytesValue(mint.encodeAsIAddress()),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated),
        CborBytesValue(tokenAccount.encodeAsIAddress()),
        CborBytesValue(tokenOwner.encodeAsIAddress()),
      ];
}
