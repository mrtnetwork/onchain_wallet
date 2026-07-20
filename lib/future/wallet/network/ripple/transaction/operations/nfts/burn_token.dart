import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/nfts/burn.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionNFTokenBurnOperation
    extends RippleTransactionStateController<NFTokenBurn> {
  RippleTransactionNFTokenBurnOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionNFTokenBurnOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address,
      String? nftId}) {
    final intance = RippleTransactionNFTokenBurnOperation._(
        walletProvider: walletProvider, account: account, address: address);
    if (nftId != null) {
      intance.onUpdateNFTokenId(nftId);
    }
    return intance;
  }

  late final LiveFormField<String?, String> nftokenId = LiveFormField(
    title: "token_id".tr,
    subtitle: "ripple_nftoken_burn_id".tr,
    optional: false,
    value: null,
    onUpdateValue: (previous, current) {
      return QuickBytesUtils.ensureIsHash256(current) != null;
    },
  );

  final LiveFormField<ReceiptAddress<XRPBaseAddress>?, ReceiptAddress<XRPBaseAddress>>
      owner = LiveFormField(
    title: "owner".tr,
    subtitle: "ripple_nftoken_burn_owner".tr,
    optional: true,
    value: null,
  );
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

  @override
  NFTokenBurn buildTransactionInternal() {
    return NFTokenBurn(
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
      nfTokenId: nftokenId.value!,
      owner: owner.value?.view,
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionNFTokenBurnOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionNFTokenBurnWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.nftokenBurn;
  @override
  List<LiveFormField<Object?, Object>> get fields => [nftokenId, owner];
}
