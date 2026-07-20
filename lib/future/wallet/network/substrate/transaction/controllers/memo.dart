import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';

mixin SubstrateTransactionMemoController on DisposableMixin {
  final LiveFormFields<String> memos =
      LiveFormFields<String>(title: "setup_memo".tr, optional: true);

  void onUpdateMemo(String? memo) {
    if (memo == null) return;
    memos.addValue(memo);
    // onStateUpdated();
  }

  void onRemoveMemo(String memo) {
    memos.removeValue(memo);
    // onStateUpdated();
  }

  @override
  void dispose() {
    super.dispose();
    memos.dispose();
  }
}
