import 'dart:async';

import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/transfer/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionPaymentOperation
    extends RippleTransactionStateController<Payment> {
  final CachedObject<List<RippleIssueToken>> tokens = CachedObject();
  RipplePickedAsset _token = RipplePickedAsset.xrp();
  RippleTransactionPaymentOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionPaymentOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address,
      RippleIssueToken? token}) {
    final instance = RippleTransactionPaymentOperation._(
      walletProvider: walletProvider,
      account: account,
      address: address,
    );
    if (token != null) {
      instance.onUpdateToken(RipplePickedAsset.account(token));
    }
    return instance;
  }

  late final LiveFormField<StreamValue<BalanceCore>, StreamValue<BalanceCore>> token =
      LiveFormField(
    title: "token".tr,
    optional: false,
    value: address.addressData.balance,
  );
  late final LiveFormField<BalanceCore, BalanceCore> amount = LiveFormField(
    title: "transfer_amount".tr,
    subtitle: "input_the_amout".tr,
    optional: false,
    value: IntegerBalance.zero(network.token),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );
  late final LiveFormField<ReceiptAddress<XRPBaseAddress>?,
      ReceiptAddress<XRPBaseAddress>> recipient = LiveFormField(
    title: "recipient".tr,
    subtitle: "receiver_address_desc".tr,
    optional: false,
    value: null,
    onValidateError: (field, value) {
      if (value == null) return null;
      if (_token.type.isNative &&
          value.networkAddress.classicAddress == address.networkAddress.classicAddress) {
        return "send_to_self_not_allowed".tr;
      }
      return null;
    },
  );
  final LiveFormField<String?, String> invoiceId = LiveFormField(
      title: "invoiceid".tr,
      subtitle: "ripple_payment_invoiceid".tr,
      optional: true,
      value: null);

  final LiveFormField<PaymentFlag?, PaymentFlag> flag = LiveFormField(
      title: "payment_flags".tr,
      subtitle: "ripple_payment_flags".tr,
      value: null,
      optional: true);

  void onUpdateToken(RipplePickedAsset? token) {
    if (token == null) return;
    if (token.type.isNative) {
      if (_token.type.isNative) return;
      final currentAmount = this.token.value;
      this.token.setValue(address.addressData.balance);
      amount.setValue(IntegerBalance.zero(network.token));
      currentAmount.dispose();
    } else {
      if (_token.issueToken == token.issueToken) return;
      final updateToken = DecimalBalance.fromRational(
          token.issueToken!.token, token.issueToken?.currencyBalance ?? BigRational.zero);
      this
          .token
          .setValue(StreamValue(updateToken, name: "RippleTransactionPaymentOperation"));
      amount.setValue(DecimalBalance.zero(token.issueToken!.token));
    }
    _token = token;
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipient(ReceiptAddress<XRPBaseAddress>? address) {
    if (address == null) return;
    recipient.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmountXrp(BigInt amount) {
    final balance = this.amount.value;
    assert(balance is IntegerBalance);
    if (balance is IntegerBalance) {
      if (balance.updateBalance(amount)) {
        this.amount.notify();
      }
    }
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmountToken(BigRational amount) {
    final balance = this.amount.value;
    assert(balance is DecimalBalance);
    if (balance is DecimalBalance) {
      if (balance.updateBalance(amount)) {
        this.amount.notify();
      }
    }
    onStateUpdated();
    estimateFee();
  }

  void onUpdateInvoiceId(String? invoiceId) {
    this.invoiceId.setValue(invoiceId);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateFlag(PaymentFlag? flag) {
    this.flag.setValue(flag);
    onStateUpdated();
    estimateFee();
  }

  dynamic getMaxInput() {
    final nativeToken = _token.type.isNative;
    if (nativeToken) {
      final max = address.addressData.currencyBalance - txFee.fee.fee.balance;
      if (max.isNegative) return BigInt.zero;
      return max;
    }
    if (_token.type.isCreateAsset) return null;
    return _token.issueToken?.currencyBalance;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;

    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    BigInt total = BigInt.zero;
    final token = _token;
    if (token.type.isNative) {
      total = amount.value.balance;
    } else {
      if (token.type.isAccountToken) {
        final issueToken = token.issueToken!;
        final BigRational tokenAmount = issueToken.balance.balance - amount.value.balance;
        if (tokenAmount.isNegative) {
          return TransactionStateStatus.insufficient(
              DecimalBalance.fromRational(issueToken.token, tokenAmount),
              warning: simulateError);
        }
      }
    }
    final r = address.addressData.currencyBalance - total - txFee.fee.fee.balance;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<IXRPTransactionData<Payment>> buildTransactionData(
      {bool simulate = false}) async {
    return IXRPTransactionData(
        fee: txFee.fee,
        submittableTransaction: buildTransactionInternal(),
        payment: IXRPTransactionDataTokenTransfer(
            recipient: recipient.value!.networkAddress,
            amount: amount.value.balance,
            token: _token));
  }

  @override
  Payment buildTransactionInternal() {
    final token = _token;
    final payment = Payment(
        destination: recipient.value!.view,
        destinationTag: recipient.value?.networkAddress.tag,
        memos: RippleUtils.toXrplMemos(memos),
        invoiceId: invoiceId.value == null
            ? null
            : QuickBytesUtils.ensureIsHex(invoiceId.value!),
        amount: token.type.isNative
            ? XRPAmount(amount.value.balance as BigInt)
            : IssuedCurrencyAmount(
                currency: token.issueToken!.assetCode,
                issuer: token.issuer!,
                value: (amount.value.balance as BigRational).toDecimal()),
        account: address.networkAddress.address,
        sourceTag: address.networkAddress.tag,
        fee: txFee.fee.fee.balance,
        flags: [flag.value?.id ?? 0]);
    return payment;
  }

  @override
  Future<List<IWalletTransaction<XRPWalletTransaction, IXRPAddress>>>
      buildWalletTransaction(
          {required IXRPSignedTransaction<IXRPTransactionData<Payment>> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final payment = signedTx.transaction.transactionData.payment;
    final token = payment?.token;
    if (payment == null || token == null || token.type.isCreateAsset) {
      return super.buildWalletTransaction(signedTx: signedTx, txId: txId);
    }
    final WalletTransactionAmount txAmount = token.type.isNative
        ? WalletTransactionIntegerAmount(amount: payment.amount, network: network)
        : WalletTransactionDecimalsAmount(
            amount: (payment.amount as BigRational).toDecimal(),
            token: token.issueToken!.token,
            tokenIdentifier: token.issuer!);
    final output =
        XRPWalletTransactionTransferOutput(to: payment.recipient, amount: txAmount);
    final transaction = XRPWalletTransaction(
        txId: txId.txId, network: network, outputs: [output], totalOutput: txAmount);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionPaymentOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionTransferWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType => SubmittableTransactionType.payment;
  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [token, recipient, amount, invoiceId, flag];

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required XRPNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    tokens
        .get(onFetch: () async => client.accountTokens(address))
        .catchError((_) => <RippleIssueToken>[]);
    return this;
  }
}
