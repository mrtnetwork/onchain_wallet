part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class StellarChain extends Chain<
    StellarAddress,
    StellarIssueToken,
    NFTCore,
    WalletStellarNetwork,
    StellarWalletTransaction,
    IStellarAddress,
    StellarClient,
    StellarNetworkProvider,
    IStellarChainContext> {
  StellarChain._(
      {required WalletStellarNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            StellarMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory StellarChain.setup(
      {required WalletStellarNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return StellarChain._(network: network, id: id, controller: controller);
  }

  factory StellarChain.deserialize(
      {required WalletStellarNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return StellarChain._(network: network, id: id, controller: controller);
  }
}

abstract final class IStellarChainContext
    implements
        IChainContext<
            StellarAddress,
            StellarIssueToken,
            NFTCore,
            WalletStellarNetwork,
            StellarWalletTransaction,
            IStellarAddress,
            StellarClient,
            StellarNetworkProvider> {}

final class StellarMainChainContext extends DefaultMainChainContext<
    StellarAddress,
    StellarIssueToken,
    NFTCore,
    WalletStellarNetwork,
    StellarWalletTransaction,
    IStellarAddress,
    StellarClient,
    StellarNetworkProvider> implements IStellarChainContext {
  StellarMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IStellarAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final accountInfo = await client.getAccount(address.networkAddress);
        final balance = accountInfo?.balances
                .whereType<StellarNativeBalanceResponse>()
                .fold(BigInt.zero, (p, c) => p + c.unlockedBalance) ??
            BigInt.zero;
        final updateBalance = await address._updateAccountBalance(balance);
        if (updateBalance.isErr) return updateBalance;
        final tokens = await address.getAccountTokens();
        return tokens.andThenAsync((tokens) async {
          for (final i in tokens) {
            final balance = accountInfo?.getAssetByIssueAsset(i);
            final result = await address._updateAccountTokenBalance(
                i, () => i._updateBalance(balance?.unlockedBalance ?? BigInt.zero));
            if (result.isErr) return result;
          }
          return updateBalance;
        });
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IStellarAddress address,
      required List<StellarIssueToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final accountInfo = await client.getAccount(address.networkAddress);
        final balance = accountInfo?.balances
                .whereType<StellarNativeBalanceResponse>()
                .fold(BigInt.zero, (p, c) => p + c.unlockedBalance) ??
            BigInt.zero;
        final updateBalance = await address._updateAccountBalance(balance);
        if (updateBalance.isErr) return updateBalance;
        for (final i in tokens) {
          final balance = accountInfo?.getAssetByIssueAsset(i);
          final result = await address._updateAccountTokenBalance(
              i, () => i._updateBalance(balance?.unlockedBalance ?? BigInt.zero));
          if (result.isErr) return result;
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  IResult<StellarNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<StellarNetworkProvider> exclude = const []}) {
    final horizon =
        providers.where((e) => e.service == APIProviderServices.horizon).toList();
    final soroban =
        providers.where((e) => e.service == APIProviderServices.stellarRpc).toList();
    for (final h in horizon) {
      for (final s in soroban) {
        final identifier = StellarNetworkProvider(horizon: h, soroban: s);
        if (exclude.contains(identifier)) continue;
        return ResultOk(identifier);
      }
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.allOf(
      {APIProviderServices.horizon, APIProviderServices.stellarRpc});
}
