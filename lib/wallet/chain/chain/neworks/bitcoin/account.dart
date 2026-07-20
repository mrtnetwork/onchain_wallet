part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class BitcoinNetworkStorageId extends DefaultNetworkStorageId {
  static const BitcoinNetworkStorageId utxos = BitcoinNetworkStorageId(51);
  const BitcoinNetworkStorageId(super.storageId);
  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    utxos,
  ];
}

final class BitcoinChain extends Chain<
    BitcoinNetworkAddress,
    TokenCore,
    NFTCore,
    WalletBitcoinNetwork,
    BitcoinWalletTransaction,
    IBitcoinAddress,
    BitcoinNetworkClient,
    BitcoinNetworkProvider,
    IBitcoinChainContext> {
  BitcoinChain._(
      {required WalletBitcoinNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            BitcoinMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory BitcoinChain.setup(
      {required WalletBitcoinNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return BitcoinChain._(network: network, id: id, controller: controller);
  }

  factory BitcoinChain.deserialize(
      {required WalletBitcoinNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return BitcoinChain._(network: network, id: id, controller: controller);
  }

  Future<IResult<BitcoinUtxosWithAccountInfo>> getAccountUtxos(IBitcoinAddress address,
      {bool includeTokens = true}) {
    return _context.getAccountUtxos(address, includeTokens: includeTokens);
  }

  BitcoinNetworkAddress? findAddressFromScriptSync(Script script) {
    return _context.findAddressFromScriptSync(script);
  }
}
