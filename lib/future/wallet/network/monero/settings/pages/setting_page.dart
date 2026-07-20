import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';

class MoneroSettingsView extends StatelessWidget {
  const MoneroSettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<MoneroNetworkClient?, IMoneroAddress?,
        MoneroChain>(
      title: "settings".tr,
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) {
        return ConstraintsBoxView(
            child: Column(
          children: [
            AppListTile(
              leading: const Icon(Icons.sync),
              title: Text("sync_options".tr),
              subtitle: Text("monero_sync_options_desc".tr),
              onTap: () {
                context.to(PageRouter.moneroSyncOptions);
              },
            ),
            AppListTile(
              leading: const Icon(Icons.sync),
              title: Text("sync_information".tr),
              subtitle: Text("view_account_block_sync".tr),
              onTap: () {
                context.to(PageRouter.moneroAccountSync);
              },
            ),
            AppListTile(
              leading: const Icon(Icons.password),
              title: Text("monero_mnemonic".tr),
              subtitle: Text("generate_monero_private_key".tr),
              onTap: () {
                context.to(PageRouter.moneroMnemonic);
              },
            ),
            AppListTile(
              leading: const Icon(Icons.handshake),
              title: Text("generate_transaction_proof".tr),
              subtitle: Text("monero_tx_proof_desc3".tr),
              onTap: () {
                context.to(PageRouter.moneroGenerateProof);
              },
            ),
            AppListTile(
              leading: const Icon(Icons.verified),
              title: Text("verify_transaction_proof".tr),
              subtitle: Text("monero_verify_proof_desc".tr),
              onTap: () {
                context.to(PageRouter.moneroVerifyProof);
              },
            ),
          ],
        ));
      },
    );
  }
}
