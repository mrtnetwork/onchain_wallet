import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/settings/pages/status.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/syncing.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';

List<PopupMenuItem<int>> zcashAccountMenuButton(
    {required ZcashChain account, required BuildContext context, required int value}) {
  if (!account.haveAddress) return [];
  final address = account.addressSync;
  final bool hasMultipleProtocol = address.account.receivers.length > 1;
  if (hasMultipleProtocol) {
    return [
      PopupMenuItem<int>(
        value: value,
        onTap: () {
          context.openSliverDialog(
              widget: (context) => _ShowZcashSpeceficProtocolAddress(
                    address: account.addressSync,
                    account: account,
                  ),
              label: "protocols_addresses".tr);
        },
        child: AppListTile(
          trailing: const Icon(Icons.north_east_sharp),
          title: Text("protocols_addresses".tr, style: context.textTheme.labelMedium),
        ),
      ),
    ];
  }
  return [];
}

class ZcashAccountPageView extends StatelessWidget {
  const ZcashAccountPageView({required this.chainAccount, super.key});
  final ZcashChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
      _ZcashServices(chainAccount),
      AccountTransactionActivityView<ZcashWalletTransaction, IZcashAddress>(
          account: chainAccount, address: chainAccount.addressSync)
    ]);
  }
}

class _ZcashServices extends StatelessWidget {
  const _ZcashServices(this.account);
  final ZcashChain account;

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      SliverToBoxAdapter(
        child: Column(children: [
          ChainStreamBuilder(
            account: account,
            allowNotify: [
              ZcashChainNotify.trackerAccountChanged,
            ],
            builder: (context, latestEvent) {
              return FutureShimmerBuilder(
                  onData: (context, snapshot) {
                    return AppListTile(
                      leading: const Icon(Icons.sync),
                      trailing: switch (snapshot.data) {
                        ResultOk<ZcashSyncing?>(:final value)
                            when snapshot.connectionState == ConnectionState.done =>
                          switch (value) {
                            null => ToolTipView(
                                message: "chain_synchronization_disabled_desc".tr,
                                child: Icon(
                                  Icons.error,
                                  color: context.colors.error,
                                )),
                            ZcashSyncing syncing => APPStreamBuilder(
                                value: syncing.latestEvent,
                                builder: (context, _) =>
                                    BlockSyncStatusIcon(status: syncing.status))
                          },
                        ResultErr<ZcashSyncing?>(:final localizationError)
                            when snapshot.connectionState == ConnectionState.done =>
                          ToolTipView(
                              message: localizationError,
                              child: Icon(
                                Icons.error,
                                color: context.colors.error,
                              )),
                        _ => null,
                      },
                      title: Text("sync_information".tr),
                      subtitle: Text("view_account_block_sync".tr),
                      onTap: () {
                        context.to(PageRouter.zcashAccountSync);
                      },
                    );
                    // return AppListTile(
                    //   leading: const Icon(Icons.sync),
                    //   title: Text("sync_options".tr),
                    //   subtitle: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text("monero_sync_options_desc".tr),
                    //       ConditionalWidgetWithValue(
                    //         value: snapshot.data,
                    //         onValue: (context, value) => ConditionalWidgetIResult(
                    //           onOk: (context, value) {
                    //             return ConditionalWidget(
                    //               onActive: (context) => ErrorTextContainer(
                    //                   enableTap: false,
                    //                   showErrorIcon: false,
                    //                   error: "chain_synchronization_disabled_desc".tr),
                    //               enable: !value,
                    //             );
                    //           },
                    //           onErr: (context, err) => ErrorTextContainer(
                    //               enableTap: false,
                    //               showErrorIcon: false,
                    //               error: err.localizationError),
                    //           result: value,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    //   onTap: () {
                    //     context.to(PageRouter.moneroSyncOptions);
                    //   },
                    // );
                  },
                  future: account.getSyncing());
            },
          ),
        ]),
      )
    ]);
  }
}

class _ShowZcashSpeceficProtocolAddress extends StatefulWidget {
  const _ShowZcashSpeceficProtocolAddress({required this.address, required this.account});
  final IZcashAddress address;
  final ZcashChain account;

  @override
  State<_ShowZcashSpeceficProtocolAddress> createState() =>
      _ShowZcashSpeceficProtocolAddressState();
}

class _ShowZcashSpeceficProtocolAddressState
    extends State<_ShowZcashSpeceficProtocolAddress>
    with SafeState<_ShowZcashSpeceficProtocolAddress> {
  List<(ZcashProtocol protocol, ReceiptAddress<ZcashAddress>)> addresses = [];
  @override
  void onInitOnce() {
    super.onInitOnce();
    final account = widget.address.account;
    for (final i in account.receivers) {
      final addr = account.address.toProtocolAddress(i.protocol);
      assert(addr != null, "should not be null.");
      if (addr == null) continue;
      addresses.add((
        i.protocol,
        ReceiptAddress(
            view: addr.address,
            networkAddress: addr,
            type: switch (i.type) {
              ZcashAccountInfoType.orchard => "orchard".tr,
              _ => i.type.tr.tr
            })
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: addresses.map((e) {
      return FutureShimmerBuilder(
          onData: (context, snapshot) {
            return ContainerWithBorder(
              child: Column(children: [
                ContainerWithBorder(
                    backgroundColor: context.colors.onPrimaryContainer,
                    child: CopyableTextWidget(
                      text: e.$2.view,
                      color: context.primaryContainer,
                      widget: ReceiptAddressDetailsView(
                          address: e.$2, color: context.primaryContainer),
                    )),
                ConditionalWidgetWithValue(
                  value: snapshot.data,
                  onValue: (context, value) => ConditionalWidgetIResult(
                      onOk: (context, info) => ContainerWithBorder(
                          onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                          backgroundColor: context.onPrimaryContainer,
                          child: CoinAndMarketPriceView(
                              balance: info.totalActiveBalance,
                              showTokenImage: true,
                              style: context.primaryTextTheme.titleMedium,
                              symbolColor: context.primaryContainer)),
                      result: value),
                )
              ]),
            );
          },
          future: widget.account.getProtocolUtxos(widget.address, e.$1));
    }).toList());
  }
}

// class _ZcashProtocolAddressWithBalance {}
