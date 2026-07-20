import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/nfts/accept.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionNFTAcceptOfferOperation
    extends RippleTransactionStateController<NFTokenAcceptOffer> {
  final CachedObject<List<RippleIssueToken>> tokens = CachedObject();
  RippleTransactionNFTAcceptOfferOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionNFTAcceptOfferOperation({
    required WalletProvider walletProvider,
    required XRPChain account,
    required IXRPAddress address,
  }) {
    return RippleTransactionNFTAcceptOfferOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }

  late final LiveFormField<String?, String> nftokenSellOffer = LiveFormField(
    title: "NFTokenSellOffer",
    subtitle: "ripple_accept_offer_sell_offer".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      return QuickBytesUtils.ensureIsHash256(current) != null;
    },
  );

  late final LiveFormField<String?, String> nftokenBuyOffer = LiveFormField(
    title: "NFTokenBuyOffer",
    subtitle: "ripple_accept_offer_buy_offer".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      return QuickBytesUtils.ensureIsHash256(current) != null;
    },
  );

  final LiveFormField<RipplePickedAsset?, RipplePickedAsset?> token = LiveFormField(
    title: "token".tr,
    subtitle: "ripple_accept_offer_broker_fee".tr,
    optional: true,
    value: null,
  );

  final LiveFormField<BalanceCore?, BalanceCore?> amount =
      LiveFormField(title: "amount".tr, optional: true, value: null);

  void onUpdateToken(RipplePickedAsset? token) {
    if (token == null) {
      this.token.setValue(null);
      amount.setValue(null);
    } else {
      this.token.setValue(token);
      if (token.type.isNative) {
        amount.setValue(IntegerBalance.zero(network.token));
      } else {
        amount.setValue(DecimalBalance.zero(token.issueToken!.token));
      }
    }
    onStateUpdated();
    estimateFee();
  }

  void onUpdateNFTokenSellOffer(String? tokenId) {
    nftokenSellOffer.setValue(tokenId);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateNFTokenBuyOffer(String? tokenId) {
    nftokenBuyOffer.setValue(tokenId);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmountXrp(BigInt amount) {
    final a = this.amount.output as IntegerBalance;
    a.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmountIssue(BigRational amount) {
    final a = this.amount.output as DecimalBalance;
    a.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  @override
  NFTokenAcceptOffer buildTransactionInternal() {
    final token = this.token.output;
    final amount = this.amount.output;
    BaseAmount? rippleAmount;
    if (token != null) {
      if (token.type.isNative) {
        rippleAmount = XRPAmount((amount as IntegerBalance).balance);
      } else {
        rippleAmount = IssuedCurrencyAmount(
            value: (amount as DecimalBalance).balance.toDecimal(),
            currency: token.issueToken!.assetCode,
            issuer: token.issueToken!.issuer);
      }
    }
    return NFTokenAcceptOffer(
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
      nfTokenBrokerFee: rippleAmount,
      nfTokenBuyOffer: nftokenBuyOffer.value,
      nfTokenSellOffer: nftokenSellOffer.value,
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionNFTAcceptOfferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionNFTAcceptOfferWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.nftokenAcceptOffer;

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
  List<LiveFormField<Object?, Object?>> get fields =>
      [nftokenSellOffer, nftokenBuyOffer, token, amount];
}
