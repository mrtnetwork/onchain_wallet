import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SolanaTransactionTransferOperation
    extends SolanaTransactionTransferStateController2 {
  SolanaTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  SolanaTransferDetails? _lockedMax;
  @override
  Token get transferToken => network.token;

  BigInt getMaxInput(SolanaTransferDetails recipient) {
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final max = address.addressData.currencyBalance -
        total +
        recipient.amount.balance -
        txFee.fee.fee.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  void onUpdateAmount(SolanaTransferDetails recipient, BigInt amount, bool max) {
    _lockedMax = max ? recipient : null;
    recipient.updateBalance(amount);
    onStateUpdated();
    estimateFee();
  }

  @override
  void onRemoveRecipients(SolanaTransferDetails recipient) {
    _lockedMax = null;
    super.onRemoveRecipients(recipient);
  }

  @override
  void onFeeUpdated(void _) {
    if (!txFee.isPending) {
      final last = _lockedMax;
      if (last != null) {
        last.updateBalance(getMaxInput(last));
        _lockedMax = null;
      }
    }
    onStateUpdated();
  }

  @override
  Future<void> estimateFee({BigInt? accountBalance, BigInt? totalTxLamports}) {
    return super.estimateFee(
        totalTxLamports:
            recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance));
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final r = address.addressData.currencyBalance - total - txFee.fee.fee.balance;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<List<IWalletTransaction<SolanaWalletTransaction, ISolanaAddress>>>
      buildWalletTransaction(
          {required ISolanaSignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    final payments =
        signedTx.transaction.transactionData.payment?.where((e) => e.token == null) ?? [];
    if (payments.isEmpty) {
      return super.buildWalletTransaction(signedTx: signedTx, txId: txId);
    }
    final memo = signedTx.transaction.transactionData.getWalletTxMemo();
    final outputs = payments
        .map((e) => SolanaWalletTransactionTransferOutput(
            to: e.recipient,
            amount: WalletTransactionIntegerAmount(amount: e.amount, network: network)))
        .toList();

    final total =
        outputs.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.amount.balance);
    final transaction = SolanaWalletTransaction(
        txId: txId.txId,
        memos: [if (memo != null) memo],
        outputs: outputs,
        totalOutput: WalletTransactionIntegerAmount(amount: total, network: network),
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<ISolanaTransactionData> buildTransactionData({bool simulate = false}) async {
    final blockhash = await getTransactionBlockHash(simulate: simulate);
    final instructions = (await Future.wait(recipients.value
            .map((e) => e.instruction(owner: address.networkAddress, client: client))))
        .expand((e) => e)
        .toList();
    return ISolanaTransactionData(
        fee: txFee.fee,
        memo: memo.value,
        payment: recipients.value
            .map((e) => ISolanaTransactionDataTokenTransfer(
                recipient: e.recipient.networkAddress,
                amount: e.amount.balance,
                token: null))
            .toList(),
        instructions: instructions,
        blockHash: blockhash);
  }

  @override
  Future<TransactionStateController> cloneController(ISolanaAddress address) async {
    return SolanaTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SolanaTransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => SolanaTransactionOperations.transfer;
}
