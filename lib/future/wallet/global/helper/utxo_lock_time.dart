import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/date_time.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/widgets/widgets/tooltip/tooltip.dart';
import 'package:on_chain_wallet/wallet/models/others/models/utxo_timelock.dart';

extension ExtUtxoTimelockTranslate on UtxoTimelock {
  Widget tooltip(Color color) {
    final icon = switch (this) {
      UtxosTimelockUnknown() => Icons.help_outline,
      UtxosTimelockConfirmed() => Icons.check_circle,
      UtxoTimelockBlock() => Icons.lock_clock,
      UtxoTimelockTimestamp() => Icons.schedule,
      UtxosTimelockMempool() => Icons.lock_clock,
    };

    return ToolTipView(
      message: message(),
      child: Icon(icon, color: color),
    );
  }

  String message() {
    if (confirmed) return "utxos_confirmed".tr;
    return switch (this) {
      UtxosTimelockUnknown() => "unknown_timelock_status".tr,
      UtxosTimelockConfirmed() => "utxos_confirmed".tr,
      UtxoTimelockBlock(:final remainingBlocks) =>
        "utxo_will_unlock_after_n_block".tr.replaceOne(remainingBlocks.toString()),
      UtxoTimelockTimestamp(:final remaining) =>
        "utxo_will_unlock_after_n_time".tr.replaceOne(remaining.remainingTime()),
      UtxosTimelockMempool() => "utxos_is_not_confirmed_yet".tr
    };
  }
}
