part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class IBitcoinChainContext
    implements
        IChainContext<
            BitcoinNetworkAddress,
            TokenCore,
            NFTCore,
            WalletBitcoinNetwork,
            BitcoinWalletTransaction,
            IBitcoinAddress,
            BitcoinNetworkClient,
            BitcoinNetworkProvider> {
  Future<IResult<BitcoinUtxosWithAccountInfo>> getAccountUtxos(IBitcoinAddress address,
      {bool includeTokens = true});

  BitcoinNetworkAddress? findAddressFromScriptSync(Script script);
}

final class BitcoinMainChainContext extends DefaultMainChainContext<
    BitcoinNetworkAddress,
    TokenCore,
    NFTCore,
    WalletBitcoinNetwork,
    BitcoinWalletTransaction,
    IBitcoinAddress,
    BitcoinNetworkClient,
    BitcoinNetworkProvider> implements IBitcoinChainContext {
  final Map<IBitcoinAddress, OnceRunnerResult<void>> utxos = {};
  BitcoinMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<BitcoinUtxosWithAccountInfo>> getAccountUtxos(IBitcoinAddress address,
      {bool includeTokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    final addressDetails = address.toUtxoRequest;
    final client = await accountAddress.andThenAsync((e) async => await this.client());
    await client.andThenCatchAsync(
      (client) async {
        utxos[address] ??= OnceRunnerResult();
        final cachedUtxos = utxos[address]!;
        return await cachedUtxos.get(
            cachedTimeout: Duration(seconds: network.coinParam.averageBlockTime),
            onFetch: () async {
              Set<BitcoinUtxoWithSpendingInfo> existsUtxos =
                  (await address._getAccountUtxos()).unwrap();
              final utxos = await client.readAddressUtxos(
                address: address.toUtxoRequest,
                includeTokens: includeTokens && network.coinParam.isBCH,
                existsUtxos: existsUtxos.map((e) => e.utxo).toList(),
              );
              final result = await address._updateAccountUtxo(utxos.utxos.map((e) {
                return BitcoinUtxoWithSpendingInfo.unconfirmed(e.utxo);
              }).toList());
              return result.andThenAsync((_) async {
                final controller = await address._getAccountTransactionsController();
                return controller.andThenAsync((controller) async {
                  final Set<String> newTxes =
                      utxos.utxos.map((e) => e.utxo.txHash).toSet();
                  final scriptHash = address.networkAddress.pubKeyHash();
                  for (final i in newTxes) {
                    if (controller.byTxId(i, types: [WalletTransactionType.receive]) !=
                        null) {
                      continue;
                    }
                    final tx =
                        utxos.fetchedTransaction[i] ??= await client.getVervoseTx(i);
                    final addressUtxos =
                        utxos.utxos.where((e) => e.utxo.txHash == i).toList();
                    if (addressUtxos.isEmpty) continue;

                    final time = tx.time;
                    final walletTx = BitcoinWalletTransaction(
                        txId: i,
                        time: time == null
                            ? DateTime.now()
                            : DateTimeUtils.detectEpochUnit(time),
                        outputs: [],
                        type: WalletTransactionType.receive,
                        scriptHash: scriptHash,
                        status: WalletTransactionStatus.block,
                        totalOutput: WalletTransactionIntegerAmount(
                            amount: addressUtxos.fold(
                                BigInt.zero, (p, c) => p + c.utxo.value),
                            network: network),
                        network: network);
                    saveTransaction(address: address, transaction: walletTx);
                  }
                  // final height = await client.getLatestBlockHeight();

                  return ResultOk(utxos);
                });
              });
            },
            onFetched: () => ResultOk.okVoid);
      },
      logging: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "getAccountUtxos",
          trace: trace.toString(),
          err: exception),
    );
    return client.andThenCatchAsync((client) async {
      final height = await client.getLatestBlockHeight();
      final utxos = (await address._getAccountUtxos());
      return utxos.map((utxos) {
        List<BitcoinUtxoWithSpendingInfo> utxosWithConfirmation = utxos
            .map((e) => BitcoinUtxoWithSpendingInfo.fromBlockHeight(e.utxo, height))
            .toList();
        if (!includeTokens && network.coinParam.isBCH) {
          utxosWithConfirmation =
              utxosWithConfirmation.where((e) => e.utxo.token == null).toList();
        }
        return BitcoinUtxosWithAccountInfo(
            account: addressDetails, utxos: utxosWithConfirmation);
      });
    });
  }

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IBitcoinAddress address,
      {bool tokens = true}) async {
    final result = await getAccountUtxos(address);
    return result.map((_) {
      return true;
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IBitcoinAddress address,
      required List<TokenCore<Object, APPToken>> tokens,
      bool isAccountAddress = false}) async {
    return ResultErr.fromException(WalletExceptionConst.networkTokenUnsuported);
  }

  @override
  IResult<BitcoinNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<BitcoinNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = BitcoinNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  BitcoinNetworkAddress? findAddressFromScriptSync(Script script) {
    return addresses
        .firstWhereOrNull((e) => e.networkAddress.toScriptPubKey() == script)
        ?.networkAddress;
  }

  @override
  final clientRequiredServices = NetworkClientRequirment.oneOf({
    APIProviderServices.electrum,
    APIProviderServices.mempool,
    APIProviderServices.blockCypher
  });
}
