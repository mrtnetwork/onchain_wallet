import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class _SubstrateTokenUtils {
  static String generateIdentifier(Object assetIdentifier) {
    if (assetIdentifier is XCMVersionedLocation) {
      return TokenCore.toIdentifier(assetIdentifier.toHex());
    }
    return TokenCore.toIdentifier(assetIdentifier.toString());
  }
}

class SubstrateToken extends TokenCoreInteger {
  final Object assetIdentifier;
  @override
  final String identifier;

  SubstrateToken._({
    required super.balance,
    required super.token,
    required this.assetIdentifier,
    required super.updated,
    required this.identifier,
  }) : super();
  factory SubstrateToken.create({
    required BigInt balance,
    required Token token,
    required Object assetIdentifier,
  }) {
    return SubstrateToken._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        assetIdentifier: assetIdentifier,
        updated: DateTime.now(),
        identifier: _SubstrateTokenUtils.generateIdentifier(assetIdentifier));
  }
  factory SubstrateToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.substrate.tag);
    final Token token = Token.deserialize(object: values.objectAt<CborTagValue>(0));
    final IntegerBalance balance =
        IntegerBalance.token(values.rawValueAt(1), token, immutable: true);
    final DateTime updated = values.rawValueAt(2);
    Object? assetIentifier = values.objectAt<CborObject?>(3)?.getValue();
    final String identifier = values.rawValueAt(4);
    if (assetIentifier == null) {
      final List<int>? location = values.rawValueAt(5);
      if (location == null) {
        throw WalletExceptionConst.invalidTokenInformation;
      }
      assetIentifier = XCMVersionedLocation.deserialize(location);
    }
    return SubstrateToken._(
        balance: balance,
        token: token,
        updated: updated,
        assetIdentifier: assetIentifier,
        identifier: identifier);
  }
  @override
  SubstrateToken clone({BigInt? balance}) {
    return SubstrateToken._(
        balance:
            IntegerBalance.token(balance ?? this.balance.balance, token, immutable: true),
        token: token,
        assetIdentifier: assetIdentifier,
        identifier: identifier,
        updated: updated);
  }

  @override
  SubstrateToken updateToken(Token updateToken) {
    return SubstrateToken._(
        balance: balance,
        token: updateToken,
        assetIdentifier: assetIdentifier,
        updated: updated,
        identifier: identifier);
  }

  @override
  List get variables => [assetIdentifier];

  @override
  String? get type => null;

  @override
  TokenCoreType get tokenType => TokenCoreType.substrate;

  @override
  String? get issuer => null;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated),
        switch (assetIdentifier) {
          final XCMVersionedLocation _ => CborNullValue(),
          _ => CborObject.fromDynamic(assetIdentifier)
        },
        identifier.toCbor(),
        switch (assetIdentifier) {
          final XCMVersionedLocation location =>
            CborBytesValue(location.serializeVariant()),
          _ => CborNullValue()
        },
      ];
}
