import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain/aptos/src/transaction/constants/const.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/models/types.dart';

class AptosTransactionTransferOperation
    extends AptosTransactionStateController<IAptosTransactionDataTransfer> {
  AptosTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  AptosTransferDetails? _lockedMax;

  @override
  Token get transferToken => network.token;
  BigInt getMaxInput(AptosTransferDetails recipient) {
    final total = recipients.value.map((c) => c.amount.balance).sum;
    final max = address.addressData.currencyBalance -
        total +
        recipient.amount.balance -
        txFee.fee.requiredFee;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  void onUpdateAmount(AptosTransferDetails recipient, BigInt amount, bool max) {
    _lockedMax = max ? recipient : null;
    recipient.updateBalance(amount);
    if (max) {
      BigInt defaultMaxGasAmount = AptosConstants.defaultMaxGasAmount;
      final fixedAmount = getMaxInput(recipient) - defaultMaxGasAmount;
      if (fixedAmount.isNegative) {
        _lockedMax = null;
      } else {
        recipient.updateBalance(fixedAmount);
      }
    }

    onStateUpdated();
    estimateFee();
  }

  @override
  void onRemoveRecipient(AptosTransferDetails recipient) {
    _lockedMax = null;
    super.onRemoveRecipient(recipient);
  }

  @override
  Future<IAptosTransactionDataTransfer> buildTransactionData(
      {bool simulate = false}) async {
    return IAptosTransactionDataTransfer(
        recipients: recipients.value
            .map((e) => ITransactionDataTransferRecipient(
                recipient: e.recipient.networkAddress, amount: e.amount.balance))
            .toList(),
        fee: txFee.fee);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final total = recipients.value.map((c) => c.amount.balance).sum;
    final r = address.addressData.currencyBalance - total - txFee.fee.requiredFee;
    return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
        warning: simulateError);
  }

  @override
  void onFeeUpdated(void _) {
    if (!txFee.isPending) {
      final locked = _lockedMax;
      if (locked != null) {
        locked.updateBalance(getMaxInput(locked));
        _lockedMax = null;
      }
    }
    onStateUpdated();
  }

  @override
  Future<List<IWalletTransaction<AptosWalletTransaction, IAptosAddress>>>
      buildWalletTransaction(
          {required IAptosSignedTransaction<IAptosTransactionDataTransfer> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final transactionData = signedTx.transaction.transactionData;
    final outputs = transactionData.recipients
        .map((e) => AptosWalletTransactionTransferOutput(
            to: e.recipient,
            amount: WalletTransactionIntegerAmount(amount: e.amount, network: network)))
        .toList();
    final total =
        outputs.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.amount.balance);
    final transaction = AptosWalletTransaction(
        txId: txId.txId,
        outputs: outputs,
        totalOutput: WalletTransactionIntegerAmount(amount: total, network: network),
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<TransactionStateController> cloneController(IAptosAddress address) async {
    return AptosTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return AptosTransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => AptosTransactionOperations.transfer;
}
