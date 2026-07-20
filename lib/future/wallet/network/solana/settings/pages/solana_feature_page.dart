import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';

class SolanaFeaturePageView extends StatelessWidget {
  const SolanaFeaturePageView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SolanaNetworkClient?, ISolanaAddress?,
        SolanaChain>(
      addressRequired: false,
      clientRequired: false,
      title: "settings".tr,
      childBulder: (wallet, account, client, address) {
        return ConstraintsBoxView(
            child: Column(
          children: [
            AppListTile(
              leading: const Icon(Icons.password),
              title: Text("solana_key_conversion".tr),
              subtitle: Text("solana_key_conversion_desc".tr),
              onTap: () {
                context.to(PageRouter.solanaKeyConversion);
              },
            ),
          ],
        ));
      },
    );
  }
}
