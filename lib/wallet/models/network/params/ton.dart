import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:ton_dart/ton_dart.dart';
// import 'package:ton_dart/ton_dart.dart' as ton;

class TonNetworkParams extends NetworkCoinParams {
  TonChainId get chainId => switch (chainType) {
        ChainType.testnet => TonChainId.testnet,
        ChainType.mainnet => TonChainId.mainnet,
      };

  const TonNetworkParams(
      {required super.token,
      required super.chainType,
      super.addressExplorer,
      super.transactionExplorer});

  factory TonNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.ton.identifier);
    return TonNetworkParams(
        chainType: ChainType.fromValue(values.rawValueAt(0)),
        token: Token.deserialize(object: values.objectAt<CborTagValue>(1)),
        addressExplorer: values.rawValueAt(2),
        transactionExplorer: values.rawValueAt(3));
  }

  // int get identifier => workchain;

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return TonNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.ton.identifier;

  @override
  List<CborObject?> get serializationItems => [
        chainType.value.toCbor(),
        token.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor()
      ];
}
