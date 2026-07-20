import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';

class MoneroUnlockingAccountOutputView extends StatelessWidget {
  const MoneroUnlockingAccountOutputView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      appbar: AppBar(title: Text("tranaction_received".tr)),
      subtitle: PageTitleSubtitle(
          title: "tranaction_received".tr,
          body: Column(
            children: [
              Text("incomig_transaction_wallet_unlock_desc".tr),
            ],
          )),
      onAccsess: (credential) {
        return NetworkAccountControllerView<MoneroNetworkClient, IMoneroAddress,
                MoneroChain>(
            childBulder: (wallet, account, client, address) {
              return _MoneroUnlockingAccountOutputView(account);
            },
            addressRequired: true,
            clientRequired: true);
      },
    );
  }
}

class _MoneroUnlockingAccountOutputView extends StatefulWidget {
  final MoneroChain account;
  const _MoneroUnlockingAccountOutputView(this.account);

  @override
  State<_MoneroUnlockingAccountOutputView> createState() =>
      __MoneroUnlockingAccountOutputViewState();
}

class __MoneroUnlockingAccountOutputViewState
    extends State<_MoneroUnlockingAccountOutputView>
    with SafeState<_MoneroUnlockingAccountOutputView> {
  final StreamPageProgressController controller =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  Future<void> unlockingPayment() async {
    // final result = await widget.account.updatePendingTxes();
    // if (result.isErr) {
    //   controller.errorText(result.unwrapErr().localizationError, backToIdle: false);
    // } else {
    //   controller.successText('monero_successful_unlock_tx_desc'.tr, backToIdle: false);
    // }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    unlockingPayment();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: controller,
      initialWidget: ProgressWithTextView(text: "unlocking_transaction_please_wait".tr),
      builder: (context) {
        return WidgetConstant.sizedBox;
      },
    );
  }
}
