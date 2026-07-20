import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/swap/pages/pages/review_transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

class SwapAddressesView extends StatelessWidget {
  final SwapStateController controller;
  const SwapAddressesView({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: WidgetConstant.paddingHorizontal10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("source_accounts".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ...List.generate(controller.sourceAddresses.length, (i) {
            final account = controller.sourceAddresses[i];
            return ContainerWithBorder(
              onRemoveIcon: ConditionalWidget(
                enable: controller.allowAddSource,
                onActive: (context) =>
                    Icon(Icons.remove_circle, color: context.onPrimaryContainer),
                onDeactive: (context) =>
                    Icon(Icons.edit, color: context.onPrimaryContainer),
              ),
              child:
                  AddressDetailsView(address: account, color: context.onPrimaryContainer),
              onRemove: () {
                controller.onSelectUpdateAddress((acc) async {
                  return context.selectOrSwitchAccount<ChainAccount>(
                      account: acc, showMultiSig: true);
                }, account);
              },
            );
          }),
          APPAnimatedSize(
              isActive: controller.allowAddSource,
              onActive: (context) => ContainerWithBorder(
                    validate: controller.sourceAddresses.isNotEmpty,
                    onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
                    child: Text("tap_to_select_account".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                    onRemove: () {
                      controller.onSelectSourceAddress(
                        (account) async {
                          return context.selectOrSwitchAccount<ChainAccount>(
                              account: account, showMultiSig: true);
                        },
                      );
                    },
                  ),
              onDeactive: (context) => WidgetConstant.sizedBox),
          APPAnimated(
              isActive: controller.hasBalance,
              onActive: (context) => WidgetConstant.sizedBox,
              onDeactive: (context) =>
                  ErrorTextContainer(error: "insufficient_balance".tr, enableTap: false)),
          WidgetConstant.height20,
          ReceiptAddressView(
            address: controller.destinationAddress,
            onTap: () {
              controller.onSelectReceiptAddress((chain) async {
                return (await context.selectAccount(
                        account: chain, multipleSelect: false))
                    ?.firstOrNull;
              });
            },
          ),
          ErrorTextContainer(error: controller.txError),
          WidgetConstant.height40,
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Shimmer(
                onActive: (enable, context) => FixedElevatedButton(
                      activePress: true,
                      onPressed: () {
                        controller.createSwapTransaction(onPage: (route) async {
                          return context.openDialogPage('', child: (context) {
                            return TransactionReviewView(route: route);
                          });
                        });
                      },
                      child: APPAnimated(
                          isActive: enable,
                          onActive: (context) => Text("swap_now".tr),
                          onDeactive: (context) => Text("generating_transaction".tr)),
                    ),
                enable: controller.page == SwapPage.swap)
          ]),
        ],
      ),
    );
  }
}
