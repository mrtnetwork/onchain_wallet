import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/wallet/models/block/block.dart';

extension ExtBlockSyncTranslate on BlockSyncStatus {
  String get translate {
    return switch (this) {
      BlockSyncStatusSynced() => "synced".tr,
      BlockSyncStatusError() => "an_error_during_block_scanning".tr,
      BlockSyncStatusPending() => "syncing".tr,
    };
  }

  String? get errorMessage {
    return switch (this) {
      BlockSyncStatusSynced() => null,
      BlockSyncStatusError(:final error) => switch (error) {
          BaseAppException exp when !exp.localizedMessage => exp.message.tr,
          _ => error.message
        },
      BlockSyncStatusPending() => null,
    };
  }
}
