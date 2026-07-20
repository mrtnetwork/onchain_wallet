part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class TonChain extends Chain<
    TonAddress,
    TonJettonToken,
    NFTCore,
    WalletTonNetwork,
    TonWalletTransaction,
    ITonAddress,
    TonNetworkClient,
    TonNetworkProvider,
    ITonChainContext> {
  TonChain._(
      {required WalletTonNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            TonMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory TonChain.setup(
      {required WalletTonNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return TonChain._(network: network, id: id, controller: controller);
  }

  factory TonChain.deserialize(
      {required WalletTonNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return TonChain._(network: network, id: id, controller: controller);
  }
}

abstract final class ITonChainContext
    implements
        IChainContext<TonAddress, TonJettonToken, NFTCore, WalletTonNetwork,
            TonWalletTransaction, ITonAddress, TonNetworkClient, TonNetworkProvider> {}

final class TonMainChainContext extends DefaultMainChainContext<
    TonAddress,
    TonJettonToken,
    NFTCore,
    WalletTonNetwork,
    TonWalletTransaction,
    ITonAddress,
    TonNetworkClient,
    TonNetworkProvider> implements ITonChainContext {
  TonMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ITonAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balance = await client.getAccountBalance(address.networkAddress);
        final updateBalance = await address._updateAccountBalance(balance);
        if (updateBalance.isErr) return updateBalance;
        if (tokens) {
          final tokens = await address.getAccountTokens();
          return tokens.andThenAsync((tokens) async {
            final balances = await Future.wait(tokens.map((e) async {
              return IResult.call(() async =>
                  (await client.getJettonWalletData(e.walletAddress)).balance);
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
      {required ITonAddress address,
      required List<TonJettonToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balances = await Future.wait(tokens.map((e) async {
          return IResult.call(
              () async => (await client.getJettonWalletData(e.walletAddress)).balance);
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
  IResult<TonNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<TonNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = TonNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.oneOf(
      {APIProviderServices.tonApi, APIProviderServices.tonCenter});
}
