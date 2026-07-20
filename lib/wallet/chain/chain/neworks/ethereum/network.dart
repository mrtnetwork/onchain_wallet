part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class EthereumNetworkController extends NetworkController<IEthereumAddress, EthereumChain,
    Web3EthereumChainAccount, Web3InternalDefaultChain, ChainConfig> {
  EthereumNetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.ethereum);

  @override
  Future<IResult<Web3EthereumChainAuthenticated>> createWeb3ChainAuthenticated(
      Web3ApplicationAuthentication app) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3EthereumChainIdnetifier(
                id: e.network.value,
                chainId: e.chainId,
                supportEIP1559: e.network.coinParam.supportEIP1559,
                wsIdentifier: e.network.wsIdentifier,
                caip2: e.network.caip,
              ))
          .toList();
      List<Web3EthereumChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];
        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) {
          return networkAddresses.cast();
        }
        final List<IEthereumAddress> addresses = [];
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
        web3Accounts
            .addAll(addresses.map((e) => Web3EthereumChainAccount.fromChainAccount(
                  address: e,
                  isDefault: e == defaultAddress,
                  id: e.network.value,
                )));
      }
      final currentNetwork = _chains[internalNetwork.defaultChain]!;
      final provider = await currentNetwork.getActiveService(web3: true);
      return ResultOk(Web3EthereumChainAuthenticated(
          accounts: web3Accounts,
          networks: web3Networks,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          serviceIdentifier: provider.ok()?.provider));
    });
  }
}
