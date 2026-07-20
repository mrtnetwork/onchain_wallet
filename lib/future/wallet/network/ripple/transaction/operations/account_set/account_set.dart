import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/widgets/account_set/account_set.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionAccountSetOperation
    extends RippleTransactionStateController<AccountSet> {
  RippleTransactionAccountSetOperation._(
      {required super.walletProvider, required super.account, required super.address});
  factory RippleTransactionAccountSetOperation(
      {required WalletProvider walletProvider,
      required XRPChain account,
      required IXRPAddress address}) {
    return RippleTransactionAccountSetOperation._(
        walletProvider: walletProvider, account: account, address: address);
  }
  final LiveFormField<AccountSetAsfFlag?, AccountSetAsfFlag> setFlag = LiveFormField(
    title: "ripple_enable_account_set_flags".tr,
    optional: true,
    value: null,
  );
  final LiveFormField<AccountSetAsfFlag?, AccountSetAsfFlag> clearFlag = LiveFormField(
      title: "ripple_disable_account_set_flags".tr, optional: true, value: null);

  final LiveFormField<String?, String> domain = LiveFormField(
      title: "domain".tr, subtitle: "domain_desc".tr, optional: true, value: null);

  final LiveFormField<String?, String> email = LiveFormField(
      title: "email_hash".tr,
      subtitle: "ripple_email_hash_desc".tr,
      optional: true,
      value: null);
  late final LiveFormField<String?, String> messageKey = LiveFormField(
    title: "ripple_message_key".tr,
    subtitle: "ripple_message_key_desc".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      if (validateMessageKey(current) == null) return true;
      return false;
    },
  );
  final LiveFormField<ReceiptAddress<XRPBaseAddress>?, ReceiptAddress<XRPBaseAddress>>
      nftokenMinter = LiveFormField(
          title: "ripple_nft_token_minter".tr,
          subtitle: "ripple_nft_token_minter_desc".tr,
          optional: true,
          value: null);
  late final LiveFormField<BigRational?, BigRational> transferRate = LiveFormField(
    title: "ripple_transfer_rate".tr,
    subtitle: "ripple_transfer_rate_desc".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      return validateTransferRate(current.toDecimal()) == null;
    },
  );
  late final LiveFormField<BigRational?, BigRational> tickSize = LiveFormField(
    title: "ripple_tick_size".tr,
    subtitle: "ripple_tick_size_desc".tr,
    optional: true,
    value: null,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      return validateTickSize(current.toDecimal()) == null;
    },
  );

  void onUpdateSetFlag(AccountSetAsfFlag? flag) {
    setFlag.setValue(flag);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateClearFlag(AccountSetAsfFlag? flag) {
    clearFlag.setValue(flag);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateDomain(String? domain) {
    this.domain.setValue(domain);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateEmail(String? email) {
    this.email.setValue(email);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateMessageKey(String? messageKey) {
    this.messageKey.setValue(messageKey);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateNFTokenMinter(ReceiptAddress<XRPBaseAddress>? nftokenMinter) {
    this.nftokenMinter.setValue(nftokenMinter);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateTransferRate(BigRational? transferRate) {
    this.transferRate.setValue(transferRate);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateTickSize(BigRational? tickSize) {
    this.tickSize.setValue(tickSize);
    onStateUpdated();
    estimateFee();
  }

  String? validateMessageKey(String? v) {
    if (v == null) return "ripple_public_key".tr;
    if (v.isEmpty) return null;
    final isValid = RippleUtils.validateRipplePublicKey(v);
    if (isValid == null) return "ripple_public_key".tr;
    return null;
  }

  String? validateTransferRate(String? v) {
    final BigRational? rate = BigRational.tryParse(v ?? "");
    final valid = RippleUtils.validateAccoutSetTransferRate(rate);
    if (valid == null) {
      return "ripple_validate_transfer_rate".tr;
    }
    return null;
  }

  String? validateTickSize(String? v) {
    final BigRational? rate = BigRational.tryParse(v ?? "");
    final valid = RippleUtils.validateAccoutSetTickSize(rate);
    if (valid == null) {
      return "ripple_validate_tick_size".tr;
    }
    return null;
  }

  @override
  AccountSet buildTransactionInternal() {
    return AccountSet(
      account: address.networkAddress.classicAddress,
      setFlag: setFlag.value,
      clearFlag: clearFlag.value,
      domain: domain.hasValue ? QuickBytesUtils.ensureIsHex(domain.value!) : null,
      emailHash: email.hasValue
          ? QuickBytesUtils.stringToHexWithLength(
              email.value!, RippleConst.maxEmailHashLength)
          : null,
      fee: txFee.fee.fee.balance,
      memos: RippleUtils.toXrplMemos(memos),
      messageKey: messageKey.value,
      nftTokenMinter: nftokenMinter.value?.networkAddress.classicAddress,
      tickSize: tickSize.value?.toBigInt().toInt(),
      transferRate: transferRate.value?.toBigInt().toInt(),
    );
  }

  @override
  Future<TransactionStateController> cloneController(IXRPAddress address) async {
    return RippleTransactionAccountSetOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return RippleTransactionAccountSetWidget(form: this);
  }

  @override
  SubmittableTransactionType get transactionType => SubmittableTransactionType.accountSet;
  @override
  List<LiveFormField<Object?, Object>> get fields => [
        setFlag,
        clearFlag,
        domain,
        email,
        messageKey,
        nftokenMinter,
        transferRate,
        tickSize
      ];
}
