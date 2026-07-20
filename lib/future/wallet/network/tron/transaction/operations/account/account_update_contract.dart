import 'dart:async';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/account_update_contract.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionAccountUpdateContractOperation
    extends TronTransactionStateController2<AccountUpdateContract> {
  TronTransactionAccountUpdateContractOperation(
      {required super.walletProvider,
      required super.account,
      required super.address});

  final LiveFormField<String?, String> accountName = LiveFormField(
      title: "account_name".tr,
      subtitle: "account_name_desc".tr,
      value: null,
      optional: false);
  void onUpdateAccountName(String? name) {
    if (name == null) return;
    accountName.setValue(name);
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ITronTransactionData<AccountUpdateContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      contract: AccountUpdateContract(
          ownerAddress: address.networkAddress,
          accountName: StringUtils.toBytes(accountName.value!)),
    );
  }

  @override
  Future<TransactionStateController> cloneController(
      ITronAddress address) async {
    return TronTransactionAccountUpdateContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionAccountUpdateContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.accountUpdateContract;

  @override
  List<LiveFormField<Object?, Object>> get fields => [accountName];
}
