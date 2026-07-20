part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class AptosNetworkController extends NetworkController<IAptosAddress, AptosChain,
    Web3AptosChainAccount, Web3InternalDefaultChain, ChainConfig> {
  AptosNetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.aptos);

  @override
  Future<IResult<Web3AptosChainAuthenticated>> createWeb3ChainAuthenticated(
      Web3ApplicationAuthentication app) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3AptosChainIdnetifier(
              id: e.network.value,
              wsIdentifier: e.network.wsIdentifier,
              caip2: e.network.caip,
              chainId: e.network.coinParam.aptosChainType.id))
          .toList();
      List<Web3AptosChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];

        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) {
          return networkAddresses.cast();
        }
        final List<IAptosAddress> addresses = [];
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
        web3Accounts.addAll(addresses.map((e) => Web3AptosChainAccount.fromChainAccount(
            address: e,
            network: network.network.coinParam.aptosChainType,
            isDefault: e == defaultAddress,
            id: e.network.value)));
      }
      return ResultOk(Web3AptosChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }
}
