import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateMetadataConstantsView extends StatelessWidget {
  const SubstrateMetadataConstantsView(
      {this.scrollController, required this.account, super.key});
  final SubstrateChain account;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SubstrateNetworkClient, ISubstrateAddress,
            SubstrateChain>(
        addressRequired: true,
        clientRequired: true,
        account: account,
        title: 'constants'.tr,
        childBulder: (wallet, account, client, address) =>
            SubstrateMetadataConstantsWidget(
                account: account, scrollController: scrollController, client: client));
  }
}

class SubstrateMetadataConstantsWidget extends StatefulWidget {
  const SubstrateMetadataConstantsWidget(
      {super.key, required this.account, required this.client, this.scrollController});
  final SubstrateChain account;
  final SubstrateNetworkClient client;
  final ScrollController? scrollController;

  @override
  State<SubstrateMetadataConstantsWidget> createState() =>
      _SubstrateMetadataConstantsWidgetState();
}

class _SubstrateMetadataConstantsWidgetState
    extends SubstrateAccountState<SubstrateMetadataConstantsWidget> {
  @override
  SubstrateNetworkClient get client => widget.client;
  late final List<PalletInfo> contantsPallets;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  Map<PalletInfo, Text> items = {};
  late PalletInfo pallet;
  void onChangePallet(PalletInfo? pallet) {
    this.pallet = pallet ?? this.pallet;
    updateState();
  }

  Future<void> init() async {
    contantsPallets = client.metadata.constantPallets();
    items = {for (final i in contantsPallets) i: Text(i.name)};
    pallet = contantsPallets.first;
    progressKey.backToIdle();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    MethodUtils.executeAfterDelay(() => init());
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  SubstrateChain get account => widget.account;
  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      initialWidget: ProgressWithTextView(text: 'retrieving_constants_please_wait'.tr),
      builder: (context) {
        return CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: MultiSliver(children: [
                SliverPinnedHeaderSurface(
                    elevation: APPConst.elevation,
                    child: AppDropDownBottom(
                        items: items, onChanged: onChangePallet, value: pallet)),
                SliverPadding(
                  padding: WidgetConstant.paddingHorizontal20,
                  sliver: APPSliverAnimatedSwitcher(enable: pallet, widgets: {
                    pallet: (context) => PalletConstantsView(pallet: pallet)
                  }),
                )
              ]),
            ),
          ],
        );
      },
    );
  }
}

class PalletConstantsView extends StatelessWidget {
  const PalletConstantsView({super.key, required this.pallet});
  final PalletInfo pallet;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemBuilder: (context, index) {
        final call = pallet.contants![index];
        return AppListTile(
            title: Text(call.name),
            maxLine: 10,
            trailing: IconButton(
                onPressed: () {
                  context.openSliverDialog(
                      widget: (context) {
                        return ContainerWithBorder(
                          child: CopyableTextWidget(
                            text: call.value?.toString() ?? '',
                            color: context.onPrimaryContainer,
                            maxLines: null,
                            widget: APPSelectableText(
                              call.value?.toString() ?? '',
                              style: context.onPrimaryTextTheme.titleMedium,
                            ),
                          ),
                        );
                      },
                      label: call.name);
                },
                icon: const Icon(Icons.remove_red_eye)),
            contentPadding: EdgeInsets.zero,
            subtitle: LargeTextView(call.docs, textAligen: TextAlign.start));
      },
      itemCount: pallet.contants!.length,
    );
  }
}
