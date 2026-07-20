import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/networks/ethereum/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class EthereumNetworkParams extends NetworkCoinParams {
  final String id;
  final bool supportEIP1559;
  final bool defaultNetwork;

  @override
  bool get isTestNet => defaultNetwork && !mainnet;
  const EthereumNetworkParams.unsafe(
      {super.transactionExplorer,
      super.addressExplorer,
      required super.token,
      required this.id,
      required this.supportEIP1559,
      required super.chainType,
      super.bip32CoinType,
      this.defaultNetwork = true});
  factory EthereumNetworkParams(
      {String? transactionExplorer,
      String? addressExplorer,
      required Token token,
      required BigInt chainId,
      required bool supportEIP1559,
      required ChainType chainType,
      bool defaultNetwork = true,
      int? bip32CoinType}) {
    if (chainId.isNegative || token.decimal != EthereumUtils.decimal) {
      throw const WalletException.message("invalid_network_information");
    }
    return EthereumNetworkParams.unsafe(
        transactionExplorer: transactionExplorer,
        addressExplorer: addressExplorer,
        token: token,
        id: chainId.toString(),
        supportEIP1559: supportEIP1559,
        chainType: chainType,
        bip32CoinType: bip32CoinType,
        defaultNetwork: defaultNetwork);
  }

  factory EthereumNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NetworkType.ethereum.identifier);
    final bool defaultNetwork = cbor.rawValueAt(4);
    return EthereumNetworkParams.unsafe(
      id: cbor.rawValueAt(0),
      supportEIP1559: cbor.rawValueAt(1),
      chainType: ChainType.fromValue(cbor.rawValueAt(2)),
      token: Token.deserialize(object: cbor.objectAt<CborTagValue>(3)),
      defaultNetwork: defaultNetwork,
      bip32CoinType: cbor.rawValueAt(5),
      transactionExplorer: cbor.rawValueAt(6),
      addressExplorer: cbor.rawValueAt(7),
    );
  }

  BigInt get identifier => chainId;

  BigInt get chainId => BigInt.parse(id);

  @override
  EthereumNetworkParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return EthereumNetworkParams.unsafe(
      transactionExplorer: transactionExplorer,
      addressExplorer: addressExplorer,
      token:
          NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
      id: id,
      supportEIP1559: supportEIP1559,
      chainType: chainType,
      defaultNetwork: defaultNetwork,
      bip32CoinType: bip32CoinType,
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.ethereum.identifier;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        supportEIP1559.toCbor(),
        chainType.value.toCbor(),
        token.toCbor(),
        defaultNetwork.toCbor(),
        bip32CoinType?.toCbor(),
        transactionExplorer?.toCbor(),
        addressExplorer?.toCbor(),
      ];
}
