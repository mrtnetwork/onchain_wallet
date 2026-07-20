import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

enum RippleKeyScheme {
  ed25519(value: 0, name: "ED25519"),
  secp256k1(value: 1, name: "Secp256k1");

  final int value;
  final String name;

  const RippleKeyScheme({required this.value, required this.name});
  static RippleKeyScheme fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("RippleKeyScheme"));
  }

  EllipticCurveTypes get curve {
    return switch (this) {
      RippleKeyScheme.secp256k1 => EllipticCurveTypes.secp256k1,
      _ => EllipticCurveTypes.ed25519
    };
  }
}

class RippleNetworkParams extends NetworkCoinParams {
  final int networkId;

  factory RippleNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.xrpl.identifier);
    return RippleNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        networkId: values.rawValueAt(2),
        addressExplorer: values.rawValueAt(3),
        transactionExplorer: values.rawValueAt(4));
  }
  const RippleNetworkParams(
      {required super.token,
      required super.chainType,
      required this.networkId,
      super.addressExplorer,
      super.transactionExplorer});

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.xrpl.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        networkId.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor()
      ];
  int get identifier => networkId;

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return RippleNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        networkId: networkId,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }
}
