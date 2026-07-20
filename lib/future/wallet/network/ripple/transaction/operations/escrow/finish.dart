import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/escrow/finish.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionEscrowFinishOperation
    extends RippleTransactionStateController<EscrowFinish> {
  RippleTransactionEscrowFinishOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionEscrowFinishOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionEscrowFinishOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }
  final LiveFormField<ReceiptAddress<XRPBaseAddress>?, ReceiptAddress<XRPBaseAddress>>
      owner = LiveFormField(
    title: "owner".tr,
    subtitle: "ripple_escrow_finish_owner".tr,
    optional: false,
    value: null,
  );

  final LiveFormField<BigRational?, BigRational> offerSequence = LiveFormField(
    title: "OfferSequence",
    subtitle: "ripple_escrow_finish_sequence".tr,
    optional: false,
    value: null,
  );

  final LiveFormField<String?, String> condition = LiveFormField(
    title: "condition".tr,
    subtitle: "ripple_escrow_finish_condition".tr,
    optional: true,
    value: null,
  );
  final LiveFormField<String?, String> fulfillment = LiveFormField(
      title: "Fulfillment",
      subtitle: "ripple_escrow_finish_fulfillment".tr,
      optional: true,
      value: null);

  void onUpdateFulfillment(String? fulfillment) {
    this.fulfillment.setValue(fulfillment);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateCondition(String? condition) {
    this.condition.setValue(condition);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateOfferSequence(BigRational? offerSequence) {
    if (offerSequence == null) return;
    this.offerSequence.setValue(offerSequence);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateOwner(ReceiptAddress<XRPBaseAddress>? address) {
    if (address == null) return;
    owner.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  @override
  EscrowFinish buildTransactionInternal() {
    return EscrowFinish(
      offerSequence: offerSequence.value!.toBigInt().toInt(),
      owner: owner.value!.view,
      fulfillment: fulfillment.value,
      condition: condition.value,
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionEscrowFinishOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionEscrowFinishWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.escrowFinish;
  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [owner, offerSequence, condition, fulfillment];
}
