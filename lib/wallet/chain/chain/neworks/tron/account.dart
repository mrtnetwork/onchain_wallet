part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class TronNetworkStorageId extends DefaultNetworkStorageId {
  static const TronNetworkStorageId accountInfo = TronNetworkStorageId(51);
  static const TronNetworkStorageId accountResource = TronNetworkStorageId(52);
  const TronNetworkStorageId(super.storageId);

  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    accountInfo,
    accountResource
  ];
}

final class TronChain extends Chain<
    TronAddress,
    TronToken,
    NFTCore,
    WalletTronNetwork,
    TronWalletTransaction,
    ITronAddress,
    TronClient,
    TronNetworkProvider,
    ITronChainContext> {
  TronChain._(
      {required WalletTronNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            TronMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory TronChain.setup(
      {required WalletTronNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return TronChain._(network: network, id: id, controller: controller);
  }
  factory TronChain.deserialize(
      {required WalletTronNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return TronChain._(network: network, id: id, controller: controller);
  }
}

abstract final class ITronChainContext
    implements
        IChainContext<TronAddress, TronToken, NFTCore, WalletTronNetwork,
            TronWalletTransaction, ITronAddress, TronClient, TronNetworkProvider> {}

final class TronMainChainContext extends DefaultMainChainContext<
    TronAddress,
    TronToken,
    NFTCore,
    WalletTronNetwork,
    TronWalletTransaction,
    ITronAddress,
    TronClient,
    TronNetworkProvider> implements ITronChainContext {
  TronMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  ITronAddress? getAddressSync({String? address, TronAddress? networkAddress}) {
    return super.getAddressSync(address: address, networkAddress: networkAddress) ??
        addresses.firstWhereOrNull((element) => element.baseAddress == address);
  }

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ITronAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync(
        (client) async {
          final tokens = await address.getAccountTokens();
          return tokens.andThenAsync((tokens) async {
            final balance = await client.getAccountInfo(address.networkAddress);
            final accountInfo = balance?.accountInfo;
            final accountResource = balance?.resource;
            final result = await IResult.anyError([
              address._updateAccountInfo(accountInfo),
              address._updateAccountResource_(accountResource),
            ]);
            if (result.isErr) return result.cast();
            final trc20Tokens = tokens.whereType<SolidityToken>().toList();
            final balances = await Future.wait(trc20Tokens.map((e) async {
              return IResult.call(() async => await client.ethClient.getTokenBalance(
                  contract: e.contractAddress, address: address.networkAddress));
            }));
            for (int i = 0; i < trc20Tokens.length; i++) {
              final token = trc20Tokens[i];
              final balance = balances[i];
              if (balance.isErr) continue;
              final result = await address._updateAccountTokenBalance(
                  token as TronToken, () => token._updateBalance(balance.unwrap()));
              if (result.isErr) return result;
            }
            return balances
                .firstWhere((e) => e.isErr, orElse: () => ResultOk(BigInt.zero))
                .map((_) {
              return result.unwrap().any((e) => e);
            });
          });
        },
        logging: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "updateAddressBalanceInternal",
            err: exception,
            trace: trace.toString()),
      );
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ITronAddress address,
      required List<TronToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final trc10Tokens = tokens.where((e) => e.tronTokenType.isTrc10);
        if (trc10Tokens.isNotEmpty) {
          final balance = await client.getAccountInfo(address.networkAddress);
          final accountInfo = balance?.accountInfo;
          final accountResource = balance?.resource;
          final result = await IResult.anyError([
            address._updateAccountInfo(accountInfo),
            address._updateAccountResource_(accountResource),
            ...trc10Tokens.map((t) {
              final balance =
                  accountInfo?.assetV2.firstWhereNullable((e) => t.issuer == e.key);
              return address._updateAccountTokenBalance(
                  t, () => t._updateBalance(balance?.value ?? BigInt.zero));
            })
          ]);
          if (result.isErr) return result;
        }
        final trc20Tokens = tokens.whereType<SolidityToken>().toList();
        final balances = await Future.wait(trc20Tokens.map((e) async {
          return IResult.call(() async => await client.ethClient.getTokenBalance(
              contract: e.contractAddress, address: address.networkAddress));
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
  IResult<TronNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<TronNetworkProvider> exclude = const []}) {
    final node = providers.where((e) => e.service == APIProviderServices.tron).toList();
    final solidity =
        providers.where((e) => e.service == APIProviderServices.ethereumJsonRpc).toList();
    for (final n in node) {
      for (final e in solidity) {
        final identifier = TronNetworkProvider(node: n, ethereum: e);
        if (exclude.contains(identifier)) continue;
        return ResultOk(identifier);
      }
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.allOf(
      {APIProviderServices.tron, APIProviderServices.ethereumJsonRpc});
}
