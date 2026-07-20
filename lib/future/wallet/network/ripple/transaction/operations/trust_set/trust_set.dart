import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/trust_set/trust_set.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionTrustSetOperation
    extends RippleTransactionStateController<TrustSet> {
  final CachedObject<List<RippleIssueToken>> tokens = CachedObject();
  RippleTransactionTrustSetOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionTrustSetOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionTrustSetOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }

  final LiveFormField<RippleIssueToken?, RippleIssueToken> token = LiveFormField(
      title: "token".tr,
      subtitle: "ripple_choose_token_for_trust_path".tr,
      optional: false,
      value: null);

  final LiveFormField<DecimalBalance?, DecimalBalance> amount = LiveFormField(
      title: "amount".tr, subtitle: "trust_line_limit".tr, optional: false, value: null);

  final LiveFormField<BigRational?, BigRational> qualityIn = LiveFormField(
      title: "trust_set_quality_in".tr,
      subtitle: "trust_set_quality_in_desc".tr,
      optional: true,
      value: null);
  final LiveFormField<BigRational?, BigRational> qualityOut = LiveFormField(
      title: "trust_set_quality_out".tr,
      subtitle: "trust_set_quality_out_desc".tr,
      optional: true,
      value: null);
  final LiveFormField<TrustSetFlag?, TrustSetFlag> flag = LiveFormField(
      title: "trust_set_flags".tr,
      subtitle: "ripple_trust_set_flags".tr,
      optional: true,
      value: null);

  void onUpdateToken(RipplePickedAsset? asset) {
    if (asset == null) return;
    final token = asset.issueToken;
    if (token == null) return;
    this.token.setValue(token);
    amount.setValue(DecimalBalance.fromRational(token.token, BigRational.zero));
    onStateUpdated();
    estimateFee();
  }

  void onUpdateFlag(TrustSetFlag? flag) {
    this.flag.setValue(flag);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateQualityOut(BigRational? qualityOut) {
    this.qualityOut.setValue(qualityOut);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateQualityIn(BigRational? qualityIn) {
    this.qualityIn.setValue(qualityIn);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmount(BigRational? amount) {
    if (amount == null) return;
    this.amount.value?.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  @override
  TrustSet buildTransactionInternal() {
    final token = this.token.output;
    return TrustSet(
      limitAmount: IssuedCurrencyAmount(
          value: amount.output.balance.toDecimal(),
          currency: token.assetCode,
          issuer: token.issuer),
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
      qualityIn: qualityIn.value?.toBigInt().toInt(),
      qualityOut: qualityOut.value?.toBigInt().toInt(),
      flags: [flag.value?.value ?? 0],
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionTrustSetOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionTrustSetWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType => SubmittableTransactionType.trustSet;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required XRPNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    tokens
        .get(onFetch: () async => client.accountTokens(address))
        .catchError((_) => <RippleIssueToken>[]);
    return this;
  }

  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [amount, qualityIn, qualityOut, flag, token];
}
