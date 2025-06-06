import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/ripple/forms/core/ripple.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/core/core.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/crypto/utils/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class RippeBurnTokenForm extends RippleOperationTransactionForm {
  RippeBurnTokenForm({String? offerID}) {
    if (offerID != null) {
      setValue(nftokenId, offerID);
    }
  }

  final TransactionFormField<String> nftokenId = TransactionFormField(
    name: "token_id",
    subject: "ripple_nftoken_burn_id",
    id: "burn_token_id",
    optional: false,
    onChangeForm: (v) {
      return QuickBytesUtils.ensureIsHash256(v);
    },
  );
  final TransactionFormField<ReceiptAddress> owner = TransactionFormField(
    name: "owner",
    id: "burn_owner",
    subject: "ripple_nftoken_burn_owner",
    onChangeForm: (v) {
      if (RippleUtils.ensureIsRippleAddress(v!.view) == null) return null;
      return v;
    },
  );

  @override
  String? validateError() {
    for (final i in fields) {
      if (!i.optional && !i.hasValue) {
        return "field_is_req".tr.replaceOne(i.name);
      }
    }
    return toTransaction().validate;
  }

  @override
  List<TransactionFormField> get fields => [nftokenId, owner];

  @override
  XRPTransaction toTransaction(
      {List<XRPLMemo> memos = const [], XRPLSignature? signer, BigInt? fee}) {
    return NFTokenBurn(
      account: address.networkAddress.toAddress(),
      sourceTag: address.networkAddress.tag,
      memos: RippleUtils.toXrplMemos(memos),
      fee: fee,
      nfTokenId: nftokenId.value!,
      owner: owner.value?.view,
    );
  }

  @override
  void setValue<T>(TransactionFormField<T>? field, T? value) {
    if (field == null) return;
    if (field.setValue(value)) {
      onChanged?.call();
    }
  }

  @override
  String get name => "NFTokenBurn";

  @override
  String get validatorName => "ripple_nftoken_burn_fields";
  @override
  String get helperUri => RippleConst.aboutNftokenBurn;
  @override
  String get validatorDescription => "ripple_nftoken_burn_desc";

  @override
  void removeIndex<T>(TransactionFormField<List<T>> field, int index) {}

  @override
  void setListValue<T>(TransactionFormField<List<T>> field, T? value) {}

  @override
  XRPLTransactionType get transactionType => XRPLTransactionType.nftokenBurn;
}
