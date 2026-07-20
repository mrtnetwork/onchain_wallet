import 'dart:async';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/create_witness.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionWitnessCreateContractOperation
    extends TronTransactionStateController2<WitnessCreateContract> {
  TronTransactionWitnessCreateContractOperation(
      {required super.walletProvider,
      required super.account,
      required super.address});

  final LiveFormField<String?, String> url = LiveFormField(
      title: "url".tr,
      subtitle: "tron_create_witness_url_desc".tr,
      value: null,
      optional: true);
  void onUpdateUrl(String? url) {
    this.url.setValue(url);
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ITronTransactionData<WitnessCreateContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
        fee: txFee.fee,
        blockData: blockData,
        memo: memo.value,
        contract: WitnessCreateContract(
            ownerAddress: address.networkAddress,
            url: StringUtils.tryToBytes(url.value)));
  }

  @override
  Future<TransactionStateController> cloneController(
      ITronAddress address) async {
    return TronTransactionWitnessCreateContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionWitnessCreateContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.witnessCreateContract;

  @override
  List<LiveFormField<Object?, Object>> get fields => [url];
}
