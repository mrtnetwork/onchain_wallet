import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

enum SolanaNetworkType {
  mainnet(
      identifier: 'solana:mainnet',
      value: 0,
      genesis: "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp"),
  testnet(
      identifier: 'solana:testnet',
      value: 1,
      genesis: "4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z"),

  devnet(
      identifier: 'solana:devnet', value: 2, genesis: "EtWTRABZaYq6iMfeYKouRu166VU2xqa1");

  final String identifier;
  final int value;
  final String genesis;
  const SolanaNetworkType(
      {required this.identifier, required this.value, required this.genesis});
  static SolanaNetworkType fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("SolanaNetworkType"));
  }
}

class SolanaNetworkParams extends NetworkCoinParams {
  final int chainId;
  final SolanaNetworkType type;

  factory SolanaNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.solana.identifier);

    return SolanaNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        chainId: values.rawValueAt(2),
        type: SolanaNetworkType.fromValue(values.rawValueAt(3)),
        addressExplorer: values.rawValueAt(4),
        transactionExplorer: values.rawValueAt(5));
  }
  const SolanaNetworkParams(
      {required super.token,
      required super.chainType,
      required this.chainId,
      required this.type,
      super.addressExplorer,
      super.transactionExplorer});

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.solana.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        chainId.toCbor(),
        type.value.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor()
      ];
  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return SolanaNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        chainId: chainId,
        type: type,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }
}
