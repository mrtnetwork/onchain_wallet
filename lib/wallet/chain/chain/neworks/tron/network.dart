part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class TronNetworkController extends NetworkController<ITronAddress, TronChain,
    Web3TronChainAccount, Web3InternalDefaultChain, ChainConfig> {
  TronNetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.tron);

  @override
  Future<IResult<Web3TronChainAuthenticated>> createWeb3ChainAuthenticated(
    Web3ApplicationAuthentication app,
  ) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = await Future.wait(this.web3Networks.map((e) async {
        final provoders = await e.getActiveService(web3: true);

        ///
        final provider = ProvidersConst.getOrDefaultTronDefaultProvider(
            e.network.tronNetworkType,
            provoders.fold(
                onErr: (error) => [],
                onOk: (e) => [
                      if (e != null) ...[e.node, e.ethereum]
                    ]));
        return Web3TronChainIdnetifier(
          id: e.network.value,
          chainId: e.network.tronNetworkType.genesisBlockNumber,
          solidityNode: provider.solidity.url,
          fullNode: provider.node.url,
          wsIdentifier: e.network.wsIdentifier,
          caip2: e.network.caip,
        );
      }).toList());
      List<Web3TronChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];
        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) {
          return networkAddresses.cast();
        }
        final List<ITronAddress> addresses = [];
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
        web3Accounts.addAll(addresses.map((e) => Web3TronChainAccount.fromChainAccount(
            address: e, isDefault: e == defaultAddress, id: e.network.value)));
      }
      return ResultOk(Web3TronChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }
}
