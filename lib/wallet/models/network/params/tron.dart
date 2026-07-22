import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class TronNetworkParams extends NetworkCoinParams {
  factory TronNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.tron.identifier);

    return TronNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        addressExplorer: values.rawValueAt(2),
        transactionExplorer: values.rawValueAt(3));
  }
  const TronNetworkParams(
      {required super.token,
      required super.chainType,
      super.addressExplorer,
      super.transactionExplorer});

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return TronNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.tron.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor()
      ];

  @override
  int get averageBlockTime => 5;
}
