import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class ImportCustomKeyToWalletView extends StatefulWidget {
  const ImportCustomKeyToWalletView({required this.keypair, super.key});
  final ImportCustomKeys keypair;

  @override
  State<ImportCustomKeyToWalletView> createState() => ImportCustomKeyToWalletViewState();
}

class ImportCustomKeyToWalletViewState extends State<ImportCustomKeyToWalletView>
    with SafeState {
  bool showKeys = false;
  late final String keyType = widget.keypair.coin.conf.type.name.camelCase;

  void onChangeShowKeys() {
    showKeys = !showKeys;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "import_private_key".tr,
              body: LargeTextView([
                "import_private_key_desc".tr,
                "export_private_key_desc".tr,
              ])),
          Text("private_key".tr, style: context.textTheme.titleMedium),
          Text(keyType),
          WidgetConstant.height8,
          SecureContentView(content: widget.keypair.privateKey),
          WidgetConstant.height20,
          Text(
            "public_key".tr,
            style: context.textTheme.titleMedium,
          ),
          WidgetConstant.height8,
          SecureContentView(content: widget.keypair.publicKey),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: () {
                  context.to(PageRouter.importAccount, argruments: widget.keypair);
                },
                child: Text("import_to_wallet".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}
