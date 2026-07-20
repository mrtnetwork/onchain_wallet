part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class BitcoinNetworkController extends NetworkController<IBitcoinAddress, BitcoinChain,
    Web3BitcoinChainAccount, Web3InternalDefaultChain, ChainConfig> {
  BitcoinNetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.bitcoinAndForked);

  @override
  Future<IResult<Web3BitcoinChainAuthenticated>> createWeb3ChainAuthenticated(
    Web3ApplicationAuthentication app,
  ) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3BitcoinChainIdnetifier(
              id: e.network.value,
              wsIdentifier: e.network.wsIdentifier,
              caip2: e.network.caip,
              network: e.network.coinParam.transacationNetwork))
          .toList();
      List<Web3BitcoinChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];
        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) return networkAddresses.cast();
        final List<IBitcoinAddress> addresses = [];
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
        web3Accounts.addAll(addresses.map((e) => Web3BitcoinChainAccount.fromChainAccount(
            address: e, network: network.network, isDefault: e == defaultAddress)));
      }
      return ResultOk(Web3BitcoinChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }
}

class BitcoinCashNetworkController extends NetworkController<IBitcoinAddress,
    BitcoinChain, Web3BitcoinCashChainAccount, Web3InternalDefaultChain, ChainConfig> {
  BitcoinCashNetworkController(
      {super.networks, required super.id, required super.database})
      : super(type: NetworkType.bitcoinCash);

  @override
  Future<IResult<Web3BitcoinCashChainAuthenticated>> createWeb3ChainAuthenticated(
    Web3ApplicationAuthentication app,
  ) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3BitcoinCashChainIdnetifier(
              id: e.network.value,
              wsIdentifier: e.network.wsIdentifier,
              caip2: e.network.caip,
              network: e.network.coinParam.transacationNetwork as BitcoinCashNetwork))
          .toList();
      List<Web3BitcoinCashChainAccount> web3Accounts = [];
      // for (final i in internalNetwork.networks) {
      //   final network = _chains[i.networkId];
      //   if (network == null) continue;
      //   final networkAddresses = await network.getAccountAddresses();
      //   if (networkAddresses.isErr) {
      //     return networkAddresses.cast();
      //   }
      //   final List<IBitcoinCashAddress> addresses = [];
      //   for (final a in i.accounts) {
      //     final address = networkAddresses.unwrap().firstWhereOrNull((e) =>
      //         e.identifier == a.identifier && e.derivationIndex == a.derivationIndex);
      //     if (address == null) continue;
      //     addresses.add(address.cast<IBitcoinCashAddress>());
      //   }
      //   final defaultAddress = addresses.firstWhereOrNull((e) =>
      //           e.identifier == i.defaultAccount?.identifier &&
      //           e.derivationIndex == i.defaultAccount?.derivationIndex) ??
      //       addresses.firstOrNull;
      //   web3Accounts.addAll(addresses.map((e) =>
      //       Web3BitcoinCashChainAccount.fromChainAccount(
      //           address: e,
      //           network: network.network.cast(),
      //           isDefault: e == defaultAddress)));
      // }
      return ResultOk(Web3BitcoinCashChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }
}
