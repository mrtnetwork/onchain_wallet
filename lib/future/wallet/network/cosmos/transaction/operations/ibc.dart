import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/widgets/ibc.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class CosmosTransactionIbcTransferOperation extends CosmosTransactionStateController2 {
  CosmosTransactionIbcTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  List<CosmosChain> _ibcDestinationChains = [];
  List<CosmosChain> get ibcDestinationChains => _ibcDestinationChains;

  LiveFormField<CosmosIbcTransferForm?, CosmosIbcTransferForm?> pendingIbc =
      LiveFormField<CosmosIbcTransferForm?, CosmosIbcTransferForm?>(
          optional: true, title: '', value: null);
  late final LiveFormFields<CosmosIbcTransferData> transfers =
      LiveFormFields<CosmosIbcTransferData>(
          optional: false, title: "list_of_transfers".tr);

  void onSkipOperation() {
    final transfer = pendingIbc.value;
    if (transfer == null) return;
    pendingIbc.setValue(null);
    transfer.dispose();
    onStateUpdated();
    estimateFee();
  }

  void onCreateNewOperation() {
    if (pendingIbc.hasValue) return;
    final form = CosmosIbcTransferForm(controller: this);
    pendingIbc.setValue(form);
  }

  void onEditOperation(CosmosIbcTransferData transfer) {
    if (pendingIbc.hasValue) return;
    final form = transfer.form;
    pendingIbc.setValue(form);
    transfers.removeValue(transfer);
  }

  void onUpdateOperations() {
    final form = pendingIbc.value;
    if (form == null) return;
    form.onStateUpdated();
    if (!form.stateStatus.value.isReady) return;
    final transfer = form.toMessage();
    final data = CosmosIbcTransferData(transfer: transfer, form: form);
    transfers.addValue(data);
    onStateUpdated();
    estimateFee();
    pendingIbc.setValue(null);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    for (final i in transfers.value) {
      final state = i.form.getStateStatus();
      if (!state.isReady) return state;
    }
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<ICosmosTransactionData> buildTransactionData({bool simulate = false}) async {
    final messages = transfers.value
        .map((e) => CosmosTransactionMessage(
            message: e.transfer.toMessage(address.networkAddress, network),
            signer: address))
        .toList();
    final payments = transfers.value
        .map((e) => ICosmosTransactionDataTokenTransfer(
            recipient: e.transfer.address.networkAddress,
            amount: e.transfer.amount.balance,
            token: e.transfer.token))
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
    return CosmosTransactionIbcTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return CosmosTransactionIbcTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => CosmosTransactionOperations.ibcTransfer;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required CosmosNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _ibcDestinationChains = walletProvider.wallet
        .getChains<CosmosChain>()
        .where((e) =>
            e != account &&
            e.network.coinParam.ibcEnabled &&
            e.network.coinParam.chainType == network.coinParam.chainType)
        .toList();
    return this;
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields => [transfers, pendingIbc];
  @override
  void dispose() {
    pendingIbc.value?.dispose();

    for (final i in transfers.value) {
      i.form.dispose();
    }
    super.dispose();
  }
}
