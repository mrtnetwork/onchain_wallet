import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/progress_bar/widgets/stream_bottun.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:stellar_dart/stellar_dart.dart';

extension AccountReceivementStatusExtension on AccountReceivementStatus {
  StreamWidgetStatus get toProgressStatus {
    switch (this) {
      case AccountReceivementStatus.idle:
        return StreamWidgetStatus.idle;
      case AccountReceivementStatus.error:
        return StreamWidgetStatus.error;
      case AccountReceivementStatus.pending:
        return StreamWidgetStatus.progress;
      default:
        return StreamWidgetStatus.success;
    }
  }

  String? get message {
    switch (this) {
      case AccountReceivementStatus.idle:
        return null;
      case AccountReceivementStatus.error:
        return "retrieve_account_activity_failed".tr;
      case AccountReceivementStatus.pending:
        return null;
      case AccountReceivementStatus.inactive:
        return "recipient_account_inactive".tr;
      default:
        return "recipient_account_active".tr;
    }
  }
}

mixin StellarOperationDestinationTracker<T extends StatefulWidget>
    on SafeState<T> {
  StellarReceiptWithActivityStatus? receiver;
  StellarPickedIssueAsset? get asset;
  StellarClient get client;
  String? destinationInactiveError;
  String? pathLimitError;
  void onAccountActivityUpdated() {
    updateState();
  }

  void checkTrustPathLimit(StellarPickedIssueAsset? asset, BigInt amount) {
    pathLimitError = _checkTrustPathLimit(asset, amount);
    updateState();
  }

  String? _checkTrustPathLimit(StellarPickedIssueAsset? asset, BigInt amount) {
    if (asset == null ||
        asset.asset.type.isNative ||
        receiver?.accountInfo == null) {
      return null;
    }
    final receiverAsset = receiver!.accountInfo!.getAsset(asset.asset);
    if (receiverAsset == null) return "stellar_destination_lacks_trust_path".tr;
    final limit = receiverAsset.limitAsBigint() - receiverAsset.unlockedBalance;
    if (limit < amount) return "stellar_asset_trust_path_limit_exceeded".tr;
    return null;
  }

  Future<void> trackActivity(StellarReceiptWithActivityStatus receiver) async {
    if (!receiver.status.canTry) return;
    receiver.setPending();
    destinationInactiveError = null;
    pathLimitError = null;
    updateState();
    final result = await MethodUtils.call(() async {
      return await client.getAccount(receiver.address.networkAddress);
    });
    if (result.hasError) {
      receiver.setStatus(AccountReceivementStatus.error);
    } else if (result.result != null) {
      receiver.setStatus(AccountReceivementStatus.active,
          accountInfo: result.result);
    } else {
      receiver.setStatus(AccountReceivementStatus.inactive);
      destinationInactiveError = "stellar_account_inactive_desc".tr;
    }
    onAccountActivityUpdated();
  }

  void setReceiver(ReceiptAddress<StellarAddress>? receiver) {
    if (receiver == null ||
        receiver.networkAddress == this.receiver?.address.networkAddress) {
      return;
    }
    this.receiver = StellarReceiptWithActivityStatus(receiver);
    trackActivity(this.receiver!);
  }
}
