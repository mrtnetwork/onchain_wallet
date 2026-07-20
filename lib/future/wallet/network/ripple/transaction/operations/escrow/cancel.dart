import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/escrow/cancel.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionEscrowCancelOperation
    extends RippleTransactionStateController<EscrowCancel> {
  RippleTransactionEscrowCancelOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionEscrowCancelOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionEscrowCancelOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }
  final LiveFormField<ReceiptAddress<XRPBaseAddress>?, ReceiptAddress<XRPBaseAddress>>
      owner = LiveFormField(
    title: "owner".tr,
    subtitle: "ripple_escrow_cancel_owner".tr,
    optional: false,
    value: null,
  );

  late final LiveFormField<BigRational?, BigRational> offerSequence = LiveFormField(
    title: "OfferSequence",
    subtitle: "ripple_escrow_cancel_offer_sequence".tr,
    optional: false,
    value: null,
  );

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
  EscrowCancel buildTransactionInternal() {
    return EscrowCancel(
      offerSequence: offerSequence.value!.toBigInt().toInt(),
      owner: owner.value!.view,
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionEscrowCancelOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionEscrowCancelWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.escrowCancel;
  @override
  List<LiveFormField<Object?, Object>> get fields => [owner, offerSequence];
}
