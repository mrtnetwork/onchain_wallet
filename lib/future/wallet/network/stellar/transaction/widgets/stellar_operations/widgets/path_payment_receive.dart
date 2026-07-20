import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/live_widgets.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/widgets/pick_asset.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/live_form_widget.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';

class StellarTransactionPathPaymentStrictReceiveWidget extends StatelessWidget {
  final StellarPathPaymentStrictReceiveOperationForm form;
  const StellarTransactionPathPaymentStrictReceiveWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LiveFormPickStellarAssetWidget(
        field: form.asset,
        allowNativeAssets: true,
        allowCreateAsset: true,
        onSelectAsset: (asset) => form.onUpdateAsset(asset),
        controller: form.controller,
        onAssetPicked: (context, field, selling) {
          return Column(
            children: [
              LiveFormWidgetAmount(
                  onUpdateAmount: (amount, max) => form.onUpdateSendMax(amount),
                  field: form.sendMax),
              WidgetConstant.height20,
              LiveFormWidgetStellarAddressWithActivity(
                field: form.destination,
                account: form.controller.account,
                onUpdateAddress: (address) => form.onUpdateDestination(address),
              ),
              WidgetConstant.height20,
              LiveFormPickStellarAssetWidget(
                field: form.destAsset,
                allowNativeAssets: true,
                allowCreateAsset: true,
                onSelectAsset: (asset) => form.onUpdateDestAsset(asset),
                controller: form.controller,
                onAssetPicked: (context, field, buying) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    LiveFormWidgetAmount(
                        onUpdateAmount: (amount, max) => form.onUpdateDestAmount(amount),
                        field: form.destAmount),
                    WidgetConstant.height20,
                    LiveFormWidgetList(
                      field: form.paths,
                      onCreate: (context, field) {
                        if (!form.allowAddPaths) return null;
                        return ContainerWithBorder(
                          onRemoveIcon:
                              Icon(Icons.add_box, color: context.onPrimaryContainer),
                          child: Text("tap_to_select_or_create_asset".tr,
                              style: context.onPrimaryTextTheme.bodyMedium),
                          onRemove: () {
                            context
                                .openDialogPage<StellarPickedIssueAsset>('',
                                    child: (context) => StellarPickAssetView(
                                        accountInfo: form.controller.accountData,
                                        chain: form.controller.account,
                                        tokens: form.controller.addressTokens,
                                        allowCreate: true))
                                .then((e) => form.onUpdatePath(e,
                                    onPathExists: () =>
                                        context.showAlert("path_already_exist".tr)));
                          },
                        );
                      },
                      builder: (context, field, value) {
                        return ContainerWithBorder(
                          onRemoveIcon: Icon(Icons.remove_circle,
                              color: context.colors.onPrimaryContainer),
                          child: AccountTokenDetailsWidget(
                              token: value.token,
                              radius: APPConst.circleRadius25,
                              color: context.onPrimaryContainer,
                              tokenAddress: value.issuer),
                          onRemove: () {
                            form.onRemovePath(value);
                          },
                        );
                      },
                    ),
                  ]);
                },
              ),
            ],
          );
        },
      )
    ]);
  }
}
