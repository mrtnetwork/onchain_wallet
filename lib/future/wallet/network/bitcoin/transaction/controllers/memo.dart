import 'package:blockchain_utils/utf8/src/encoder.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';

mixin BitcoinTransactionMempController on BaseBitcoinTransactionController {
  final LiveFormFields<BitcoinMemo> memos =
      LiveFormFields(title: "setup_memo".tr, subtitle: "memo_desc2".tr);
  int? get opReturnLength => network.coinParam.maxMemoLength;
  bool get allowMultipleOpReturn => network.coinParam.supportMultipleOpReturn;
  bool get canAddNewMemo => allowMultipleOpReturn || memos.value.isEmpty;

  bool onUpdateMemo(String? memo) {
    if (memo == null || onValidateMemo(memo) != null) {
      return false;
    }
    memos.addValue(BitcoinMemo(memo));
    return true;
  }

  String? onValidateMemo(String? memo) {
    final length = opReturnLength;
    if (length == null || memo == null) return null;
    final inBytesLength = switch (StringUtils.isHexBytes(memo)) {
      true => memo.length ~/ 2,
      false => UTF8Encoder.inBytesLength(memo),
    };
    if (inBytesLength <= length) return null;
    return "op_return_length_validator".tr.replaceOne(length.toString());
  }

  void onRemoveMemo(BitcoinMemo memo) {
    memos.removeValue(memo);
  }

  @override
  void dispose() {
    super.dispose();
    memos.clear();
    memos.dispose();
  }
}
