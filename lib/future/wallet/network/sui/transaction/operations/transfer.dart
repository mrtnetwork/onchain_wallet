import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain/sui/src/transaction/const/constant.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';

class SuiTransactionTransferOperation
    extends SuiTransactionStateController<ISuiTransactionDataTransfer> {
  SuiTransactionTransferOperation(
      {required super.walletProvider,
      required super.account,
      required super.address});
  SuiTransferDetails? _lockedMax;
  @override
  Token get transferToken => network.token;

  BigInt getMaxInput(SuiTransferDetails recipient) {
    final total = recipients.value
        .fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final max = address.addressData.currencyBalance -
        total +
        recipient.amount.balance -
        txFee.fee.requiredFee;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  void onUpdateAmount(SuiTransferDetails recipient, BigInt amount, bool max) {
    _lockedMax = max ? recipient : null;
    recipient.updateBalance(amount);
    if (max) {
      final fixedAmount = getMaxInput(recipient) - SuiTransactionConst.minGas;
      if (fixedAmount.isNegative) {
        _lockedMax = null;
      } else {
        amount = fixedAmount;
        recipient.updateBalance(amount);
      }
    }
    onStateUpdated();
    estimateFee();
  }

  @override
  void onRemoveRecipient(SuiTransferDetails recipient) {
    _lockedMax = null;
    super.onRemoveRecipient(recipient);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;

    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final total = recipients.value
        .fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final r =
        address.addressData.currencyBalance - total - txFee.fee.requiredFee;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  void onFeeUpdated(void _) {
    if (!txFee.isPending) {
      final lockedMax = _lockedMax;
      if (lockedMax != null) {
        lockedMax.updateBalance(getMaxInput(lockedMax));
        _lockedMax = null;
      }
    }
    onStateUpdated();
  }

  @override
  Future<ISuiTransactionDataTransfer> buildTransactionData(
      {bool simulate = false}) async {
    return ISuiTransactionDataTransfer(
        recipients: recipients.output
            .map((e) => ITransactionDataTransferRecipient(
                recipient: e.recipient.networkAddress,
                amount: e.amount.balance))
            .toList(),
        fee: txFee.fee);
  }

  @override
  Future<ISuiTransaction<ISuiTransactionDataTransfer>> buildTransaction(
      {bool simulate = false, BigInt? gasPrice, BigInt? budget}) async {
    final transaction = await buildTransactionData();
    gasPrice ??= transaction.fee.gasPrice;
    budget ??= transaction.fee.budget;
    final txV1 = buildTransferSingleCoin(
        gasPrice: gasPrice,
        budget: budget,
        recipients: transaction.recipients,
        owner: address.networkAddress);
    return ISuiTransaction(
        account: address, transactionData: transaction, transaction: txV1);
  }

  @override
  Future<List<IWalletTransaction<SuiWalletTransaction, ISuiAddress>>>
      buildWalletTransaction(
          {required ISuiSignedTransaction<ISuiTransactionDataTransfer> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final outputs = signedTx.transaction.transactionData.recipients
        .map((e) => SuiWalletTransactionTransferOutput(
            to: e.recipient,
            amount: WalletTransactionIntegerAmount(
                amount: e.amount, network: network)))
        .toList();
    final total = outputs.fold<BigInt>(
        BigInt.zero, (p, c) => p + c.amount.amount.balance);
    final transaction = SuiWalletTransaction(
        txId: txId.txId,
        outputs: outputs,
        totalOutput:
            WalletTransactionIntegerAmount(amount: total, network: network),
        network: network);
    return [
      IWalletTransaction(
          transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<TransactionStateController> cloneController(
      ISuiAddress address) async {
    return SuiTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SuiTransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => SuiTransactionOperations.transfer;
}
