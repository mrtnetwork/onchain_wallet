import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';

class SwapSelectAssetView extends StatefulWidget {
  final bool isSource;
  final SwapStateController controller;
  const SwapSelectAssetView(
      {required this.isSource, required this.controller, super.key});

  @override
  State<SwapSelectAssetView> createState() => _AsseetsState();
}

class _AsseetsState extends State<SwapSelectAssetView>
    with SafeState<SwapSelectAssetView> {
  Map<WalletNetwork, Set<APPSwapAssets>> _assets = {};
  Set<APPSwapAssets> allAssets = {};
  Set<APPSwapAssets> assets = {};
  int selectedIndex = 0;
  List<WalletNetwork> networks = [];
  String name = '';

  @override
  void onInitOnce() {
    super.onInitOnce();
    // controller = context.watch(StateConst.swap);
    if (widget.isSource) {
      _assets = widget.controller.sourceAssets;
    } else {
      _assets = widget.controller.destinationAssets;
    }
    networks = _assets.keys.toList();
    if (networks.isEmpty) return;
    onDestinationSelected(0);
  }

  void filterAssets() {
    final n = name.trim().toLowerCase();
    if (name.isEmpty) {
      assets = allAssets;
    } else {
      assets = allAssets
          .where((e) =>
              e.asset.symbol.toLowerCase().contains(n) ||
              (e.asset.fullName?.toLowerCase().contains(n) ?? false))
          .toSet();
    }
    updateState();
  }

  void onChange(String v) {
    name = v;
    filterAssets();
  }

  void onSelectAsset(APPSwapAssets asset) {
    if (widget.isSource) {
      widget.controller.updateSourceAsset(asset);
    } else {
      widget.controller.updateDestinationAsset(asset);
    }
    context.pop();
  }

  void onDestinationSelected(int index) {
    selectedIndex = index;
    final network = networks.elementAt(index);
    allAssets = _assets[network] ?? {};
    filterAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: onChange,
          decoration: InputDecoration(
              filled: true,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderSide: BorderSide.none)),
        ),
      ),
      body: EmptyItemWidgetView(
          isEmpty: networks.isEmpty,
          itemBuilder: () => Row(children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: APPConst.naviationRailWidth),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                                useIndicator: true,
                                onDestinationSelected: onDestinationSelected,
                                labelType: NavigationRailLabelType.none,
                                destinations: List.generate(networks.length, (index) {
                                  final network = networks[index];
                                  return _NavigationRailDestination(
                                      network: network, disabled: false);
                                }),
                                selectedIndex: selectedIndex),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                    child: APPAnimated(
                        isActive: true,
                        onActive: (context) => CustomScrollView(
                              key: ValueKey(assets.length),
                              slivers: [
                                EmptyItemSliverWidgetView(
                                  isEmpty: assets.isEmpty,
                                  icon: Icons.token,
                                  subject: 'no_token_found'.tr,
                                  itemBuilder: (context) {
                                    return SliverList.builder(
                                      itemBuilder: (context, index) {
                                        final asset = assets.elementAt(index);
                                        final url = asset.asset.assetUrl();
                                        return ContainerWithBorder(
                                          onRemoveIcon: ConditionalWidget(
                                              enable: url != null,
                                              onActive: (context) => LaunchBrowserIcon(
                                                  url: url,
                                                  color: context.onPrimaryContainer)),
                                          onRemove: () => onSelectAsset(asset),
                                          child: Row(children: [
                                            Stack(
                                              children: [
                                                CircleTokenImageView(asset.token,
                                                    radius: APPConst.circleRadius25),
                                                Align(
                                                    alignment: Alignment.bottomRight,
                                                    child: CircleTokenImageView(
                                                        asset.network.token,
                                                        radius: 10))
                                              ],
                                            ),
                                            WidgetConstant.width8,
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                  Text(asset.asset.symbol,
                                                      style: context.onPrimaryTextTheme
                                                          .titleMedium),
                                                  Text(asset.asset.fullName ?? '',
                                                      style: context
                                                          .onPrimaryTextTheme.bodySmall),
                                                ])),
                                          ]),
                                        );
                                      },
                                      // separatorBuilder: (context, index) => WidgetConstant.divider,
                                      itemCount: assets.length,
                                      addAutomaticKeepAlives: false,
                                      addRepaintBoundaries: false,
                                      addSemanticIndexes: false,
                                    );
                                  },
                                ),
                                WidgetConstant.sliverPaddingVertial40,
                              ],
                            ),
                        onDeactive: (context) => WidgetConstant.sizedBox))
              ])),
    );
  }
}

class _NavigationRailDestination extends NavigationRailDestination {
  _NavigationRailDestination({required WalletNetwork network, required super.disabled})
      : super(
            label: WidgetConstant.sizedBox,
            icon: Opacity(
                opacity: disabled ? 0.3 : 1,
                child: CircleTokenImageView(network.token, radius: 15)));
}

// class _AssetProviderView extends StatelessWidget {
//   final SwapServiceProvider provider;
//   const _AssetProviderView({required this.provider, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return TappedTooltipView(
//       tooltipWidget: ToolTipView(
//           message: provider.name,
//           child: Opacity(
//             opacity: 0.7,
//             child: CircleServiceProviderImageView(provider,
//                 radius: APPConst.circleRadius10),
//           )),
//     );
//   }
// }
