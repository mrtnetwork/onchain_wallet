import 'dart:async';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';

class CosmosTransactionTransferOperation extends CosmosTransactionStateController2 {
  CosmosTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormFields<CosmosTransferDetails> recipients =
      LiveFormFields<CosmosTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (_, value) => _validateRecipients(value));

  String? _validateRecipients(List<CosmosTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  void onUpdateRecipients(List<ReceiptAddress<CosmosBaseAddress>> addressess) {
    final recipients = addressess
        .map((e) => CosmosTransferDetails(
            recipient: e, token: nativeToken, balance: address.addressData.balance))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipientToken(
      {required CosmosTransferDetails receipt, required CW20Token? token}) {
    if (token == null) return;
    receipt.onUpdateToken(token);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(CosmosTransferDetails recipient) {
    recipients.removeValue(recipient);
    recipient.dispose();
    onStateUpdated();
    estimateFee();
  }

  BigInt _getMaxInput(CosmosTransferDetails recipient) {
    final token = tokens.firstWhereOrNull((e) => e == recipient.token);
    if (token == null) return BigInt.zero;
    final total =
        recipients.value.where((e) => e.token == token).map((e) => e.amount.balance).sum;
    BigInt remain = token.balance.balance - total;
    if (token.denom == txFee.denom) {
      remain -= txFee.fee.fee.balance;
    }
    return remain;
  }

  BigInt getMaxInput(CosmosTransferDetails recipient) {
    final remain = _getMaxInput(recipient) + recipient.amount.balance;
    if (remain.isNegative) return BigInt.zero;
    return remain;
  }

  void onUpdateAmount(CosmosTransferDetails recipient, BigInt amount, bool max) {
    recipient.onUpdateBalance(amount);
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    for (final i in recipients.value) {
      final remain = _getMaxInput(i);
      if (remain.isNegative) {
        return TransactionStateStatus.insufficient(
            IntegerBalance.token(remain, i.token.token),
            warning: simulateError);
      }
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<ICosmosTransactionData> buildTransactionData({bool simulate = false}) async {
    final messages = recipients.value
        .map((e) => CosmosTransactionMessage(
            message: e.toMessage(address.networkAddress, network), signer: address))
        .toList();
    final payments = recipients.value
        .map((e) => ICosmosTransactionDataTokenTransfer(
            recipient: e.recipient.networkAddress,
            amount: e.amount.balance,
            token: e.token))
        .toList();
    return ICosmosTransactionData(
        fee: txFee.fee,
        memo: memo.value,
        messages: messages,
        sequence: transactionRequirment.account!.sequence ?? BigInt.zero,
        accountNumber: transactionRequirment.account!.accountNumber ?? BigInt.zero,
        feeDenom: txFee.denom,
        payments: payments);
  }

  @override
  Future<TransactionStateController> cloneController(ICosmosAddress address) async {
    return CosmosTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return CosmosTransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => CosmosTransactionOperations.transfer;

  @override
  List<LiveFormField<Object?, Object>> get fields => [recipients];
}
