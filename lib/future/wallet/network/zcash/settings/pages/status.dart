import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/extension/extensions.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';

class BlockSyncStatusIcon extends StatelessWidget {
  final BlockSyncStatus status;
  final Color? color;
  const BlockSyncStatusIcon({required this.status, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return ToolTipView(
        message: switch (status) {
          BlockSyncStatusError() => status.errorMessage,
          _ => status.translate
        },
        child: switch (status) {
          BlockSyncStatusSynced() => Icon(Icons.check_circle, color: color),
          BlockSyncStatusError() => Icon(Icons.error, color: context.colors.error),
          BlockSyncStatusPending() => Icon(Icons.sync, color: color),
        });
  }
}
