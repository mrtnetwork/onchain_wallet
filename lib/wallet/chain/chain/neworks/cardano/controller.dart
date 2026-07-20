part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class IADAChainContext
    implements
        IChainContext<
            ADAAddress,
            TokenCore,
            NFTCore,
            WalletCardanoNetwork,
            ADAWalletTransaction,
            ICardanoAddress,
            ADANetworkClient,
            CardanoNetworkProvider> {
  Future<IResult<List<ADAAddressUtxo>>> getAccountUtxos(ICardanoAddress address);

  Future<IResult<List<TransactionUnspentOutput>>> getAccountTransactionUnspentOutputs(
      ICardanoAddress address);
  Future<IResult<List<TransactionUnspentOutput>>>
      getAccountLatestTransactionUnspentOutputs(ICardanoAddress address);
}

final class ADAMainChainContext extends DefaultMainChainContext<
    ADAAddress,
    TokenCore,
    NFTCore,
    WalletCardanoNetwork,
    ADAWalletTransaction,
    ICardanoAddress,
    ADANetworkClient,
    CardanoNetworkProvider> implements IADAChainContext {
  final Map<ICardanoAddress, CachedObject<List<ADAAccountUTXOResponse>>> utxos = {};

  ADAMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<List<ADAAddressUtxo>>> getAccountUtxos(ICardanoAddress address) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      final utxos = await client.andThenCatchAsync((client) async {
        network.coinParam.maxTxConfirmationBlock;
        this.utxos[address] ??= CachedObject(
            interval: Duration(seconds: network.coinParam.totalConfirmationTime));

        final cachedUtxos = CachedObject<List<ADAAccountUTXOResponse>>(
            interval: Duration(seconds: network.coinParam.averageBlockTime));
        this.utxos[address]!;
        final utxos = await cachedUtxos.get(
            onFetch: () async =>
                await client.getAccountUtxos(address: address.networkAddress));
        final addressUtxos = await address._getAccountUtxos();
        return addressUtxos.andThenCatchAsync((addressUtxos) async {
          Set<ADAAddressUtxo> existsUtxos = addressUtxos.clone();
          existsUtxos =
              existsUtxos.where((e) => utxos.any((u) => u.toInput == e.input)).toSet();
          final save = await address._updateAccountUtxox(existsUtxos);
          return save.andThenCatchAsync((_) async {
            final existInputs = existsUtxos.map((e) => e.input);
            final newUtxos =
                utxos.where((e) => !existInputs.contains(e.toInput)).toList();

            ///
            if (newUtxos.isEmpty) {
              return ResultOk(utxos);
            }
            final txInputs = newUtxos.map((e) => e.toInput).toList();
            final txes = await client.getTxesFromInputs(txInputs);
            for (final i in newUtxos) {
              final tx = txes.firstWhereOrNull((e) => e.txInput == i.toInput);
              if (tx == null) continue;
              existsUtxos.add(ADAAddressUtxo.fromUtxo(i, tx.output));
            }
            final save = await address._updateAccountUtxox(existsUtxos);
            return save.andThenCatchAsync((_) async {
              final txIds = txInputs.map((e) => e.txIdHex).toSet();
              for (final i in txIds) {
                final tx =
                    txes.firstWhereOrNull((e) => e.txInput.txIdHex == e.txInput.txIdHex);
                if (tx == null) continue;
                final addressUtxos =
                    newUtxos.where((e) => e.toInput.txIdHex == i).toList();
                if (addressUtxos.isEmpty) continue;
                final walletTx = ADAWalletTransaction(
                    txId: i,
                    time: tx.blockTime,
                    outputs: [],
                    type: WalletTransactionType.receive,
                    status: WalletTransactionStatus.block,
                    totalOutput: WalletTransactionIntegerAmount(
                        amount: addressUtxos.sumOflovelace, network: network),
                    network: network);
                saveTransaction(address: address, transaction: walletTx);
              }
              return ResultOk(utxos);
            });
          });
        });
      });
      return utxos.andThenAsync((e) async {
        final utxos = await address._getAccountUtxos();
        return utxos.map((e) => e.toList());
      });
    });
  }

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ICardanoAddress address,
      {bool tokens = true}) async {
    if (address.isRewardAddress) return ResultOk(true);
    final result = await getAccountUtxos(address);
    return result.map((_) => true);
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ICardanoAddress address,
      required List<TokenCore<Object, APPToken>> tokens,
      bool isAccountAddress = false}) async {
    return ResultErr.fromException(WalletExceptionConst.networkTokenUnsuported);
  }

  @override
  Future<IResult<List<TransactionUnspentOutput>>> getAccountTransactionUnspentOutputs(
      ICardanoAddress address) async {
    final addr = await isAccountAddress(address);
    return addr.andThenAsync((address) async {
      final utxos = await address._getAccountUtxosController();
      return utxos.map((e) => e.transactionUnspentOutputs);
    });
  }

  @override
  Future<IResult<List<TransactionUnspentOutput>>>
      getAccountLatestTransactionUnspentOutputs(ICardanoAddress address) async {
    final utxos = await getAccountUtxos(address);
    return utxos.map((e) => e.map((e) => e.transactionUnspentOutput).toList());
  }

  @override
  IResult<CardanoNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<CardanoNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = CardanoNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.blockfrost});
}
