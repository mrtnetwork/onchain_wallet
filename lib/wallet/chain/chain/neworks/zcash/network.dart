part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class ZcashNetworkController extends NetworkController<IZcashAddress, ZcashChain,
    Web3ZcashChainAccount, Web3InternalDefaultChain, ChainConfig> {
  ZcashNetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.zcash);

  @override
  Future<IResult<Web3ZcashChainAuthenticated>> createWeb3ChainAuthenticated(
    Web3ApplicationAuthentication app,
  ) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3ZcashChainIdnetifier(
              id: e.network.value,
              wsIdentifier: e.network.wsIdentifier,
              caip2: e.network.caip,
              network: e.zcashNetwork))
          .toList();
      List<Web3ZcashChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];
        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) {
          return networkAddresses.cast();
        }
        final List<IZcashAddress> addresses = [];
        for (final a in i.accounts) {
          final address = networkAddresses.unwrap().firstWhereOrNull((e) =>
              e.identifier == a.identifier && e.derivationIndex == a.derivationIndex);
          if (address == null) continue;
          addresses.add(address);
        }
        final defaultAddress = addresses.firstWhereOrNull((e) =>
                e.identifier == i.defaultAccount?.identifier &&
                e.derivationIndex == i.defaultAccount?.derivationIndex) ??
            addresses.firstOrNull;
        web3Accounts.addAll(addresses.map((e) => Web3ZcashChainAccount.fromChainAccount(
            address: e, isDefault: e == defaultAddress, id: e.network.value)));
      }
      return ResultOk(Web3ZcashChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }

  Future<IResult<ZcashSyncChain>> updateSyncChain(
      {required ZcashSyncChain syncChain,
      int? resetTrackerHeight,
      List<IZcashAddress>? addresses}) async {
    final update = await _storageSaveSyncChain(syncChain);
    return update.andThenAsync((_) async {
      final result = await IResult.anyError(_chains.values.map((e) => e.updateSyncChain(
          resetTrackerHeight:
              syncChain.network == e.zcashNetwork ? resetTrackerHeight : null,
          addresses: syncChain.network == e.zcashNetwork ? addresses : null)));
      return result.map((_) => syncChain);
    });
  }

  Future<IResult<void>> _storageSaveSyncChain(ZcashSyncChain syncChain) async {
    final storageKey = ZcashChainStorageId.syncChain;
    return await _storage.insertChainStorage(storage: storageKey, value: syncChain);
  }
}
