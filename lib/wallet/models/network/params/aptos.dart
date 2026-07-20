import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

enum AptosChainType {
  devnet(null),
  testnet(2),
  mainnet(1);

  const AptosChainType(this.id);
  final int? id;
  bool get isDevnet => this == devnet;
  String get identifier => "aptos:$name";
  static AptosChainType fromValue(int? value) {
    if (value == null || value > 170) return AptosChainType.devnet;
    return values.firstWhere(
      (e) => e.id == value,
      orElse: () => throw AppInternalError.internalError("AptosChainType"),
    );
  }
}

class AptosNetworkParams extends NetworkCoinParams {
  final AptosChainType aptosChainType;

  factory AptosNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.aptos.identifier);

    return AptosNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        aptosChainType: AptosChainType.fromValue(values.rawValueAt(1)),
        chainType: ChainType.fromValue(values.rawValueAt(2)),
        addressExplorer: values.rawValueAt(3),
        transactionExplorer: values.rawValueAt(4),
        bip32CoinType: values.rawValueAt(5));
  }
  const AptosNetworkParams(
      {required super.token,
      required super.chainType,
      required this.aptosChainType,
      super.addressExplorer,
      super.transactionExplorer,
      super.bip32CoinType});

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return AptosNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        aptosChainType: aptosChainType,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer,
        bip32CoinType: bip32CoinType ?? this.bip32CoinType);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.aptos.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        aptosChainType.id?.toCbor(),
        chainType.value.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor(),
        bip32CoinType?.toCbor()
      ];
}
