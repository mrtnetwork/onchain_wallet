import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class CardanoNetworkParams extends NetworkCoinParams {
  final ADANetwork networkType;
  String get chainId {
    return "${networkType.value}-${networkType.protocolMagic}";
  }

  factory CardanoNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.cardano.identifier);

    return CardanoNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        networkType: ADANetwork.fromProtocolMagic(values.rawValueAt(2)),
        addressExplorer: values.rawValueAt(3),
        transactionExplorer: values.rawValueAt(4));
  }
  const CardanoNetworkParams(
      {required super.token,
      required super.chainType,
      required this.networkType,
      super.addressExplorer,
      super.transactionExplorer});

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.cardano.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        networkType.protocolMagic.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor()
      ];
  int get identifier => networkType.protocolMagic;

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return CardanoNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        networkType: networkType,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }

  @override
  int get averageBlockTime => 20;
  @override
  int get maxTxConfirmationBlock => 5;
}
