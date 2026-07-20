part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract class NetworkController<
    ACCOUNT extends ChainAccount,
    T extends APPCHAINACCOUNT<ACCOUNT>,
    WEB3 extends Web3ChainAccount,
    WEB3CHAIN extends Web3InternalChain,
    CONFIG extends ChainConfig> {
  final NetworkType type;
  final ChainStorageManager _storage;

  final Map<int, T> _chains;

  List<T> get web3Networks => _chains.values.where((e) => e.network.supportWeb3).toList();

  NetworkController(
      {List<T> networks = const [],
      required this.type,
      required String id,
      required IAppDatabaseApi database})
      : _chains = {for (final i in networks) i.network.value: i},
        _storage = ChainStorageManager(id: id, networkType: type, database: database);
  static NetworkController fromChains(
      {required NetworkType type,
      required List<Chain> chains,
      required String id,
      required IAppDatabaseApi database}) {
    switch (type) {
      case NetworkType.aptos:
        return AptosNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.bitcoinAndForked:
        return BitcoinNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.bitcoinCash:
        return BitcoinCashNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.ethereum:
        return EthereumNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.zcash:
        return ZcashNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.xrpl:
        return XRPNetworkController(networks: chains.cast(), id: id, database: database);
      case NetworkType.cardano:
        return ADANetworkController(networks: chains.cast(), id: id, database: database);
      case NetworkType.cosmos:
        return CosmosNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.monero:
        return MoneroNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.sui:
        return SuiNetworkController(networks: chains.cast(), id: id, database: database);
      case NetworkType.solana:
        return SolanaNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.stellar:
        return StellarNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.substrate:
        return SubstrateNetworkController(
            networks: chains.cast(), id: id, database: database);
      case NetworkType.tron:
        return TronNetworkController(networks: chains.cast(), id: id, database: database);
      case NetworkType.ton:
        return TonNetworkController(networks: chains.cast(), id: id, database: database);
    }
  }

  List<T> getChains() {
    return _chains.values.toList();
  }

  List<int> getIds() {
    return _chains.keys.toList();
  }

  T? getChain(int id) => _chains[id];

  bool hasChain(Chain chain) {
    return _chains.containsKey(chain.network.value);
  }

  Future<IResult<Web3ChainAuthenticated<WEB3>>> createWeb3ChainAuthenticated(
      Web3ApplicationAuthentication app);

  Future<IResult<void>> updateWeb3InternalChain(
      {required Web3ApplicationAuthentication app, required WEB3CHAIN web3Chain}) async {
    return await _storage.insertChainStorage(
        value: web3Chain, storage: DefaultChainStorageId.web3, key: app.applicationId);
  }

  Future<IResult<void>> disconnectWeb3Chain(Web3ApplicationAuthentication app) async {
    return await _storage.removeChainStorage(
        storage: DefaultChainStorageId.web3, key: app.applicationId);
  }

  Future<IResult<CONFIG>> getConfig() async {
    final data =
        await _storage.queryChainStorageData(storage: DefaultChainStorageId.config);
    return data.map((data) {
      if (data == null) return ChainConfig.create(type).cast<CONFIG>();
      final config = ChainConfig.deserialize(cborBytes: data);
      return config.cast<CONFIG>();
    });
  }

  Future<void> updateConfig(CONFIG config) async {
    await _storage.insertChainStorage(
        storage: DefaultChainStorageId.config, value: config);
  }

  Future<IResult<(T, List<ACCOUNT>)?>> getWeb3AuthenticatedAccounts(
      Web3ApplicationAuthentication app, List<WEB3> web3Accounts) async {
    final internalChain = await getWeb3InternalChainAuthenticated(app);
    return internalChain.andThenAsync((internalChain) async {
      if (web3Accounts.isEmpty) {
        return ResultOk(
            (_chains[internalChain.defaultChain] ?? web3Networks.first, <ACCOUNT>[]));
      }
      final isValidAccounts = web3Accounts.map((e) => e.id).toSet().length == 1;
      if (!isValidAccounts) return ResultOk(null);
      final int networkId = web3Accounts.first.id;
      final network = _chains[networkId];
      final internalNetwork =
          internalChain.networks.firstWhereOrNull((e) => e.networkId == networkId);
      if (network == null || internalNetwork == null) return ResultOk(null);
      final networkAddresses = (await network.getAccountAddresses());
      return networkAddresses.map((networkAddresses) {
        List<ACCOUNT> addresses = [];
        for (final i in web3Accounts) {
          final authAddress = internalNetwork.accounts.firstWhereOrNull((e) =>
              e.identifier == i.identifier && e.derivationIndex == i.derivationIndex);
          final address = networkAddresses.firstWhereOrNull((e) =>
              e.identifier == i.identifier && e.derivationIndex == i.derivationIndex);
          if (address == null || authAddress == null) return null;
          addresses.add(address.cast<ACCOUNT>());
        }
        return (network, addresses);
      });
    });
  }

  Future<IResult<WEB3CHAIN>> getWeb3InternalChainAuthenticated(
      Web3ApplicationAuthentication app) async {
    final web3Networks = this.web3Networks;
    if (web3Networks.isEmpty) {
      return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
    }
    final data = await _storage.queryChainStorageData(
        storage: DefaultChainStorageId.web3, key: app.applicationId);
    return data.map((data) {
      if (data == null) {
        return Web3InternalDefaultChain(
                networks: web3Networks
                    .map((e) => Web3InternalDefaultNetwork(
                        accounts: [], networkId: e.network.value))
                    .toList(),
                defaultChain: web3Networks.first.networkId,
                type: type)
            .cast<WEB3CHAIN>();
      }
      Web3InternalDefaultChain web3Chain =
          Web3InternalDefaultChain.deserialize(bytes: data);
      web3Chain = Web3InternalDefaultChain(
          networks: web3Networks.map((e) {
            final network =
                web3Chain.networks.firstWhereNullable((i) => i.networkId == e.networkId);
            return Web3InternalDefaultNetwork(
                accounts: network?.accounts ?? [],
                networkId: e.networkId,
                defaultAccount: network?.defaultAccount);
          }).toList(),
          defaultChain:
              _chains[web3Chain.defaultChain]?.networkId ?? web3Networks.first.networkId,
          type: type);
      return web3Chain.cast<WEB3CHAIN>();
    });
  }

  Future<IResult<List<WalletNetworkBackup>>> getNetworksBackup(List<Chain> chains) async {
    if (chains.isEmpty) return ResultOk([]);
    final correctChains = chains.where((e) => _chains.containsKey(e.networkId)).toList();
    assert(correctChains.length == chains.length, "invalid backup chains");
    return await IResult.anyError(correctChains.map((e) => e.toBackup()).toList());
  }

  Future<IResult<List<WalletBackupChainRepository>>> getChainBackup(
      {List<Web3ApplicationAuthentication> web3Applications = const []}) async {
    return await _storage.readAllChainRepositories(
        web3Identifier: web3Applications.map((e) => e.applicationId).toList());
  }

  E cast<E extends APPNETWORKCONTROLLER>() {
    if (this is! E) {
      throw AppInternalError.internalError("NetworkController.cast");
    }
    return this as E;
  }
}
