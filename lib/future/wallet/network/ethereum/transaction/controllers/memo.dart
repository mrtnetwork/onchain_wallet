import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';

mixin EthereumTransactionMemoController<T extends IEthereumTransactionData>
    on BaseEthereumTransactionController<T> {
  final LiveFormField<String?, String> memo = LiveFormField(
      title: "setup_memo".tr, subtitle: "memo_desc2".tr, value: null, optional: true);
  List<int>? memoBytes() {
    final memo = this.memo.value;
    if (memo == null) return null;
    return StringUtils.toBytes(memo);
  }

  bool onUpdateMemo(String? memo) {
    if (memo == null) return false;
    this.memo.setValue(memo);
    return true;
  }

  void onRemoveMemo() {
    memo.setValue(null);
  }
}
