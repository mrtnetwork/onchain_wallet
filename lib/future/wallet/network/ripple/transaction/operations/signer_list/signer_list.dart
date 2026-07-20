import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/signer_list/signer_list.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionSignerListSetOperation
    extends RippleTransactionStateController<SignerListSet> {
  RippleTransactionSignerListSetOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionSignerListSetOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionSignerListSetOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }
  final LiveFormFields<XRPSignerEntries> signerEntries = LiveFormFields(
      title: "SignerEntries", subtitle: "ripple_signer_entries_desc".tr, optional: true);
  final LiveFormField<BigRational?, BigRational> signerQuorum = LiveFormField(
    title: "signerquorum".tr,
    subtitle: "ripple_signer_quorum_desc".tr,
    optional: false,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) {
        return false;
      }
      if (current.isNegative) return false;
      if (current > RippleConst.max32UnsignedRational) return false;
      return true;
    },
  );

  void onUpdateSignerEntries(XRPSignerEntries? signer) {
    if (signer == null) return;
    signerEntries.addValue(signer);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveSignerEntries(XRPSignerEntries signer) {
    signerEntries.removeValue(signer);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateSignerQuorum(BigRational? signerQuorum) {
    this.signerQuorum.setValue(signerQuorum);
    onStateUpdated();
    estimateFee();
  }

  @override
  SignerListSet buildTransactionInternal() {
    return SignerListSet(
        signerEntries: signerEntries.value
            .map((e) => SignerEntry(
                account: e.address.networkAddress.classicAddress,
                signerWeight: e.weight.toBigInt().toInt()))
            .toList(),
        signerQuorum: signerQuorum.value!.toBigInt().toInt(),
        account: address.networkAddress.address,
        sourceTag: address.networkAddress.tag,
        memos: RippleUtils.toXrplMemos(memos),
        fee: txFee.fee.fee.balance);
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionSignerListSetOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionSignerListSetWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.signerListSet;
  @override
  List<LiveFormField<Object?, Object>> get fields => [signerEntries, signerQuorum];
}
