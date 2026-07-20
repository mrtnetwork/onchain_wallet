part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class AptosChain extends Chain<
    AptosAddress,
    AptosFATokens,
    NFTCore,
    WalletAptosNetwork,
    AptosWalletTransaction,
    IAptosAddress,
    AptosNetworkClient,
    AptosNetworkProvider,
    IAptosChainContext> {
  AptosChain._(
      {required WalletAptosNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            AptosMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory AptosChain.setup(
      {required WalletAptosNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return AptosChain._(network: network, controller: controller, id: id);
  }

  factory AptosChain.deserialize({
    required WalletAptosNetwork network,
    required CborListValue cbor,
    required InChainWalletController controller,
  }) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return AptosChain._(network: network, id: id, controller: controller);
  }
}

abstract final class IAptosChainContext
    implements
        IChainContext<
            AptosAddress,
            AptosFATokens,
            NFTCore,
            WalletAptosNetwork,
            AptosWalletTransaction,
            IAptosAddress,
            AptosNetworkClient,
            AptosNetworkProvider> {}

final class AptosMainChainContext extends DefaultMainChainContext<
    AptosAddress,
    AptosFATokens,
    NFTCore,
    WalletAptosNetwork,
    AptosWalletTransaction,
    IAptosAddress,
    AptosNetworkClient,
    AptosNetworkProvider> implements IAptosChainContext {
  AptosMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IAptosAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    final client = await accountAddress.andThenAsync((e) async => await this.client());
    return client.andThenCatchAsync((client) async {
      final balance = await client.getAccountBalance(address.networkAddress);
      final updateBalance = await address._updateAccountBalance(balance);
      if (updateBalance.isErr) return updateBalance;
      bool changed = updateBalance.unwrap();
      if (tokens) {
        final accountTokens = await address.getAccountTokens();
        return accountTokens.andThenCatchAsync((tokens) async {
          final tokenbalances = await client.getAccountTokenBalances(
              address: address.networkAddress,
              assetTypes: tokens.map((e) => e.assetType).toList());
          for (final token in tokens) {
            final balance =
                tokenbalances.firstWhereOrNull((e) => e.assetType == token.assetType);
            final result = await address._updateAccountTokenBalance(token, () {
              changed = token._updateBalance(balance?.balance ?? BigInt.zero);
              changed |= token.setFreeze(balance?.frozen ?? false);
              return changed;
            });
            if (result.isErr) {
              return result.map((_) {
                return changed;
              });
            }
          }
          return ResultOk(changed);
        });
      }
      return ResultOk(changed);
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IAptosAddress address,
      required List<AptosFATokens> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    final client = await accountAddress.andThenAsync((e) async => await this.client());
    return client.andThenCatchAsync((client) async {
      final tokenbalances = await client.getAccountTokenBalances(
          address: address.networkAddress,
          assetTypes: tokens.map((e) => e.assetType).toList());
      for (final token in tokens) {
        final balance =
            tokenbalances.firstWhereOrNull((e) => e.assetType == token.assetType);
        final result = await address._updateAccountTokenBalance(token, () {
          bool changed = token._updateBalance(balance?.balance ?? BigInt.zero);
          changed |= token.setFreeze(balance?.frozen ?? false);
          return changed;
        });
        if (result.isErr) return result.map((_) {});
      }
      return ResultOk.okVoid;
    });
  }

  @override
  IResult<AptosNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<AptosNetworkProvider> exclude = const []}) {
    final graphQlProviders =
        providers.where((e) => e.service == APIProviderServices.graphQl).toList();
    final fullNode =
        providers.where((e) => e.service == APIProviderServices.aptos).toList();
    for (final i in fullNode) {
      for (final g in graphQlProviders) {
        final identifier = AptosNetworkProvider(fullNode: i, graphQl: g);
        if (exclude.contains(identifier)) continue;
        return ResultOk(identifier);
      }
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.allOf(
      {APIProviderServices.aptos, APIProviderServices.graphQl});
}
