import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/substrate/client/substrate.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/substrate/models/models/models.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/substrate/substrate.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateQuickAccessView extends StatelessWidget {
  const SubstrateQuickAccessView(
      {this.scrollController, required this.account, super.key});
  final ScrollController? scrollController;
  final SubstrateChain account;
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SubstrateNetworkClient, ISubstrateAddress,
        SubstrateChain>(
      addressRequired: true,
      account: account,
      clientRequired: true,
      childBulder: (wallet, account, client, address) {
        return _QuickAccessView(
            scrollController: scrollController, account: account, client: client);
      },
    );
  }
}

class _QuickAccessView extends StatefulWidget {
  const _QuickAccessView(
      {this.scrollController, required this.account, required this.client});
  final ScrollController? scrollController;
  final SubstrateChain account;
  final SubstrateNetworkClient client;

  @override
  State<_QuickAccessView> createState() => __QuickAccessViewState();
}

class __QuickAccessViewState extends SubstrateAccountState<_QuickAccessView> {
  @override
  SubstrateChain get account => widget.account;
  @override
  SubstrateNetworkClient get client => widget.client;

  SubstrateChainMetadata get api => client.metadata;
  StorageInfo? accountInfoKey;
  late final Future<SubstrateBlockWithEra> finalizeBlock = client.finalizeBlockWithEra();

  @override
  void onInitOnce() {
    super.onInitOnce();
    accountInfoKey = api.getAccountInfoStorageKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("substrate_quick_block_access".tr)),
      body: UnfocusableChild(
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        APPFutureBuilder(
                            onData: (context, result) {
                              return Column(
                                children: [
                                  CopyableTextWidget(
                                      text: result.block,
                                      widget: AppListTile(
                                          subtitle: Text(result.block),
                                          title: Text("finaliz_block".tr,
                                              style: context.textTheme.titleMedium))),
                                  CopyableTextWidget(
                                      text: result.era.toString(),
                                      widget: AppListTile(
                                          subtitle: Text(result.era.toString()),
                                          title: Text("quick_era".tr,
                                              style: context.textTheme.titleMedium)))
                                ],
                              );
                            },
                            onError: (context, err) {
                              return AppListTile(
                                  title: Text("finaliz_block_era".tr),
                                  trailing: Tooltip(
                                      message: err.toString(),
                                      child: WidgetConstant.errorIcon));
                            },
                            onProgress: (context) {
                              return AppListTile(
                                  title: Text("finaliz_block_era".tr),
                                  trailing: const APPCircularProgressIndicator());
                            },
                            future: finalizeBlock),
                        CopyableTextWidget(
                            text: api.genesis,
                            widget: AppListTile(
                                subtitle: Text(api.genesis),
                                title: Text("genesis_hash".tr,
                                    style: context.textTheme.titleMedium))),
                      ]),
                ))
          ],
        ),
      ),
    );
  }
}
