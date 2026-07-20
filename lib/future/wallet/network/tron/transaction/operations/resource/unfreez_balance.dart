import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/unfreeze_balance.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionUnFreezeBalanceV2ContractOperation
    extends TronTransactionStateController2<UnfreezeBalanceV2Contract> {
  TronTransactionUnFreezeBalanceV2ContractOperation(
      {required super.walletProvider, required super.account, required super.address});

  late final IntegerBalance stackedBalance = IntegerBalance.zero(network.token);

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
      title: "unfreeze_balance".tr,
      subtitle: "trx_unstake_amount".tr,
      value: IntegerBalance.zero(network.token, allowNegative: false),
      optional: false);

  final LiveFormField<ResourceCode, ResourceCode> resource = LiveFormField(
      title: "resource".tr,
      subtitle: "trx_stake_type".tr,
      value: ResourceCode.bandWidth,
      optional: false);

  BigInt getMaxInput() {
    return stackedBalance.balance;
  }

  void _setResourceAmount(ResourceCode resource) {
    final resourceAmount = accountInfo?.frozenV2
            .firstWhereOrNull((element) => element.type == resource)
            ?.amount ??
        BigInt.zero;
    stackedBalance.updateBalance(resourceAmount);
    if (amount.value.balance > resourceAmount) {
      onUpdateAmount(BigInt.zero);
      return;
    }
    onStateUpdated();
    estimateFee();
  }

  void onUpdateResource(ResourceCode? resource) {
    if (resource == null || resource == this.resource.value) return;
    this.resource.setValue(resource);
    _setResourceAmount(resource);
  }

  void onUpdateAmount(BigInt amount) {
    if (amount > stackedBalance.balance) return;
    this.amount.value.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ITronTransactionData<UnfreezeBalanceV2Contract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      contract: UnfreezeBalanceV2Contract(
          ownerAddress: address.networkAddress,
          unfreezeBalance: amount.value.balance,
          resource: resource.value),
    );
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    return TronTransactionUnFreezeBalanceV2ContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionUnFreezeBalanceV2ContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.unfreezeBalanceV2Contract;

  @override
  List<LiveFormField<Object?, Object>> get fields => [amount, resource];
  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _setResourceAmount(resource.value);
    return this;
  }
}
