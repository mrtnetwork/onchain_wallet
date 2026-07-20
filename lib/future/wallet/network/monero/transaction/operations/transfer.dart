import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class MoneroTransactionTransferOperation extends MoneroTransactionStateController {
  MoneroTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  MoneroTransferDetails? _lockedMax;
  @override
  Token get transferToken => network.token;
  List<MoneroUtxoWithBalanceInfo> _utxos = [];

  late final LiveFormFields<MoneroTransferDetails> recipients =
      LiveFormFields<MoneroTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (_, value) => _validateRecipients(value));

  late final LiveFormField<MoneroTransferDetails, MoneroTransferDetails> remainingAmount =
      LiveFormField(
          title: "remaining_amount".tr,
          subtitle: "remaining_amount_and_receiver".tr,
          value: MoneroTransferDetails(
              allowNegativeAmount: true,
              recipientUpdateble: true,
              recipient:
                  account.getOrCreateReceiptFromNetworkAddressSync(account: address),
              token: network.token),
          optional: false);

  @override
  BigInt getMaxFeeInput() {
    return totalUtxos.value.balance;
  }

  void _onReceiptsUpdated() {
    final totalOutput = totalUtxos.value.balance;
    final totalAmounts = recipients.value.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.amount.balance);
    remainingAmount.value
        .updateBalance(totalOutput - totalAmounts - txFee.fee.fee.balance);
    remainingAmount.notify();
  }

  @override
  void onSelectedUtxosChanged(List<MoneroUtxoWithBalanceInfo> utxos) {
    _utxos = utxos;
    _lockedMax = null;
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipients(List<ReceiptAddress<MoneroAddress>> addressess) {
    _lockedMax = null;
    final recipients = addressess
        .map((e) => MoneroTransferDetails(recipient: e, token: network.token))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipientAmount(MoneroTransferDetails recipient, BigInt amount, bool max) {
    _lockedMax = max ? recipient : null;
    recipient.updateBalance(amount);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(MoneroTransferDetails recipient) {
    _lockedMax = null;
    recipients.removeValue(recipient);
    recipient.dispose();
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRemainingAccount(IMoneroAddress? address) {
    if (address == null || filterRemainAccount(address) != null) return;
    final recipient = account.getOrCreateReceiptFromNetworkAddressSync(account: address);
    remainingAmount.value.updateRecipientAddress(recipient);
    remainingAmount.notify();
    onStateUpdated();
  }

  @override
  Future<void> estimateFee() async {
    if (_utxos.isEmpty || !fieldsReady) {
      setDefaultFee();
      return;
    }

    return super.estimateFee();
  }

  String? _validateRecipients(List<MoneroTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    if (recipients.length >= MoneroConst.maxTxOutput) {
      return "transaction_output_exceeds_16_desc".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  bool _canSendToAddress(MoneroAddress address) {
    if (address.isIntegratedAddress) {
      if (recipients.value.isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  String? filterAccount(MoneroAddress address) {
    if (address == remainingAmount.value.recipient.networkAddress ||
        recipients.value.any((e) => e.recipient.networkAddress == address)) {
      return "address_already_exist".tr;
    } else if (!_canSendToAddress(address)) {
      return "monero_tx_integrated_address_alert".tr;
    }
    return null;
  }

  String? filterRemainAccount(IMoneroAddress address) {
    if (address.networkAddress == remainingAmount.value.recipient.networkAddress ||
        recipients.value
            .any((e) => e.recipient.networkAddress == address.networkAddress)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  BigInt getMaxInput(MoneroTransferDetails recipient) {
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final max = totalUtxos.value.balance -
        total +
        recipient.amount.balance -
        txFee.fee.fee.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    if (remainingAmount.value.amount.isNegative) {
      return TransactionStateStatus.insufficient(remainingAmount.value.amount);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  void onFeeUpdated(void _) {
    if (txFee.isPending) return;
    final lockedMax = _lockedMax;
    _onReceiptsUpdated();
    if (txFee.proccessed && lockedMax != null) {
      final remain = remainingAmount.value.amount.balance;
      BigInt amount = lockedMax.amount.balance;
      if (remain.isNegative) {
        amount -= (remain).abs();
      } else {
        amount += remain;
      }
      if (amount.isNegative) {
        amount = BigInt.zero;
      }
      lockedMax.updateBalance(amount);
      _onReceiptsUpdated();
    }
    _lockedMax = null;

    onStateUpdated();
  }

  @override
  Future<IMoneroTransactionData> buildTransactionData({bool simulate = false}) async {
    return IMoneroTransactionData(
      // fee: txFee.fee,
      change: remainingAmount.value.hasAmount
          ? MoneroTxDestination(
              amount: remainingAmount.value.amount.balance,
              address: remainingAmount.value.recipient.networkAddress)
          : null,
      payments: _utxos,
      destinations: recipients.value.map((e) => e.toMoneroDestination()).toList(),
    );
  }

  @override
  Future<List<IWalletTransaction<MoneroWalletTransaction, IMoneroAddress>>>
      buildWalletTransaction(
          {required IMoneroSignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    final List<IWalletTransaction<MoneroWalletTransaction, IMoneroAddress>> transactions =
        [];
    final signers =
        signedTx.transaction.transactionData.payments.map((e) => e.account).toSet();
    final destinations = signedTx.transaction.transactionData.destinations
        .map((e) => MoneroWalletTransactionOutput(
            amount: WalletTransactionIntegerAmount(
                amount: e.amount.balance, network: network),
            to: e.recipient.networkAddress))
        .toList();
    for (final i in signers) {
      final payments = signedTx.transaction.transactionData.payments
          .where((e) => e.account == i)
          .toList();
      final total = payments.fold<BigInt>(BigInt.zero, (p, c) => p + c.utxo.amount);
      final transaction = MoneroWalletTransaction(
          txId: txId.txId,
          time: DateTime.now(),
          network: network,
          totalOutput: WalletTransactionIntegerAmount(amount: total, network: network),
          outputs: destinations,
          txKeys: signedTx.finalTransactionData.txData.txKeys.map((e) => e.key).toList());
      transactions.add(IWalletTransaction(transaction: transaction, account: i));
    }
    return transactions;
  }

  @override
  Future<TransactionStateController> cloneController(IMoneroAddress address) async {
    return MoneroTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return MoneroTransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => MoneroTransactionOperations.transfer;

  @override
  List<LiveFormField<Object?, Object?>> get fields => [recipients, remainingAmount];

  @override
  void dispose() {
    super.dispose();
    for (final i in recipients.value) {
      i.dispose();
    }
    remainingAmount.value.dispose();
  }
}
