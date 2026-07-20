part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class CosmosNetowkStorageId extends DefaultNetworkStorageId {
  static const CosmosNetowkStorageId channelIds = CosmosNetowkStorageId(51);
  const CosmosNetowkStorageId(super.storageId);
  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    channelIds
  ];
}

final class CosmosChain extends Chain<
    CosmosBaseAddress,
    CW20Token,
    NFTCore,
    WalletCosmosNetwork,
    CosmosWalletTransaction,
    ICosmosAddress,
    CosmosNetworkClient,
    CosmosNetworkProvider,
    ICosmosChainContext> {
  CosmosChain._(
      {required WalletCosmosNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            CosmosMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory CosmosChain.setup(
      {required WalletCosmosNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return CosmosChain._(network: network, id: id, controller: controller);
  }
  factory CosmosChain.deserialize(
      {required WalletCosmosNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return CosmosChain._(network: network, id: id, controller: controller);
  }

  Future<IResult<CosmosAccountIBCChannelIds>> getIbcChannelIds() {
    return _context.getIbcChannelIds();
  }

  Future<IResult<void>> addNewIbcChannel(CosmosIBCChannelId channel) {
    return _context.addNewIbcChannel(channel);
  }
}

abstract final class ICosmosChainContext
    implements
        IChainContext<
            CosmosBaseAddress,
            CW20Token,
            NFTCore,
            WalletCosmosNetwork,
            CosmosWalletTransaction,
            ICosmosAddress,
            CosmosNetworkClient,
            CosmosNetworkProvider> {
  Future<IResult<CosmosAccountIBCChannelIds>> getIbcChannelIds();
  Future<IResult<void>> addNewIbcChannel(CosmosIBCChannelId channel);

  /// storages
  Future<IResult<void>> storageSaveIbcChannelIds(CosmosAccountIBCChannelIds channelIds);
  Future<IResult<CosmosAccountIBCChannelIds>> storageGetIbcChannelIds();
}

final class CosmosMainChainContext extends DefaultMainChainContext<
    CosmosBaseAddress,
    CW20Token,
    NFTCore,
    WalletCosmosNetwork,
    CosmosWalletTransaction,
    ICosmosAddress,
    CosmosNetworkClient,
    CosmosNetworkProvider> implements ICosmosChainContext {
  CosmosMainChainContext(
      {required super.id, required super.controller, required super.network});
  OnceRunnerWithData<CosmosAccountIBCChannelIds> channelIdsRunner = OnceRunnerWithData();

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ICosmosAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balances = await client.getAddressCoins(address.networkAddress);
        final nativeToken =
            balances.firstWhereOrNull((e) => e.denom == network.coinParam.denom);
        final updateBalance =
            await address._updateAccountBalance(nativeToken?.getAmount() ?? BigInt.zero);
        if (updateBalance.isErr) return updateBalance;
        bool changed = updateBalance.unwrap();
        final tokens = await address.getAccountTokens();
        return tokens.andThenAsync((tokens) async {
          for (final i in tokens) {
            final balance = balances.firstWhereOrNull((e) => e.denom == i.denom);
            final result = await address._updateAccountTokenBalance(
                i, () => i._updateBalance(balance?.getAmount() ?? BigInt.zero));
            if (result.isErr) {
              return result.map((_) {
                return changed;
              });
            }
          }
          return ResultOk(changed);
        });
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ICosmosAddress address,
      required List<CW20Token> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenAsync((client) async {
        final balances = await client.getAddressCoins(address.networkAddress);
        final nativeToken =
            balances.firstWhereOrNull((e) => e.denom == network.coinParam.denom);
        final updateBalance =
            await address._updateAccountBalance(nativeToken?.getAmount() ?? BigInt.zero);
        if (updateBalance.isErr) return updateBalance;
        for (final i in tokens) {
          final balance = balances.firstWhereOrNull((e) => e.denom == i.denom);
          final result = await address._updateAccountTokenBalance(
              i, () => i._updateBalance(balance?.getAmount() ?? BigInt.zero));
          if (result.isErr) return result.map((_) {});
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<CosmosAccountIBCChannelIds>> getIbcChannelIds() {
    return channelIdsRunner.get(onFetch: storageGetIbcChannelIds);
  }

  @override
  IResult<CosmosNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<CosmosNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = CosmosNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  Future<IResult<void>> addNewIbcChannel(CosmosIBCChannelId channel) async {
    return callSync(
        fn: () async {
          final ids = await getIbcChannelIds();
          return ids.andThenAsync((ids) {
            ids.addChannel(channel);
            return storageSaveIbcChannelIds(ids);
          });
        },
        lockId: LockId.five,
        type: null);
  }

  /// storages

  @override
  Future<IResult<void>> storageSaveIbcChannelIds(
      CosmosAccountIBCChannelIds channelIds) async {
    final storagekey = CosmosNetowkStorageId.channelIds;
    return await storage.insertNetworkStorage(storage: storagekey, value: channelIds);
  }

  @override
  Future<IResult<CosmosAccountIBCChannelIds>> storageGetIbcChannelIds() async {
    final storagekey = CosmosNetowkStorageId.channelIds;
    final data = await storage.queryNetworkStorage(storage: storagekey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(CosmosAccountIBCChannelIds());
      final result = IResult.callSync(
        () => CosmosAccountIBCChannelIds.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetIbcChannelIds",
            err: exception,
            trace: trace.toString()),
      );
      return result
          .and((channels, _) => ResultOk(channels ?? CosmosAccountIBCChannelIds()));
    });
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.oneOf({
    APIProviderServices.tendermint,
    APIProviderServices.cosmosRest,
    APIProviderServices.cosmosGrpc
  });
}
