import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/nfts/create.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionNFTokenCreateOfferOperation
    extends RippleTransactionStateController<NFTokenCreateOffer> {
  RippleTransactionNFTokenCreateOfferOperation._(
      {required super.walletProvider, required super.account, required super.address});
  final CachedObject<List<RippleIssueToken>> tokens = CachedObject();
  factory RippleTransactionNFTokenCreateOfferOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address,
      String? nftId}) {
    final intance = RippleTransactionNFTokenCreateOfferOperation._(
        walletProvider: walletProvider, account: account, address: address);
    if (nftId != null) {
      intance.onUpdateNFTokenId(nftId);
    }
    return intance;
  }
  late final LiveFormField<String?, String> nftokenId = LiveFormField(
    title: "token_id".tr,
    subtitle: "ripple_create_nft_offer_id".tr,
    optional: false,
    value: null,
    onUpdateValue: (previous, current) {
      return QuickBytesUtils.ensureIsHash256(current) != null;
    },
  );

  late final LiveFormField<ReceiptAddress<XRPBaseAddress>?,
      ReceiptAddress<XRPBaseAddress>> owner = LiveFormField(
    title: "owner".tr,
    subtitle: "ripple_create_offer_owner".tr,
    optional: true,
    value: null,
  );

  final LiveFormField<DateTime?, DateTime> expiration = LiveFormField(
    title: "expiration".tr,
    subtitle: "ripple_create_offer_expiration".tr,
    optional: true,
    value: null,
  );
  late final LiveFormField<ReceiptAddress<XRPBaseAddress>?,
      ReceiptAddress<XRPBaseAddress>> destination = LiveFormField(
    title: "destination".tr,
    subtitle: "ripple_create_offer_destination".tr,
    optional: true,
    value: null,
  );

  final LiveFormField<RipplePickedAsset?, RipplePickedAsset> token = LiveFormField(
    title: "token".tr,
    subtitle: "token_to_offer".tr,
    optional: false,
    value: null,
  );

  late final LiveFormField<BalanceCore?, BalanceCore> amount = LiveFormField(
    title: "amount".tr,
    subtitle: "offer_amount".tr,
    optional: false,
    value: null,
    onValidateError: (field, value) {
      if (token.value == null) return null;
      if (value?.largerThanZero ?? false) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  final LiveFormField<NftTokenCreateOfferFlag?, NftTokenCreateOfferFlag> flags =
      LiveFormField(
    title: "NFTokenCreateOfferFlags",
    subtitle: "nft_offer_flag_desc".tr,
    optional: true,
    value: NftTokenCreateOfferFlag.tfSellNftoken,
  );

  void onUpdateToken(RipplePickedAsset? token) {
    if (token == null) return;
    this.token.setValue(token);
    if (token.type.isNative) {
      amount.setValue(IntegerBalance.zero(network.token));
    } else {
      amount.setValue(DecimalBalance.zero(token.issueToken!.token));
    }
    onStateUpdated();
    estimateFee();
  }

  void onUpdateNFTokenId(String? tokenId) {
    nftokenId.setValue(tokenId);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateOwner(ReceiptAddress<XRPBaseAddress>? address) {
    owner.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateDestination(ReceiptAddress<XRPBaseAddress>? address) {
    destination.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateExpiration(DateTime? expiration) {
    this.expiration.setValue(expiration);
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
  NFTokenCreateOffer buildTransactionInternal() {
    final token = this.token.output;
    final amount = this.amount.output;
    BaseAmount rippleAmount;
    if (token.type.isNative) {
      rippleAmount = XRPAmount((amount as IntegerBalance).balance);
    } else {
      rippleAmount = IssuedCurrencyAmount(
          value: (amount as DecimalBalance).balance.toDecimal(),
          currency: token.issueToken!.assetCode,
          issuer: token.issueToken!.issuer);
    }
    return NFTokenCreateOffer(
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
      flags: flags.value?.value == null ? null : [flags.value!.value],
      amount: rippleAmount,
      nftokenId: nftokenId.value!,
      destination: destination.value?.networkAddress.classicAddress,
      expiration:
          expiration.hasValue ? XRPHelper.datetimeToRippleTime(expiration.value!) : null,
      owner: owner.value?.networkAddress.classicAddress,
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionNFTokenCreateOfferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionNFTokenCreateOfferWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.nftokenCreateOffer;

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
      [nftokenId, owner, expiration, destination, token, amount, flags];
}
