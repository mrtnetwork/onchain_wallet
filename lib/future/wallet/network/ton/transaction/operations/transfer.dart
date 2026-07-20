import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/types/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain_wallet/crypto/networks/ton/ton.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';

class TonTransactionTransferOperation extends TonTransactionStateController2 {
  TonTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  bool get allowAddTransfer => recipients.value.length < maxMessageLength;

  late final LiveFormFields<TonTransferDetails> recipients =
      LiveFormFields<TonTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (_, value) => _validateRecipients(value));

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) {
      setDefaultFee();
      return;
    }
    return super.estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    final simulateError =
        txFee.fee.hasError ? "simulate_transaction_fee_failed".tr : null;
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final r = address.addressData.currencyBalance - total - txFee.fee.fee.balance;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    final tokens =
        recipients.value.map((e) => e.jetton).whereType<TonJettonToken>().toSet();
    for (final i in tokens) {
      final total = recipients.value
          .where((e) => e.jetton == i)
          .fold<BigInt>(BigInt.zero, (p, c) => p + c.tokenBalance.balance);
      final remain = i.balance.balance - total;
      if (remain.isNegative) {
        return TransactionStateStatus.insufficient(IntegerBalance.token(r, i.token),
            warning: simulateError);
      }
    }
    return TransactionStateStatus.ready();
  }

  String? _validateRecipients(List<TonTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) {
        return "the_amount_is_unspecified".tr;
      }
      if (i.hasToken && !i.hasTokenAmount) {
        return "the_jetton_amount_is_unspecified".tr;
      }
      if (i.hasToken && i.forwardBalance.largerThanZero) {
        if (i.amount.balance <= i.forwardBalance.balance) {
          return "ton_total_amount_validator".tr;
        }
      }
      if (!i.isReady) return "some_required_fields_not_filled".tr;
    }
    return null;
  }

  String? filterAccount(TonAddress address) {
    if (address == this.address.networkAddress ||
        recipients.value.any((e) => e.recipient.networkAddress == address)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateRecipients(
      List<ReceiptAddress<TonAddress>>? addressess, StringVoid onErr) {
    if (addressess == null) return;
    for (final i in addressess) {
      if (!allowAddTransfer) {
        onErr("outgoing_message_limit_exceeded".tr);
        break;
      }
      final transfer = TonTransferDetails(recipient: i, token: network.token);
      recipients.addValue(transfer);
    }
    onStateUpdated();
    estimateFee();
  }

  void onUpdateBalance(TonTransferDetails address, BigInt? balance) {
    if (balance == null) return;
    address.updateBalance(balance);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateForwardBalance(TonTransferDetails address, BigInt? balance) {
    if (balance == null) return;
    address.onUpdateForwardBalance(balance);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateQueryId(TonTransferDetails address, BigRational? queryId) {
    if (queryId == null) return;
    address.onUpdateQueryId(queryId.toBigInt());
    onStateUpdated();
    estimateFee();
  }

  void onUpdateJettonBalance(TonTransferDetails address, BigInt? balance) {
    if (balance == null) return;
    address.onUpdateJettonBalance(balance);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateMessageBody(
      TonTransferDetails address, TonMessageBodyType type, String? messageBody) {
    address.onUpdateMessageBody(type, messageBody);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAddressBounce(TonTransferDetails address, bool bounce) {
    address.onUpdateBounce(bounce);
    onStateUpdated();
    estimateFee();
  }

  BigInt getMaxInput(TonTransferDetails address) {
    final total = recipients.value.fold<BigInt>(
        BigInt.zero, (previousValue, element) => previousValue + element.amount.balance);
    final amount = this.address.addressData.currencyBalance -
        total -
        txFee.fee.fee.balance +
        address.amount.balance;
    if (amount.isNegative) return BigInt.zero;
    return amount;
  }

  void onUpdateToken(TonTransferDetails address, TonJettonToken? jetton) {
    if (jetton == null || jetton == address.jetton) return;
    address.onUpdateTransferToken(jetton);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveToken(TonTransferDetails address) {
    if (address.jetton == null) return;
    address.onUpdateTransferToken(null);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(TonTransferDetails recipient) {
    recipients.removeValue(recipient);
    recipient.dispose();
    onStateUpdated();
    estimateFee();
  }

  String? queryIdValidator(String? v) {
    if (TonUtils.isValidQueryId(BigInt.parse(v ?? ""))) return null;
    return "ton_query_id_validator".tr;
  }

  BigInt getTokenMaxInput(TonTransferDetails output) {
    final token = output.jetton;
    assert(token != null);
    if (token == null) return BigInt.zero;
    final total = recipients.value
        .where((e) => e.jetton == token)
        .fold<BigInt>(BigInt.zero, (p, c) => p + c.tokenBalance.balance);
    return token.balance.balance - total + output.tokenBalance.balance;
  }

  @override
  Future<ITonTransactionData> buildTransactionData({bool simulate = false}) async {
    final seqno = await getAccountSeqno(walletContract);
    final messages =
        recipients.value.map((e) => e.toMessage(address.networkAddress)).toList();
    if (walletVesion == 1 && messages.length > 1) {
      throw AppException("ton_wallet_validator_desc");
    }
    final payments = recipients.value.expand((e) => e.toPaymentInfo()).toList();
    return ITonTransactionData(
        fee: txFee.fee, messages: messages, seqno: seqno, payment: payments);
  }

  @override
  Future<TransactionStateController> cloneController(ITonAddress address) async {
    return TonTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TonTransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => TonTransactionOperations.transfer;

  @override
  List<LiveFormField<Object?, Object>> get fields => [recipients];

  @override
  void dispose() {
    for (final i in recipients.value) {
      i.dispose();
    }
    super.dispose();
  }
}
