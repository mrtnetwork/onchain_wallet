part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class ADANetworkController extends NetworkController<ICardanoAddress, ADAChain,
    Web3ADAChainAccount, Web3InternalADAChain, ChainConfig> {
  ADANetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.cardano);

  @override
  Future<IResult<(ADAChain, List<ICardanoAddress>)?>> getWeb3AuthenticatedAccounts(
      Web3ApplicationAuthentication app, List<Web3ADAChainAccount> web3Accounts) async {
    final internalChain = await getWeb3InternalChainAuthenticated(app);
    return internalChain.andThenAsync((internalChain) async {
      if (web3Accounts.isEmpty) {
        return ResultOk((
          _chains[internalChain.defaultChain] ?? web3Networks.first,
          <ICardanoAddress>[]
        ));
      }
      final isValidAccounts = web3Accounts.map((e) => e.id).toSet().length == 1;
      if (!isValidAccounts) return ResultOk(null);
      final int networkId = web3Accounts.first.id;
      final network = _chains[networkId];
      final internalNetwork =
          internalChain.networks.firstWhereOrNull((e) => e.networkId == networkId);
      if (network == null || internalNetwork == null) return ResultOk(null);
      final networkAddresses = await network.getAccountAddresses();
      return networkAddresses.map((networkAddresses) {
        List<ICardanoAddress> addresses = [];
        for (final i in web3Accounts) {
          final authAddress = internalNetwork.accounts.firstWhereOrNull((e) =>
              e.identifier == i.identifier &&
              e.derivationIndex == i.derivationIndex &&
              e.type.isReward == i.isRewardAddress);
          ICardanoAddress? address = switch (i.isRewardAddress) {
            false => networkAddresses.firstWhereOrNull((e) =>
                e.identifier == i.identifier &&
                e.derivationIndex == i.derivationIndex &&
                !e.isRewardAddress),
            true => networkAddresses.firstWhereOrNull((e) =>
                e.identifier == i.identifier &&
                (e.rewardKeyIndex ?? e.derivationIndex) == i.derivationIndex &&
                (e.isRewardAddress || e.isBaseAddress))
          };
          if (address == null || authAddress == null) return null;
          addresses.add(address.cast<ICardanoAddress>());
        }
        return (network, addresses);
      });
    });
  }

  @override
  Future<IResult<Web3InternalADAChain>> getWeb3InternalChainAuthenticated(
      Web3ApplicationAuthentication app) async {
    final web3Networks = this.web3Networks;
    if (web3Networks.isEmpty) {
      return ResultErr.fromException(WalletExceptionConst.unsuportedFeature);
    }
    final data = await _storage.queryChainStorageData(
        storage: DefaultChainStorageId.web3, key: app.applicationId);
    return data.map((data) {
      if (data == null) {
        return Web3InternalADAChain(
          networks: web3Networks
              .map((e) => Web3InternalADANetwork(accounts: [], networkId: e.networkId))
              .toList(),
          defaultChain: web3Networks.first.networkId,
        );
      }
      Web3InternalADAChain web3Chain = Web3InternalADAChain.deserialize(bytes: data);
      web3Chain = Web3InternalADAChain(
          networks: web3Networks.map((e) {
            final network =
                web3Chain.networks.firstWhereNullable((i) => i.networkId == e.networkId);
            return Web3InternalADANetwork(
                accounts: network?.accounts ?? [],
                networkId: e.networkId,
                defaultAccount: network?.defaultAccount);
          }).toList(),
          defaultChain:
              _chains[web3Chain.defaultChain]?.networkId ?? web3Networks.first.networkId);
      return web3Chain;
    });
  }

  @override
  Future<IResult<Web3ADAChainAuthenticated>> createWeb3ChainAuthenticated(
      Web3ApplicationAuthentication app) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3ADAChainIdnetifier(
              id: e.networkId,
              wsIdentifier: e.network.wsIdentifier,
              caip2: e.network.caip,
              network: e.network.coinParam.networkType))
          .toList();
      List<Web3ADAChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];
        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) {
          return networkAddresses.cast();
        }
        final List<ICardanoAddress> addresses = [];
        final List<ICardanoAddress> rewardAddress = [];
        for (final a in i.accounts) {
          ICardanoAddress? address;
          if (a.type.isPayment) {
            address = networkAddresses.unwrap().firstWhereOrNull((e) =>
                e.identifier == a.identifier &&
                !e.isRewardAddress &&
                e.derivationIndex == a.derivationIndex);
            if (address == null) continue;
            addresses.add(address);
          } else {
            address = networkAddresses.unwrap().firstWhereOrNull((e) =>
                e.identifier == a.identifier &&
                (e.rewardKeyIndex ?? e.derivationIndex) == a.derivationIndex &&
                (e.isRewardAddress || e.isBaseAddress));
            if (address == null) continue;
            rewardAddress.add(address);
          }
        }
        final defaultAddress = addresses.firstWhereOrNull((e) =>
                e.identifier == i.defaultAccount?.identifier &&
                e.derivationIndex == i.defaultAccount?.derivationIndex &&
                !e.isRewardAddress) ??
            addresses.firstOrNull;
        web3Accounts.addAll(await Future.wait(addresses.map((e) async {
          final utxos = await network.getAccountTransactionUnspentOutputs(e);
          // final utxos = await switch (context.isBackgroundScript) {
          //   false => network.getAccountLatestTransactionUnspentOutputs(e),
          //   true => network.getAccountTransactionUnspentOutputs(e)
          // };
          return Web3ADAChainAccount.fromChainAccount(
              address: e,
              id: network.networkId,
              isDefault: e == defaultAddress,
              isRewardAddress: false,
              utxos: utxos.unwrapOr((_) => <TransactionUnspentOutput>[])
              // utxos: switch (context.isBackgroundScript) {
              //   false => utxos.unwrapOr((_) => <TransactionUnspentOutput>[]),
              //   true => utxos.unwrapOr((_) => <TransactionUnspentOutput>[])
              // },
              );
        })));
        web3Accounts.addAll(rewardAddress.map((e) => Web3ADAChainAccount.fromChainAccount(
            address: e,
            id: network.networkId,
            isDefault: false,
            isRewardAddress: true,
            utxos: [])));
      }

      return ResultOk(Web3ADAChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }
}
