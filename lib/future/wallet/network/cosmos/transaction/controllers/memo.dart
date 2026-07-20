import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';

mixin CosmosTransactionMemoController on DisposableMixin {
  final LiveFormField<String?, String?> memo = LiveFormField(
      title: "setup_memo".tr, subtitle: "memo_desc2".tr, value: null, optional: true);

  bool onUpdateMemo(String? memo) {
    if (memo == null) return false;
    final String? currentMemo = this.memo.value;
    this.memo.setValue(memo);
    return currentMemo != this.memo.value;
  }

  void onRemoveMemo() {
    memo.setValue(null);
  }

  @override
  void dispose() {
    super.dispose();
    memo.dispose();
  }
}
