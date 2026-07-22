part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class EthereumChain extends Chain<
    ETHAddress,
    ETHERC20Token,
    NFTCore,
    WalletEthereumNetwork,
    EthWalletTransaction,
    IEthereumAddress,
    EthereumNetworkClient,
    EthereumNetworkProvider,
    IEthereumChainContext> {
  EthereumChain._(
      {required WalletEthereumNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            EthereumMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory EthereumChain.setup(
      {required WalletEthereumNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return EthereumChain._(network: network, id: id, controller: controller);
  }

  factory EthereumChain.deserialize(
      {required WalletEthereumNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return EthereumChain._(network: network, id: id, controller: controller);
  }

  late final BigInt chainId = network.coinParam.chainId;

  Future<IResult<BigInt>> getErc20TokenBalance(
          {required IEthereumAddress address, required ETHAddress contract}) =>
      _context.getErc20TokenBalance(address: address, contract: contract);
}

abstract final class IEthereumChainContext
    implements
        IChainContext<
            ETHAddress,
            ETHERC20Token,
            NFTCore,
            WalletEthereumNetwork,
            EthWalletTransaction,
            IEthereumAddress,
            EthereumNetworkClient,
            EthereumNetworkProvider> {
  Future<IResult<BigInt>> getErc20TokenBalance(
      {required IEthereumAddress address, required ETHAddress contract});
}

final class EthereumMainChainContext extends DefaultMainChainContext<
    ETHAddress,
    ETHERC20Token,
    NFTCore,
    WalletEthereumNetwork,
    EthWalletTransaction,
    IEthereumAddress,
    EthereumNetworkClient,
    EthereumNetworkProvider> implements IEthereumChainContext {
  EthereumMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IEthereumAddress address,
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
              return IResult.call(() async => await client.getTokenBalance(
                  address: address.networkAddress, contract: e.contractAddress));
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
        return ResultOk(updateBalance.unwrap());
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IEthereumAddress address,
      required List<ETHERC20Token> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balances = await Future.wait(tokens.map((e) async {
          return IResult.call(() async => await client.getTokenBalance(
              address: address.networkAddress, contract: e.contractAddress));
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
  Future<IResult<BigInt>> getErc20TokenBalance(
      {required IEthereumAddress address, required ETHAddress contract}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final tokens = await address.getAccountTokens();
      return tokens.andThenAsync((tokens) async {
        final wToken = tokens.firstWhereOrNull((e) => e.contractAddress == contract);
        if (wToken == null) {
          final client = await this.client();
          return client.andThenCatchAsync((client) async {
            final balance = await client.getTokenBalance(
                address: address.networkAddress, contract: contract);
            return ResultOk(balance);
          });
        }
        final update = await updateTokenBalance(address: address, tokens: [wToken]);
        return update.map((e) => wToken.balance.balance);
      });
    });
  }

  @override
  IResult<EthereumNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<EthereumNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = EthereumNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.ethereumJsonRpc});
}
