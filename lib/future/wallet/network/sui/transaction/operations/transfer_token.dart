import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain/serialization/bcs/move/types/types.dart';
import 'package:on_chain/sui/src/transaction/types/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/widgets/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SuiTransactionTransferTokenOperation
    extends SuiTransactionStateController<ISuiTransactionDataTokenTransfer> {
  SuiTransactionTransferTokenOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      required this.token});
  StreamSubscription<IntegerBalance>? _tokenBalanceListener;
  final SuiToken token;
  @override
  Token get transferToken => token.token;

  BigInt getMaxInput(SuiTransferDetails recipient) {
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final max = token.balance.balance - total + recipient.amount.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  void onUpdateAmount(SuiTransferDetails recipient, BigInt amount, bool max) {
    recipient.updateBalance(amount);
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    BigInt total = address.addressData.currencyBalance - txFee.fee.requiredFee;
    if (total.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(total, network.token),
          warning: simulateError);
    }
    total = recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final r = token.balance.balance - total;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, transferToken),
          warning: simulateError);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<ISuiTransactionDataTokenTransfer> buildTransactionData(
      {bool simulate = false}) async {
    final coins = await getAccountCoins(address.networkAddress);
    return ISuiTransactionDataTokenTransfer(
        coins: coins,
        token: token,
        recipients: recipients.output
            .map((e) => ITransactionDataTransferTokenRecipient(
                recipient: e.recipient.networkAddress,
                amount: e.amount.balance,
                token: token))
            .toList(),
        fee: txFee.fee);
  }

  @override
  Future<ISuiTransaction<ISuiTransactionDataTokenTransfer>> buildTransaction(
      {bool simulate = false, BigInt? gasPrice, BigInt? budget}) async {
    final transaction = await buildTransactionData(simulate: simulate);
    gasPrice ??= transaction.fee.gasPrice;
    budget ??= transaction.fee.budget;
    final assetType = transaction.token.assetType;
    final coins = transaction.coins.where((e) => e.coinType == assetType).toList();
    if (coins.isEmpty) {
      throw WalletExceptionConst.insufficientBalance;
    }
    if (coins.length == 1) {
      final txV1 = buildTransferSingleCoin(
          object: coins[0].toObjectRef(),
          budget: budget,
          gasPrice: gasPrice,
          recipients: transaction.recipients,
          owner: address.networkAddress);
      return ISuiTransaction(
          account: address, transactionData: transaction, transaction: txV1);
    }
    List<SuiCallArguments> inputs = coins
        .map((e) => SuiCallArgObject(SuiObjectArgImmOrOwnedObject(e.toObjectRef())))
        .cast<SuiCallArguments>()
        .toList();
    final destionations = transaction.recipients;
    List<SuiCommand> commands = [
      SuiCommandMergeCoins(
          sources: List.generate(coins.length - 1, (i) => SuiArgumentInput(i + 1)),
          destination: SuiArgumentInput(0)),
      SuiCommandSplitCoins(
          amounts: List.generate(
              destionations.length, (i) => SuiArgumentInput(inputs.length + i)),
          coin: SuiArgumentInput(0))
    ];

    final amounts = destionations.map((e) => SuiCallArgPure.u64(e.amount)).toList();
    inputs.addAll(amounts);
    final transfers = List.generate(destionations.length, (i) {
      final index = inputs.length + i;
      return SuiCommandTransferObjects(objects: [
        SuiArgumentNestedResult(commandIndex: 1, resultIndex: i),
      ], address: SuiArgumentInput(index));
    });
    final addresses = destionations.map((e) => e.recipient).toList();
    inputs.addAll(addresses);
    commands.addAll(transfers);
    final kind = SuiProgrammableTransaction(inputs: inputs, commands: commands);
    final txV1 = SuiTransactionDataV1(
        expiration: const SuiTransactionExpirationNone(),
        sender: address.networkAddress,
        gasData: SuiGasData(
            payment: [], owner: address.networkAddress, price: gasPrice, budget: budget),
        kind: SuiTransactionKindProgrammableTransaction(kind));
    return ISuiTransaction(
        account: address, transactionData: transaction, transaction: txV1);
  }

  @override
  Future<List<IWalletTransaction<SuiWalletTransaction, ISuiAddress>>>
      buildWalletTransaction(
          {required ISuiSignedTransaction<ISuiTransactionDataTokenTransfer> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final outputs = signedTx.transaction.transactionData.recipients
        .map((e) => SuiWalletTransactionTransferOutput(
            to: e.recipient,
            amount: WalletTransactionIntegerAmount(
                amount: e.amount,
                network: network,
                token: e.token.token,
                tokenIdentifier: e.token.issuer)))
        .toList();
    final total =
        outputs.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.amount.balance);
    final transaction = SuiWalletTransaction(
        txId: txId.txId,
        outputs: outputs,
        totalOutput: WalletTransactionIntegerAmount(
            amount: total,
            network: network,
            token: signedTx.transaction.transactionData.token.token,
            tokenIdentifier: signedTx.transaction.transactionData.token.issuer),
        network: network);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<TransactionStateController> cloneController(ISuiAddress address) async {
    final tokens = (await address.getAccountTokens()).unwrap();
    final addressToken = tokens.firstWhere((e) => e.assetType == token.assetType,
        orElse: () => token.clone(balance: BigInt.zero));
    return SuiTransactionTransferTokenOperation(
        walletProvider: walletProvider,
        account: account,
        address: address,
        token: addressToken);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SuiTransactionTransferTokenWidget(form: this);
  }

  @override
  TransactionOperations get operation => SuiTransactionOperations.tokenTransfer;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SuiNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: false);
    if (!addressTokens.contains(token)) {
      await account.updateTokenBalance(address: address, tokens: [token]);
    } else {
      account.updateTokenBalance(address: address, tokens: [token]);
    }
    _tokenBalanceListener = token.streamBalance.stream.listen((_) => onAccountUpdated());
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    _tokenBalanceListener?.cancel();
    _tokenBalanceListener = null;
    token.streamBalance.dispose();
  }
}
