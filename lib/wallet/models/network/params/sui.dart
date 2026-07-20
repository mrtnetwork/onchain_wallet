import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

enum SuiChainType {
  devnet(0),
  testnet(1),
  mainnet(2);

  const SuiChainType(this.value);
  final int value;
  String get identifier => "sui:$name";
  static SuiChainType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("SuiChainType"),
    );
  }
}

class SuiNetworkParams extends NetworkCoinParams {
  final String identifier;
  final SuiChainType suiChain;

  factory SuiNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.sui.identifier);

    return SuiNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        identifier: values.rawValueAt(2),
        addressExplorer: values.rawValueAt(3),
        transactionExplorer: values.rawValueAt(4),
        bip32CoinType: values.rawValueAt(5),
        suiChain: SuiChainType.fromValue(values.rawValueAt(6)));
  }
  const SuiNetworkParams(
      {required super.token,
      required super.chainType,
      required this.identifier,
      required this.suiChain,
      super.addressExplorer,
      super.transactionExplorer,
      super.bip32CoinType});

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return SuiNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        identifier: identifier,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer,
        bip32CoinType: bip32CoinType ?? this.bip32CoinType,
        suiChain: suiChain);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.sui.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        identifier.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor(),
        bip32CoinType?.toCbor(),
        suiChain.value.toCbor()
      ];
}
