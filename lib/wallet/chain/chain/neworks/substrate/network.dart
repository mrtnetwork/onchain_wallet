part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class SubstrateChainConfig extends ChainConfig {
  final bool acceptMultisigTerm;
  final bool acceptXcmTransferTerm;
  const SubstrateChainConfig(
      {this.acceptMultisigTerm = false, this.acceptXcmTransferTerm = false});
  factory SubstrateChainConfig.deserialize(
      {List<int>? cborBytes, CborObject? cborObject}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: cborBytes,
        cborObject: cborObject,
        identifier: NetworkType.substrate.identifier);
    return SubstrateChainConfig(
      acceptMultisigTerm: values.rawValueAt(0),
      acceptXcmTransferTerm: values.rawValueAt(1),
    );
  }
  SubstrateChainConfig copyWith({bool? acceptMultisigTerm, bool? acceptXcmTransferTerm}) {
    return SubstrateChainConfig(
        acceptMultisigTerm: acceptMultisigTerm ?? this.acceptMultisigTerm,
        acceptXcmTransferTerm: acceptXcmTransferTerm ?? this.acceptXcmTransferTerm);
  }

  @override
  NetworkType get network => NetworkType.substrate;
  @override
  List<CborObject?> get serializationItems => [
        CborBoleanValue(acceptMultisigTerm),
        CborBoleanValue(acceptXcmTransferTerm),
      ];
}

class SubstrateNetworkController extends NetworkController<
    ISubstrateAddress,
    SubstrateChain,
    Web3SubstrateChainAccount,
    Web3InternalDefaultChain,
    SubstrateChainConfig> {
  SubstrateNetworkController({super.networks, required super.id, required super.database})
      : super(type: NetworkType.substrate);

  @override
  Future<IResult<Web3SubstrateChainAuthenticated>> createWeb3ChainAuthenticated(
    Web3ApplicationAuthentication app,
  ) async {
    final internalNetwork = await getWeb3InternalChainAuthenticated(app);
    return internalNetwork.andThenAsync((internalNetwork) async {
      final web3Networks = this
          .web3Networks
          .map((e) => Web3SubstrateChainIdnetifier(
              genesisHash: e.network.genesisBlock,
              specVersion: e.network.coinParam.specVersion,
              id: e.network.value,
              wsIdentifier: e.network.wsIdentifier,
              caip2: e.network.caip,
              type: e.network.coinParam.substrateChainType,
              ss58Fromat: e.network.coinParam.ss58Format))
          .toList();
      List<Web3SubstrateChainAccount> web3Accounts = [];
      for (final i in internalNetwork.networks) {
        final network = _chains[i.networkId];
        if (network == null) continue;
        final networkAddresses = await network.getAccountAddresses();
        if (networkAddresses.isErr) {
          return networkAddresses.cast();
        }
        final List<ISubstrateAddress> addresses = [];
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
        web3Accounts.addAll(addresses.map((e) =>
            Web3SubstrateChainAccount.fromChainAccount(
                address: e, isDefault: e == defaultAddress, id: e.network.value)));
      }
      return ResultOk(Web3SubstrateChainAuthenticated(
          accounts: web3Accounts,
          currentNetwork:
              web3Networks.firstWhere((e) => e.id == internalNetwork.defaultChain),
          networks: web3Networks));
    });
  }
}
