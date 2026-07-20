import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/settings/pages/status.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class MoneroAccountPageView extends StatelessWidget {
  const MoneroAccountPageView({required this.chainAccount, super.key});
  final MoneroChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(physics: WidgetConstant.noScrollPhysics, children: [
      _MoneroServices(chainAccount),
      AccountTransactionActivityView<MoneroWalletTransaction, IMoneroAddress>(
          account: chainAccount, address: chainAccount.addressSync)
    ]);
  }
}

class _MoneroServices extends StatelessWidget {
  const _MoneroServices(this.account);
  final MoneroChain account;

  @override
  Widget build(BuildContext context) {
    return AccountTabbarScrollWidget(slivers: [
      SliverToBoxAdapter(
        child: Column(children: [
          ChainStreamBuilder(
            account: account,
            allowNotify: [
              MoneroChainNotify.trackerAccountChanged,
            ],
            builder: (context, latestEvent) {
              return FutureShimmerBuilder(
                  onData: (context, snapshot) {
                    return AppListTile(
                      leading: const Icon(Icons.sync),
                      trailing: switch (snapshot.data) {
                        ResultOk<MoneroSyncing?>(:final value)
                            when snapshot.connectionState == ConnectionState.done =>
                          switch (value) {
                            null => ToolTipView(
                                message: "chain_synchronization_disabled_desc".tr,
                                child: Icon(
                                  Icons.error,
                                  color: context.colors.error,
                                )),
                            MoneroSyncing syncing => APPStreamBuilder(
                                value: syncing.latestEvent,
                                builder: (context, _) =>
                                    BlockSyncStatusIcon(status: syncing.status))
                          },
                        ResultErr<MoneroSyncing?>(:final localizationError)
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
                        context.to(PageRouter.moneroAccountSync);
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
          AppListTile(
            leading: const Icon(Icons.download),
            title: Text("import_utxos".tr),
            subtitle: Text("import_utoxs_from_transaction_ids".tr),
            onTap: () {
              context.to(PageRouter.moneroImportUtxos);
            },
          ),
          AppListTile(
            leading: const Icon(Icons.api),
            title: Text("wallet_rpc_synchronization".tr),
            subtitle: Text("synchronization_with_monero_wallet_rpc".tr),
            onTap: () {
              context.to(PageRouter.moneroWalletRpc);
            },
          ),
          AppListTile(
            leading: const Icon(Icons.sync),
            title: Text("create_synchronization_request".tr),
            subtitle: Text("create_synchronization_request_desc".tr),
            onTap: () {
              context.to(PageRouter.moneroCreateSynchronizationRequest);
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
          AppListTile(
            leading: const Icon(Icons.password),
            title: Text("monero_mnemonic".tr),
            subtitle: Text("generate_monero_private_key".tr),
            onTap: () {
              context.to(PageRouter.moneroMnemonic);
            },
          ),
        ]),
      )
    ]);
  }
}
