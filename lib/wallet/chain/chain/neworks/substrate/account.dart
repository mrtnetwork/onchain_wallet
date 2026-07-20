part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class SubstrateNetworkStorageId extends DefaultNetworkStorageId {
  static const SubstrateNetworkStorageId multisigTransactions =
      SubstrateNetworkStorageId(51);
  const SubstrateNetworkStorageId(super.storageId);
  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    multisigTransactions,
  ];
}

final class SubstrateChain extends Chain<
    BaseSubstrateAddress,
    SubstrateToken,
    NFTCore,
    WalletSubstrateNetwork,
    SubstrateWalletTransaction,
    ISubstrateAddress,
    SubstrateNetworkClient,
    SubstrateNetworkProvider,
    ISubstrateChainContext> {
  SubstrateChain._(
      {required WalletSubstrateNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            SubstrateMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory SubstrateChain.setup(
      {required WalletSubstrateNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return SubstrateChain._(network: network, id: id, controller: controller);
  }

  factory SubstrateChain.deserialize(
      {required WalletSubstrateNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return SubstrateChain._(network: network, id: id, controller: controller);
  }

  Future<IResult<List<SubstrateMultisigCallData>>> getAccountMultisigs(
      ISubstrateMultiSigAddress address,
      {SubstrateMultisigCall? newRequest}) {
    return _context.getAccountMultisigs(address, newRequest: newRequest);
  }
}
