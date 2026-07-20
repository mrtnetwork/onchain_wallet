part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class ADANetworkStorageId extends DefaultNetworkStorageId {
  static const ADANetworkStorageId utxos = ADANetworkStorageId(51);
  const ADANetworkStorageId(super.storageId);
  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    utxos,
  ];
}

final class ADAChain extends Chain<
    ADAAddress,
    TokenCore,
    NFTCore,
    WalletCardanoNetwork,
    ADAWalletTransaction,
    ICardanoAddress,
    ADANetworkClient,
    CardanoNetworkProvider,
    IADAChainContext> {
  ADAChain._(
      {required WalletCardanoNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            ADAMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory ADAChain.setup(
      {required WalletCardanoNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return ADAChain._(network: network, id: id, controller: controller);
  }

  factory ADAChain.deserialize(
      {required WalletCardanoNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);

    return ADAChain._(network: network, id: id, controller: controller);
  }

  Future<IResult<List<TransactionUnspentOutput>>> getAccountTransactionUnspentOutputs(
      ICardanoAddress address) {
    return _context.getAccountTransactionUnspentOutputs(address);
  }

  Future<IResult<List<TransactionUnspentOutput>>>
      getAccountLatestTransactionUnspentOutputs(ICardanoAddress address) {
    return _context.getAccountLatestTransactionUnspentOutputs(address);
  }

  Future<IResult<List<ADAAddressUtxo>>> getAccountUtxos(ICardanoAddress address) async {
    return _context.getAccountUtxos(address);
  }
}
