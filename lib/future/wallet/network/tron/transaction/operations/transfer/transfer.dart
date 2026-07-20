import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

abstract class TronTransactionBaseTransferOperation<CONTRACT extends TronBaseContract>
    extends TronTransactionStateController2<CONTRACT> {
  TronTransactionBaseTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  bool _lockedMax = false;
  Token get transferToken => network.token;
  bool get isTrc20Transfer => false;

  final LiveFormField<ReceiptAddress<TronAddress>?, ReceiptAddress<TronAddress>> receipt =
      LiveFormField(
          title: "recipient".tr,
          subtitle: "receiver_address_desc".tr,
          value: null,
          optional: false);

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: "transfer_amount".tr,
    subtitle: "input_the_amout".tr,
    value: IntegerBalance.zero(transferToken),
    optional: false,
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  String? filterAccount(TronAddress address) {
    if (address == this.address.networkAddress) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateAmount(BigInt amount, bool max) {
    _lockedMax = max;
    this.amount.value.updateBalance(max ? getMaxInput() : amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAddress(ReceiptAddress<TronAddress>? address) {
    if (address == null) return;
    receipt.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  BigInt getMaxInput() {
    final max = address.addressData.currencyBalance - txFee.fee.fee.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  @override
  void onFeeUpdated(void _) {
    if (!txFee.isPending && _lockedMax) {
      amount.value.updateBalance(getMaxInput());
      _lockedMax = false;
    }
    onStateUpdated();
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    return TronTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  TransactionContractType get transactionType => TransactionContractType.transferContract;

  @override
  List<LiveFormField<Object?, Object>> get fields => [receipt, amount];
}

class TronTransactionTransferOperation
    extends TronTransactionBaseTransferOperation<TransferContract> {
  TronTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) {
      return status;
    }
    final total = amount.value;
    final max = address.addressData.balance.value - total - txFee.fee.fee;
    if (max.isNegative) {
      return TransactionStateStatus.insufficient(max);
    }
    return TransactionStateStatus.ready();
  }

  @override
  Future<ITronTransactionData<TransferContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
        fee: txFee.fee,
        blockData: blockData,
        memo: memo.value,
        tokenTransfer: ITronTransactionDataTokenTransfer(
            recipient: receipt.value!.networkAddress, amount: amount.value.balance),
        contract: TransferContract(
            ownerAddress: address.networkAddress,
            toAddress: receipt.value!.networkAddress,
            amount: amount.value.balance));
  }

  @override
  Future<List<IWalletTransaction<TronWalletTransaction, ITronAddress>>>
      buildWalletTransaction(
          {required ITronSignedTransaction<ITronTransactionData<TransferContract>>
              signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;

    final transfer = txData.tokenTransfer;
    final token = transfer?.token;
    assert(transfer != null && token == null);
    if (transfer == null || token != null) {
      return super.buildWalletTransaction(signedTx: signedTx, txId: txId);
    }
    final txMemo = txData.getMemo();
    final transaction = TronWalletTransaction(
        txId: txId.txId,
        network: network,
        memos: [if (txMemo != null) txMemo],
        totalOutput:
            WalletTransactionIntegerAmount(amount: transfer.amount, network: network),
        outputs: [
          TronWalletTransactionTransferOutput(
            to: transfer.recipient,
            amount:
                WalletTransactionIntegerAmount(amount: transfer.amount, network: network),
          ),
        ]);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionTransferWidget(form: this);
  }
}
