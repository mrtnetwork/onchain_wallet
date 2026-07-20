import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class TonJettonToken extends TokenCoreInteger {
  TonJettonToken._(
      {required super.balance,
      required super.token,
      required this.minterAddress,
      required this.walletAddress,
      required super.updated})
      : super();

  factory TonJettonToken.create({
    required BigInt balance,
    required Token token,
    required TonAddress minterAddress,
    required TonAddress walletAddress,
  }) {
    return TonJettonToken._(
      balance: IntegerBalance.token(balance, token, immutable: true),
      token: token,
      minterAddress: minterAddress,
      walletAddress: walletAddress,
      updated: DateTime.now(),
    );
  }
  factory TonJettonToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.jetton.tag);
    final Token token = Token.deserialize(object: cbor.objectAt<CborTagValue>(0));
    final DateTime updated = cbor.rawValueAt(4);
    return TonJettonToken._(
        balance: IntegerBalance.token(cbor.rawValueAt(3), token, immutable: true),
        token: token,
        minterAddress: TonAddress.deserializeIAddress(bytes: cbor.rawValueAt(1)),
        walletAddress: TonAddress.deserializeIAddress(bytes: cbor.rawValueAt(2)),
        updated: updated);
  }

  final TonAddress minterAddress;
  final TonAddress walletAddress;

  @override
  TonJettonToken clone({BigInt? balance}) {
    return TonJettonToken.create(
      balance: balance ?? streamBalance.value.balance,
      token: token,
      minterAddress: minterAddress,
      walletAddress: walletAddress,
    );
  }

  @override
  TonJettonToken updateToken(Token updateToken) {
    return TonJettonToken.create(
      balance: streamBalance.value.balance,
      token: updateToken,
      minterAddress: minterAddress,
      walletAddress: walletAddress,
    );
  }

  @override
  List get variables => [minterAddress, walletAddress];

  @override
  String? get issuer => minterAddress.address;

  @override
  late final String? type = "Jetton";
  @override
  TokenCoreType get tokenType => TokenCoreType.jetton;

  @override
  String get identifier => minterAddress.address;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        CborBytesValue(minterAddress.encodeAsIAddress()),
        CborBytesValue(walletAddress.encodeAsIAddress()),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated),
      ];
}
