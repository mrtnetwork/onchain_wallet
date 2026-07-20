import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/nfts/mint.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionNFTokenMintOperation
    extends RippleTransactionStateController<NFTokenMint> {
  RippleTransactionNFTokenMintOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionNFTokenMintOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionNFTokenMintOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }

  late final LiveFormField<BigRational?, BigRational> nftokenTaxon = LiveFormField(
    title: "NFTokenTaxon",
    subtitle: "ripple_nftokentaxon".tr,
    optional: false,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      if (current.isNegative) return false;
      if (current > RippleConst.max32UnsignedRational) return false;
      return true;
    },
  );

  final LiveFormField<ReceiptAddress<XRPBaseAddress>?, ReceiptAddress<XRPBaseAddress>>
      issuer = LiveFormField(
    title: "issuer".tr,
    subtitle: "ripple_mint_token_issuer".tr,
    optional: true,
    value: null,
  );

  late final LiveFormField<BigRational?, BigRational> transferFee = LiveFormField(
    title: "ripple_transfer_rate".tr,
    subtitle: "ripple_mint_token_transfer_rate".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      if (current.isNegative) return false;
      if (current > RippleConst.maxNftTokenTransferRate) return false;
      return true;
    },
  );

  final LiveFormField<String?, String> uri = LiveFormField(
    title: "uri".tr,
    subtitle: "nft_token_uri".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      if (current.length > RippleConst.maxDomainLength) return false;
      return true;
    },
  );

  final LiveFormField<NFTokenMintFlag?, NFTokenMintFlag> flags = LiveFormField(
      title: "NFTokenMintFlag",
      subtitle: "nft_flags_field_desc".tr,
      optional: true,
      value: null);

  void onUpdateUri(String? uri) {
    this.uri.setValue(uri);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateIssuer(ReceiptAddress<XRPBaseAddress>? address) {
    issuer.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateNFTokenTaxon(BigRational? tax) {
    if (tax == null) return;
    nftokenTaxon.setValue(tax);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateTransferFee(BigRational? transferFee) {
    this.transferFee.setValue(transferFee);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateFlag(NFTokenMintFlag? flags) {
    this.flags.setValue(flags);
    onStateUpdated();
    estimateFee();
  }

  @override
  NFTokenMint buildTransactionInternal() {
    return NFTokenMint(
      nftokenTaxon: nftokenTaxon.value!.toBigInt().toInt(),
      account: address.networkAddress.address,
      sourceTag: address.networkAddress.tag,
      issuer: issuer.value?.networkAddress.classicAddress,
      flags: flags.value?.value == null ? null : [flags.value!.value],
      uri: uri.value == null ? null : QuickBytesUtils.ensureIsHex(uri.value!),
      memos: RippleUtils.toXrplMemos(memos),
      fee: txFee.fee.fee.balance,
      transferFee: transferFee.value?.toBigInt().toInt(),
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionNFTokenMintOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionNFTokenMintWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType =>
      SubmittableTransactionType.nftokenMint;
  @override
  List<LiveFormField<Object?, Object>> get fields => [
        nftokenTaxon,
        issuer,
        transferFee,
        uri,
        flags,
      ];
}
