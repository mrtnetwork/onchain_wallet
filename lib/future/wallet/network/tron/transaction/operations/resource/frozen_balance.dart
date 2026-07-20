import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/frozen_balance.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionFreezeBalanceV2ContractOperation
    extends TronTransactionStateController2<FreezeBalanceV2Contract> {
  TronTransactionFreezeBalanceV2ContractOperation(
      {required super.walletProvider,
      required super.account,
      required super.address});

  late final LiveFormField<IntegerBalance, IntegerBalance> amount =
      LiveFormField(
    title: "frozen_balance".tr,
    subtitle: "trx_stake_amount".tr,
    value: IntegerBalance.zero(network.token, allowNegative: false),
    optional: false,
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  final LiveFormField<ResourceCode, ResourceCode> resource = LiveFormField(
      title: "resource".tr,
      subtitle: "trx_stake_type".tr,
      value: ResourceCode.bandWidth,
      optional: false);

  void onUpdateResource(ResourceCode? resource) {
    if (resource == null) return;
    this.resource.setValue(resource);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.value.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  BigInt getMaxInput() {
    final total = amount.value.balance;
    final max =
        address.addressData.currencyBalance - total - txFee.fee.fee.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  @override
  Future<ITronTransactionData<FreezeBalanceV2Contract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      contract: FreezeBalanceV2Contract(
          ownerAddress: address.networkAddress,
          frozenBalance: amount.value.balance,
          resource: resource.value),
    );
  }

  @override
  Future<TransactionStateController> cloneController(
      ITronAddress address) async {
    return TronTransactionFreezeBalanceV2ContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionFreezeBalanceV2ContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.freezeBalanceV2Contract;

  @override
  List<LiveFormField<Object?, Object>> get fields => [amount, resource];
}
