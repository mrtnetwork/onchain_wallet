part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class XRPNetworkStorageId extends DefaultNetworkStorageId {
  static const TronNetworkStorageId addressLedgerIndex = TronNetworkStorageId(51);
  const XRPNetworkStorageId(super.storageId);

  static const List<DefaultNetworkStorageId> values = [
    ...DefaultNetworkStorageId.values,
    addressLedgerIndex
  ];
}

final class XRPChain extends Chain<
    XRPBaseAddress,
    RippleIssueToken,
    RippleNFToken,
    WalletXRPNetwork,
    XRPWalletTransaction,
    IXRPAddress,
    XRPNetworkClient,
    XRPNetworkProvider,
    IXRPChainContext> {
  XRPChain._(
      {required WalletXRPNetwork network,
      required String id,
      required InChainWalletController controller})
      : super._(
            context: switch (controller) {
          ChainWalletControllerDefault() =>
            XRPMainChainContext(network: network, controller: controller, id: id),
          ChainWalletControllerExternal() => throw UnimplementedError(),
        });

  factory XRPChain.setup(
      {required WalletXRPNetwork network,
      required String id,
      required InChainWalletController controller}) {
    return XRPChain._(network: network, id: id, controller: controller);
  }

  factory XRPChain.deserialize(
      {required WalletXRPNetwork network,
      required CborListValue cbor,
      required InChainWalletController controller}) {
    final int networkId = cbor.rawValueAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String id = cbor.rawValueAt<String>(2);
    return XRPChain._(network: network, id: id, controller: controller);
  }
}

abstract final class IXRPChainContext
    implements
        IChainContext<XRPBaseAddress, RippleIssueToken, RippleNFToken, WalletXRPNetwork,
            XRPWalletTransaction, IXRPAddress, XRPNetworkClient, XRPNetworkProvider> {
  Future<IResult<void>> getAccountTxes(IXRPAddress address,
      {bool isAccountAddress = false});
}

final class XRPMainChainContext extends DefaultMainChainContext<
    XRPBaseAddress,
    RippleIssueToken,
    RippleNFToken,
    WalletXRPNetwork,
    XRPWalletTransaction,
    IXRPAddress,
    XRPNetworkClient,
    XRPNetworkProvider> implements IXRPChainContext {
  XRPMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IXRPAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);

    final balanceChanged = await accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balance = await client.getAccountBalance(address.networkAddress);
        final updateBalance = await address._updateAccountBalance(balance);
        if (updateBalance.isErr) return updateBalance;
        bool balanceChanged = updateBalance.unwrap();
        if (tokens) {
          final tokens = await address.getAccountTokens();
          return tokens.andThenAsync((tokens) async {
            final balances = await client.getAccountTokens(address.networkAddress);
            for (final i in tokens) {
              final currentUpdate = balances.firstWhereOrNull((element) =>
                  element.issuer.classicAddress == i.issuer &&
                  element.currency == i.assetCode);
              final result = await address._updateAccountTokenBalance(
                  i,
                  () => i._updateBalance(
                      BigRational.parseDecimal(currentUpdate?.balance ?? "0")));
              if (result.isErr) return result;
              balanceChanged |= result.unwrap();
            }
            return ResultOk(balanceChanged);
          });
        }
        return ResultOk(balanceChanged);
      });
    });
    return balanceChanged.map((balanceChanged) {
      getAccountTxes(address, isAccountAddress: true);
      return balanceChanged;
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IXRPAddress address,
      required List<RippleIssueToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balances = await client.getAccountTokens(address.networkAddress);
        for (final i in tokens) {
          final currentUpdate = balances.firstWhereOrNull((element) =>
              element.issuer.classicAddress == i.issuer &&
              element.currency == i.assetCode);
          final result = await address._updateAccountTokenBalance(
              i,
              () => i._updateBalance(
                  BigRational.parseDecimal(currentUpdate?.balance ?? "0")));
          if (result.isErr) return result;
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<void>> getAccountTxes(IXRPAddress address,
      {bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync(
        (client) async {
          final ledgerIndex = await address._stoageGetAccountLedgerIndex();
          return ledgerIndex.map((e) => e).andThenAsync(
            (ledgerIndex) async {
              final txes = await client.getAccountTxes(
                  address: address.networkAddress, ledger: ledgerIndex);
              final result =
                  await address._storageSaveAccountLedgeIndex(txes.latestLedger);
              return result.andThenAsync((_) async {
                final receivedTxes = txes.txes
                    .where((e) =>
                        e.transaction.transaction.account !=
                        address.networkAddress.classicAddress)
                    .toList();
                final tokens = await address.getAccountTokens();
                return tokens.andThenAsync((tokens) async {
                  for (final i in receivedTxes) {
                    WalletTransactionAmount? amount;
                    final tx = i.transaction.transaction;
                    if (tx.transactionType == SubmittableTransactionType.payment) {
                      final payment = tx.cast<Payment>();
                      if (payment.amount.type == AmountType.native) {
                        amount = WalletTransactionIntegerAmount(
                            amount: (payment.amount as XRPAmount).value,
                            network: network);
                      } else if (payment.amount.type == AmountType.issue) {
                        final currencyAmount = (payment.amount as IssuedCurrencyAmount);

                        NonDecimalToken? token = tokens
                            .firstWhereNullable((e) =>
                                e.issuer == currencyAmount.issuer &&
                                e.assetCode == currencyAmount.currency)
                            ?.token;
                        token ??= NonDecimalToken(
                            name: currencyAmount.currency,
                            symbol: currencyAmount.currency);
                        amount = WalletTransactionDecimalsAmount(
                            amount: currencyAmount.value, token: token);
                      }
                    }
                    XRPBaseAddress sender = XRPBaseAddress(tx.account);
                    if (tx.sourceTag != null) {
                      sender = sender.toXAddress(
                          tag: tx.sourceTag, chainType: network.coinParam.chainType);
                    }
                    final xrpTx = XRPWalletTransaction(
                        txId: i.txId,
                        totalOutput: amount,
                        time: i.ledgerTime,
                        type: WalletTransactionType.receive,
                        status: i.ledgerTime == null
                            ? WalletTransactionStatus.pending
                            : WalletTransactionStatus.block,
                        network: network,
                        inputs: [
                          XRPWalletTransactionOperationInput(
                              address: sender, operation: tx.transactionType.value)
                        ]);
                    final result =
                        await saveTransaction(address: address, transaction: xrpTx);
                    if (result.isErr) return result;
                  }

                  return ResultOk.okVoid;
                });
              });
            },
          );
        },
        logging: (exception, trace) => AppLogData(
            runtime: runtimeType,
            trace: trace.toString(),
            function: "getAccountTxes",
            err: exception),
      );
    });
  }

  @override
  IResult<XRPNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<XRPNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = XRPNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.ripple});
}
