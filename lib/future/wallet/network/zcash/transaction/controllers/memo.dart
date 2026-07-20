import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:zcash_dart/zcash.dart';

mixin ZcashTransactionMemoController<T extends IZcashTransactionData>
    on BaseZcashTransactionController<T> {
  final LiveFormFields<ZcashTransactionTransparentMemo> memos = LiveFormFields(
      title: "setup_memo".tr, subtitle: "memo_attached_to_transparent_output".tr);
  int? get opReturnLength => TransparentBuilderConstant.maxOpReturn;
  bool get allowMultipleOpReturn => false;
  bool get canAddNewMemo => allowMultipleOpReturn || memos.value.isEmpty;

  bool onUpdateMemo(String? memo) {
    if (memo == null || onValidateMemo(memo) != null) {
      return false;
    }
    memos.addValue(
        ZcashTransactionTransparentMemo(ZcashTransactionMemoTransparent.fromMemo(memo)));
    return true;
  }

  String? onValidateMemo(String? memo) {
    final length = opReturnLength;
    if (length == null || memo == null) return null;
    final inBytesLength = StrUtils.getStringBytesLength(memo);
    if (inBytesLength <= length) return null;
    return "op_return_length_validator".tr.replaceOne(length.toString());
  }

  void onRemoveMemo(ZcashTransactionTransparentMemo memo) {
    memos.removeValue(memo);
  }

  @override
  void dispose() {
    super.dispose();
    memos.clear();
    memos.dispose();
  }
}
