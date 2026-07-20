import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class MoneroNetworkParams extends NetworkCoinParams {
  final MoneroNetwork network;
  final int rctHeight;

  factory MoneroNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.monero.identifier);

    return MoneroNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        network: MoneroNetwork.fromValue(values.rawValueAt(2)),
        rctHeight: values.rawValueAt(3),
        addressExplorer: values.rawValueAt(4),
        transactionExplorer: values.rawValueAt(5));
  }
  const MoneroNetworkParams(
      {required super.token,
      required super.chainType,
      required this.network,
      required this.rctHeight,
      super.addressExplorer,
      super.transactionExplorer});

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.monero.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        network.value.toCbor(),
        rctHeight.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor()
      ];
  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return MoneroNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        network: network,
        rctHeight: rctHeight,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }

  @override
  int get averageBlockTime {
    return 120;
  }

  @override
  int get maxTxConfirmationBlock => 10;
}
