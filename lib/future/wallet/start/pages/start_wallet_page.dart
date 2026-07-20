import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/theme/theme.dart';
import 'package:on_chain_wallet/future/wallet/setting/color_selector.dart';
import 'package:on_chain_wallet/future/widgets/widgets/assets_image.dart';
import 'package:on_chain_wallet/future/widgets/widgets/button.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';

import 'platform_widgets/widgets.dart';

class StartWalletPage extends StatelessWidget {
  const StartWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    return Scaffold(
      appBar: AppBar(
        actions: [
          WidgetConstant.width8,
          BrightnessToggleIcon(
              onToggleBrightness: () => wallet.toggleBrightness(),
              brightness: ThemeController.appTheme.brightness),
          ColorSelectorIconView(
            (p0) {
              if (p0 == null) return;
              return wallet.changeColor(p0);
            },
          ),
          appbarWidgets(false),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAssetsImageView(APPConst.logo),
                Text("wellcome".tr, style: context.textTheme.titleMedium),
                Text("your_gateway_to_decentralized_world".tr,
                    style: context.textTheme.bodyMedium),
                FixedElevatedButton(
                    padding: WidgetConstant.paddingVertical40,
                    onPressed: () {
                      context.to(PageRouter.createWallet);
                    },
                    child: Text("setup".tr))
              ]),
        ),
      ),
    );
  }
}
