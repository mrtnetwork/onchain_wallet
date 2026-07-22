part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class SolanaChain extends Chain<
    SolAddress,
    SolanaSPLToken,
    NFTCore,
    WalletSolanaNetwork,
    SolanaWalletTransaction,
    ISolanaAddress,
    SolanaNetworkClient,
    SolanaNetworkProvider,
    ISolanaChainContext> {
  SolanaChain._(
      {required WalletSolanaNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            SolanaMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory SolanaChain.setup(
      {required WalletSolanaNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return SolanaChain._(network: network, id: id, controller: controller);
  }

  factory SolanaChain.deserialize(
      {required WalletSolanaNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return SolanaChain._(network: network, id: id, controller: controller);
  }
  Future<IResult<BigInt>> getSplTokenBalance(
          {required ISolanaAddress address, required SolAddress mint}) =>
      _context.getSplTokenBalance(address: address, mint: mint);
}

abstract final class ISolanaChainContext
    implements
        IChainContext<
            SolAddress,
            SolanaSPLToken,
            NFTCore,
            WalletSolanaNetwork,
            SolanaWalletTransaction,
            ISolanaAddress,
            SolanaNetworkClient,
            SolanaNetworkProvider> {
  Future<IResult<BigInt>> getSplTokenBalance(
      {required ISolanaAddress address, required SolAddress mint});
}

final class SolanaMainChainContext extends DefaultMainChainContext<
    SolAddress,
    SolanaSPLToken,
    NFTCore,
    WalletSolanaNetwork,
    SolanaWalletTransaction,
    ISolanaAddress,
    SolanaNetworkClient,
    SolanaNetworkProvider> implements ISolanaChainContext {
  SolanaMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ISolanaAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balance = await client.getBalance(address.networkAddress);
        final updateBalance = await address._updateAccountBalance(balance);
        if (updateBalance.isErr) return updateBalance;
        if (tokens) {
          final tokens = await address.getAccountTokens();
          return tokens.andThenAsync((tokens) async {
            final balances = await Future.wait(tokens.map((e) async {
              return IResult.call(
                  () async => await client.getTokenAddressBalance(e.tokenAccount));
            }));
            for (int i = 0; i < tokens.length; i++) {
              final token = tokens[i];
              final balance = balances[i];
              if (balance.isErr) continue;
              final result = await address._updateAccountTokenBalance(
                  token, () => token._updateBalance(balance.unwrap()));
              if (result.isErr) return result;
            }
            return balances
                .firstWhere((e) => e.isErr, orElse: () => ResultOk(BigInt.zero))
                .map((_) {
              return updateBalance.unwrap();
            });
          });
        }
        return updateBalance;
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ISolanaAddress address,
      required List<SolanaSPLToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balances = await Future.wait(tokens.map((e) async {
          return IResult.call(
              () async => await client.getTokenAddressBalance(e.tokenAccount));
        }));
        for (int i = 0; i < tokens.length; i++) {
          final token = tokens[i];
          final balance = balances[i];
          if (balance.isErr) continue;
          final result = await address._updateAccountTokenBalance(
              token, () => token._updateBalance(balance.unwrap()));
          if (result.isErr) return result;
        }
        return balances
            .firstWhere((e) => e.isErr, orElse: () => ResultOk(BigInt.zero))
            .map((_) {});
      });
    });
  }

  @override
  IResult<SolanaNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<SolanaNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = SolanaNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.solanaJsonRpc});

  @override
  Future<IResult<BigInt>> getSplTokenBalance(
      {required ISolanaAddress address, required SolAddress mint}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final tokens = await address.getAccountTokens();
      return tokens.andThenAsync((tokens) async {
        final wToken = tokens.firstWhereOrNull((e) => e.mint == mint);
        if (wToken == null) {
          final client = await this.client();
          return client.andThenCatchAsync((client) async {
            final balance =
                await client.getTokenBalance(account: address.networkAddress, mint: mint);
            return ResultOk(balance);
          });
        }
        final update = await updateTokenBalance(address: address, tokens: [wToken]);
        return update.map((e) => wToken.balance.balance);
      });
    });
  }
}
