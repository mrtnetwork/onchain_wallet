part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class SuiChain extends Chain<
    SuiAddress,
    SuiToken,
    NFTCore,
    WalletSuiNetwork,
    SuiWalletTransaction,
    ISuiAddress,
    SuiNetworkClient,
    SuiNetworkProvider,
    ISuiChainContext> {
  SuiChain._(
      {required WalletSuiNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            SuiMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory SuiChain.setup(
      {required WalletSuiNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return SuiChain._(network: network, id: id, controller: controller);
  }

  factory SuiChain.deserialize(
      {required WalletSuiNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return SuiChain._(network: network, id: id, controller: controller);
  }
}

abstract final class ISuiChainContext
    implements
        IChainContext<SuiAddress, SuiToken, NFTCore, WalletSuiNetwork,
            SuiWalletTransaction, ISuiAddress, SuiNetworkClient, SuiNetworkProvider> {}

final class SuiMainChainContext extends DefaultMainChainContext<
    SuiAddress,
    SuiToken,
    NFTCore,
    WalletSuiNetwork,
    SuiWalletTransaction,
    ISuiAddress,
    SuiNetworkClient,
    SuiNetworkProvider> implements ISuiChainContext {
  SuiMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ISuiAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balance = await client.getAcountBalances(address.networkAddress);
        final native = balance
            .firstWhereOrNull((e) => e.coinType == SuiTransactionConst.suiTypeArgs);
        final updateBalance =
            await address._updateAccountBalance(native?.totalBalance ?? BigInt.zero);
        if (updateBalance.isErr) return updateBalance;
        final tokens = await address.getAccountTokens();
        return tokens.andThenAsync((tokens) async {
          for (final token in tokens) {
            final asset = balance.firstWhereOrNull((e) => e.coinType == token.assetType);
            final result = await address._updateAccountTokenBalance(
                token, () => token._updateBalance(asset?.totalBalance ?? BigInt.zero));
            if (result.isErr) return result;
          }
          return updateBalance;
        });
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ISuiAddress address,
      required List<SuiToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balance = await client.getAcountBalances(address.networkAddress);
        final native = balance
            .firstWhereOrNull((e) => e.coinType == SuiTransactionConst.suiTypeArgs);
        final updateBalance =
            await address._updateAccountBalance(native?.totalBalance ?? BigInt.zero);
        if (updateBalance.isErr) return updateBalance;
        for (final token in tokens) {
          final asset = balance.firstWhereOrNull((e) => e.coinType == token.assetType);
          final result = await address._updateAccountTokenBalance(
              token, () => token._updateBalance(asset?.totalBalance ?? BigInt.zero));
          if (result.isErr) return result;
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  IResult<SuiNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<SuiNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = SuiNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.oneOf({APIProviderServices.sui});
}
