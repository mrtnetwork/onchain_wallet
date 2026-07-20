import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';

class SuiFeaturePageView extends StatelessWidget {
  const SuiFeaturePageView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SuiNetworkClient?, ISuiAddress?, SuiChain>(
      title: "settings".tr,
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) {
        return ConstraintsBoxView(
            child: Column(
          children: [
            AppListTile(
              leading: const Icon(Icons.password),
              title: Text("sui_key_conversion".tr),
              subtitle: Text("sui_key_conversion_desc".tr),
              onTap: () {
                context.to(PageRouter.suiKeyConversion);
              },
            ),
          ],
        ));
      },
    );
  }
}
