import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/nfts/cancel.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionNFTokenCancelOfferOperation
    extends RippleTransactionStateController<NFTokenCancelOffer> {
  RippleTransactionNFTokenCancelOfferOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionNFTokenCancelOfferOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address,
      String? nftId}) {
    final intance = RippleTransactionNFTokenCancelOfferOperation._(
        walletProvider: walletProvider, account: account, address: address);
    if (nftId != null) {
      intance.onUpdateNFTokenOffsers(nftId);
    }
    return intance;
  }

  late final LiveFormFields<String> nftokenOffers = LiveFormFields(
    title: "NFTokenOffers",
    subtitle: "ripple_cancel_nft_token_nftoken_offers".tr,
    optional: false,
    onUpdateValueFields: (value) {
      return QuickBytesUtils.ensureIsHash256(value) != null;
    },
  );
  void onUpdateNFTokenOffsers(String? tokenId) {
    if (tokenId == null) return;
    nftokenOffers.addValue(tokenId);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveNFTokenOffsers(String tokenId) {
    nftokenOffers.removeValue(tokenId);
    onStateUpdated();
    estimateFee();
  }

  @override
  NFTokenCancelOffer buildTransactionInternal() {
    return NFTokenCancelOffer(
        account: address.networkAddress.address,
        sourceTag: address.networkAddress.tag,
        memos: RippleUtils.toXrplMemos(memos),
        fee: txFee.fee.fee.balance,
        nftokenOffers: nftokenOffers.value);
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionNFTokenCancelOfferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionNFTokenCancelOfferWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.nftokenCancelOffer;
  @override
  List<LiveFormField<Object?, Object>> get fields => [nftokenOffers];
}
