part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class MoneroChain extends Chain<
    MoneroAddress,
    TokenCore,
    NFTCore,
    WalletMoneroNetwork,
    MoneroWalletTransaction,
    IMoneroAddress,
    MoneroNetworkClient,
    MoneroNetworkProvider,
    IMoneroChainContext> {
  MoneroChain._(
      {required WalletMoneroNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            MoneroMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory MoneroChain.setup(
      {required WalletMoneroNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return MoneroChain._(network: network, id: id, controller: controller);
  }

  factory MoneroChain.deserialize(
      {required WalletMoneroNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return MoneroChain._(network: network, id: id, controller: controller);
  }

  @override
  NextDerivationMonero nextDerive({
    required CryptoCoins coin,
    required SeedTypes seedGeneration,
    required int? subId,
    DerivableIndex? startIndex,
  }) {
    return _context.nextDerive(
        coin: coin, seedGeneration: seedGeneration, subId: subId, startIndex: startIndex);
  }

  Future<IResult<MoneroSyncChain>> getSyncChain() {
    return _context.getSyncChain();
  }

  Future<IResult<MoneroWalletClient?>> walletClient() {
    return _context.walletClient();
  }

  Future<IResult<DefaultAPIProvider?>> getWalletProvider() {
    return _context.getWalletProvider();
  }

  Future<IResult<void>> updateWalletProvider(DefaultAPIProvider? provider) {
    return _context.updateWalletProvider(provider);
  }

  Future<IResult<void>> removeSyncingRequest(int requestId) {
    return _context.removeSyncingRequest(requestId);
  }

  Future<IResult<List<MoneroSubIndex>>> relatedAccountIndexes(
      DerivableIndex masterIndex) {
    return _context.relatedAccountIndexes(masterIndex);
  }

  Future<IResult<MoneroSyncing?>> getSyncing() async {
    return _context.getSyncing();
  }

  Future<IResult<List<MoneroUtxosWithAccountInfo>>> getPrimaryAccountUtxos(
      IMoneroAddress address) {
    return _context.getPrimaryAccountUtxos(address);
  }

  Future<IResult<List<IMoneroAddress>>> getPrimaryAccountAddresses(
      IMoneroAddress address) {
    return _context.getPrimaryAccountAddresses(address);
  }

  Future<IResult<MoneroUtxosWithAccountInfo>> getAddressUtxos(IMoneroAddress address) {
    return _context.getAddressUtxos(address);
  }

  IMoneroAddress? fromAccountIndex(MoneroAccountIndex index) {
    return _context.fromAccountIndex(index);
  }

  Future<IResult<MoneroSyncTrackerController>> getChainTracker() {
    return _context.getChainTracker();
  }

  MoneroNetwork get moneroNetwork => network.coinParam.network;

  Future<IResult<void>> updateSyncChain(
      {int? resetTrackerHeight, List<IMoneroAddress>? addresses}) {
    return _context.updateSyncChain(
        resetTrackerHeight: resetTrackerHeight, addresses: addresses);
  }

  Future<IResult<String>> generateTxProof(
      {required MoneroProofTxParams params, required IMoneroAddress address}) {
    return _context.generateTxProof(params: params, address: address);
  }

  Future<IResult<BigInt?>> verifyTxProof(
      {required MoneroVerifyProofTxParams params, required IMoneroAddress address}) {
    return _context.verifyTxProof(params: params, address: address);
  }

  Future<IResult<List<MoneroAccountTxTrackerStatus>>> importUtxos(List<String> txIds) {
    return _context.importUtxos(txIds);
  }

  Future<IResult<void>> addSyncRequest(MoneroSyncAccountRequest request) {
    return _context.addSyncRequest(request);
  }
}
