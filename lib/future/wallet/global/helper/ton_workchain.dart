import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:ton_dart/ton_dart.dart';

extension ExtUtxoTimelockTranslate on TonWorkChain {
  String name() {
    if (this == TonWorkChain.masterchain) return "masterchain".tr;
    if (this == TonWorkChain.basechain) return "basechain".tr;
    return id.toString();
  }
}
