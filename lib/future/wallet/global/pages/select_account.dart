import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/chain_stream.dart';
import 'package:on_chain_wallet/future/wallet/start/pages/account_no_adress.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

import 'address_details.dart';

typedef OnSelectAccountFilter<CHAINACCOUNT extends ChainAccount> = String? Function(
    CHAINACCOUNT account);

class SwitchOrSelectAccountView<CHAINACCOUNT extends ChainAccount>
    extends StatelessWidget {
  const SwitchOrSelectAccountView(
      {super.key,
      required this.account,
      required this.showMultiSig,
      this.defaultAddresses,
      this.filter,
      this.isSwitch = false});
  final APPCHAINACCOUNT<CHAINACCOUNT> account;
  final List<CHAINACCOUNT>? defaultAddresses;
  final bool showMultiSig;
  final bool isSwitch;
  final OnSelectAccountFilter<CHAINACCOUNT>? filter;
  @override
  Widget build(BuildContext context) {
    return ChainStreamBuilder(
        allowNotify: [DefaultChainNotify.address],
        builder: (context, _) {
          List<CHAINACCOUNT> addresses = defaultAddresses ?? account.addresses;
          return CustomScrollView(shrinkWrap: true, slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(isSwitch ? "switch_account".tr : "select_account".tr),
              actions: [
                CircleTokenImageView(account.network.token,
                    radius: APPConst.circleRadius12),
                WidgetConstant.width8,
                ConditionalWidget(
                    enable: defaultAddresses == null,
                    onActive: (context) => IconButton(
                        onPressed: () {
                          context.to(PageRouter.setupGenericAddress, argruments: account);
                        },
                        icon: const Icon(Icons.add_box),
                        tooltip: "new_address".tr)),
                WidgetConstant.width8,
              ],
            ),
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingVertical20,
              sliver:
                  APPSliverAnimatedSwitcher<bool>(enable: addresses.isNotEmpty, widgets: {
                false: (context) =>
                    SliverToBoxAdapter(child: NoAccountFoundInChainWidget(account)),
                true: (context) {
                  final currentAccount = account.addressSyncOrNull;
                  // List<CHAINACCOUNT> addresses = account.addresses;
                  if (!showMultiSig) {
                    addresses = addresses.where((e) => !e.multiSigAccount).toList();
                  }

                  return SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver: SliverList.builder(
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final CHAINACCOUNT addr = addresses[index];
                        bool isSelected = false;
                        if (isSwitch) {
                          isSelected = addr == currentAccount;
                        }

                        return ContainerWithBorder(
                          backgroundColor: isSelected
                              ? context.colors.secondary
                              : context.colors.primaryContainer,
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: isSelected
                                      ? null
                                      : () {
                                          final err = filter?.call(addr);
                                          if (err != null) {
                                            context.showAlert(err);
                                            return;
                                          }
                                          if (context.mounted) {
                                            context.pop(addr);
                                          }
                                        },
                                  child: AddressDetailsView(
                                      address: addr,
                                      color: isSelected
                                          ? context.colors.onSecondary
                                          : context.colors.onPrimaryContainer),
                                ),
                              ),
                              WidgetConstant.width8,
                              CopyTextIcon(
                                  isSensitive: false,
                                  dataToCopy: addr.address,
                                  color: isSelected
                                      ? context.colors.onSecondary
                                      : context.colors.onPrimaryContainer),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
              }),
            ),
          ]);
        },
        account: account);
  }
}
