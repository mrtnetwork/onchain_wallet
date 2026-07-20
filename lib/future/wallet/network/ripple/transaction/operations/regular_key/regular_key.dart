import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/regular_key/regular_key.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionSetRegularKeyOperation
    extends RippleTransactionStateController<SetRegularKey> {
  RippleTransactionSetRegularKeyOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionSetRegularKeyOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionSetRegularKeyOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }
  final LiveFormField<ReceiptAddress<XRPBaseAddress>?, ReceiptAddress<XRPBaseAddress>>
      regularKey = LiveFormField(
          title: "regular_key".tr,
          subtitle: "ripple_regular_key_field_desc".tr,
          optional: true,
          value: null);

  void onUpdateRegularKey(ReceiptAddress<XRPBaseAddress>? address) {
    regularKey.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  @override
  SetRegularKey buildTransactionInternal() {
    return SetRegularKey(
        regularKey: regularKey.value?.networkAddress.classicAddress,
        account: address.networkAddress.address,
        sourceTag: address.networkAddress.tag,
        memos: RippleUtils.toXrplMemos(memos),
        fee: txFee.fee.fee.balance);
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionSetRegularKeyOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionSetRegularKeyWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.setRegularKey;
  @override
  List<LiveFormField<Object?, Object>> get fields => [regularKey];
}
