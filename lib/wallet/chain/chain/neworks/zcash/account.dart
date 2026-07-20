part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ZcashChain extends Chain<
    ZcashAddress,
    TokenCore,
    NFTCore,
    WalletZcashNetwork,
    ZcashWalletTransaction,
    IZcashAddress,
    ZcashNetworkClient,
    ZcashNetworkProvider,
    IZcashChainContext> {
  ZcashChain._(
      {required WalletZcashNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            ZcashMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });
  factory ZcashChain.setup(
      {required WalletZcashNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return ZcashChain._(network: network, id: id, controller: controller);
  }

  factory ZcashChain.deserialize(
      {required WalletZcashNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return ZcashChain._(network: network, id: id, controller: controller);
  }

  List<BigInt> saplingAccountsDiversifierIndexsSync() {
    return _context.saplingAccountsDiversifierIndexsSync();
  }

  IZcashAddress? fromReceiverSync(ZcashAccountInfoShield info) {
    return _context.fromReceiverSync(info);
  }

  Future<IResult<List<ZcashUtxosWithAccountInfo>>> getAccountUtxos(IZcashAddress address,
      {ZcashProtocol? protocol}) {
    return _context.getAccountUtxos(address, protocol: protocol);
  }

  Future<IResult<void>> removeSyncingRequest(int requestId) {
    return _context.removeSyncingRequest(requestId);
  }

  Future<IResult<void>> updateSyncChain(
      {int? resetTrackerHeight, List<IZcashAddress>? addresses}) {
    return _context.updateSyncChain(
        resetTrackerHeight: resetTrackerHeight, addresses: addresses);
  }

  Future<IResult<void>> addSyncRequest(ZcashSyncAccountRequest request) {
    return _context.addSyncRequest(request);
  }

  Future<IResult<ZcashSyncTrackerController>> getChainTracker() {
    return _context.getChainTracker();
  }

  Future<IResult<ZcashSyncChain>> getSyncChain() {
    return _context.getSyncChain();
  }

  Future<IResult<ZcashSyncing?>> getSyncing() {
    return _context.getSyncing();
  }

  List<ZcashProtocol> supportedProtocols() => _context.supportedProtocols();

  Future<IResult<TableStructAColums>> getTrackerMerkleColumn() async {
    return ResultOk(_context.storageGetTrackerMerkleColumn());
  }

  Future<IResult<ZcashProtocolAddressWithUtxos>> getProtocolUtxos(
      IZcashAddress address, ZcashProtocol protocol) {
    return _context.getProtocolUtxos(address, protocol);
  }

  Future<IResult<List<ZcashProtocolAddressWithUtxos>>> getProtocolsUtxos(
      IZcashAddress address) {
    return _context.getProtocolsUtxos(address);
  }

  @override
  bool addressSupportedByWalletPlatform(ZcashAddress addr) {
    return _context.addressSupportedByWalletPlatform(addr);
  }

  ZcashNetwork get zcashNetwork => network.coinParam.network;

  ZcashSyncChain get accountSyncChain => _context.accountSyncChain;
}
