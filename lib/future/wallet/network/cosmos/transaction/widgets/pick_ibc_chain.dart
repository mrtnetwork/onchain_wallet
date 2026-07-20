import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef ONIBCSELECTDESTINATIONCHAIN = void Function(
    BuildContext context, CosmosIbcChainData chain);

class CosmosIbcTransactionPickDestinationChainView extends StatefulWidget {
  final ScrollController scrollController;
  final ONIBCSELECTDESTINATIONCHAIN onSelectChain;
  final CosmosChain currentChain;
  const CosmosIbcTransactionPickDestinationChainView(
      {required this.scrollController,
      required this.onSelectChain,
      required this.currentChain,
      super.key});

  @override
  State<CosmosIbcTransactionPickDestinationChainView> createState() =>
      _CosmosTransactionPickTokenViewState();
}

class _CosmosTransactionPickTokenViewState
    extends State<CosmosIbcTransactionPickDestinationChainView>
    with
        SafeState<CosmosIbcTransactionPickDestinationChainView>,
        ProgressMixin,
        CosmosCustomRequest {
  @override
  late final INetApi netApi;
  List<CosmosChain> chains = [];
  List<CW20Token> tokens = [];

  Future<void> onSelectChain(CW20Token token) async {
    progressKey.progressText("ibc_retrieval_requirements".tr);
    final chain = chains[tokens.indexOf(token)];
    final String? chainRegistery = chain.network.coinParam.chainRegisteryName;
    final ccr =
        await getChainData(chainRegistery!, chainType: chain.network.coinParam.chainType);
    List<CCRIbcTransition> ibcs = [];
    final ccrChain = ccr.ok();
    final currentChainName = widget.currentChain.network.coinParam.chainRegisteryName;
    if (ccrChain != null && currentChainName != null) {
      for (final i in ccrChain.$1.assetList.assets) {
        ibcs.addAll(i.traces
            .whereType<CCRIbcTransition>()
            .toList()
            .where((e) => e.counterparty.chainName == currentChainName)
            .toList());
      }
    }
    CosmosIbcChainData ibcChain = CosmosIbcChainData(
        ccrChainData: ccrChain?.$1, chain: chain, ibcConnections: ibcs);

    progressKey.success(backToIdle: false);
    if (context.mounted) {
      widget.onSelectChain(context, ibcChain);
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    netApi = context.appContext.netApi;
    final provider = context.wallet;
    chains = provider.wallet
        .getChains<CosmosChain>()
        .where((e) =>
            e != widget.currentChain &&
            e.network.coinParam.chainType ==
                widget.currentChain.network.coinParam.chainType)
        .toList();
    tokens = chains.map((e) => e.network.coinParam.nativeToken).toList();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    tokens = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('cosmos_chains'.tr),
      ),
      body: StreamPageProgress(
        controller: progressKey,
        builder: (context) => CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: MultiSliver(children: [
                SliverToBoxAdapter(
                    child: PageTitleSubtitle(
                        title: 'destination_chain'.tr,
                        body: Text("cosmos_destination_chain_dest".tr))),
                SliverList.separated(
                    itemBuilder: (context, index) {
                      final token = tokens[index];
                      return AccountTokenDetailsView(
                        onSelect: () => onSelectChain(token),
                        onSelectIcon: WidgetConstant.sizedBox,
                        token: token,
                        showBalance: false,
                      );
                    },
                    separatorBuilder: (context, index) {
                      return WidgetConstant.divider;
                    },
                    itemCount: tokens.length)
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
