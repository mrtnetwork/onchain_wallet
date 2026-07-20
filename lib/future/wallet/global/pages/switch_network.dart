import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SwitchNetworkView extends StatefulWidget {
  const SwitchNetworkView({required this.selectedNetwork, super.key});
  final WalletNetwork selectedNetwork;

  @override
  State<SwitchNetworkView> createState() => _SwitchNetworkViewState();
}

class _SwitchNetworkViewState extends State<SwitchNetworkView>
    with SafeState<SwitchNetworkView> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final GlobalKey<AppTextFieldState> searchKey = GlobalKey();
  Map<NetworkType, List<Chain>> allNetworks = {};
  NetworkType currentNetwork = NetworkType.bitcoinAndForked;
  String searched = '';
  static const double imageRadius = 15;

  List<Chain> allChains = [];
  late List<Chain> buildedNetwork;
  late WalletProvider wallet;
  List<Chain> filteredNetworks = [];

  int initialIndex = 0;
  bool showTestnet = false;
  NetworkType? showImport;

  void toggleShowTestnet() {
    showTestnet = !showTestnet;
    final appSetting = wallet.appSetting;
    final setting = appSetting.walletSetting.copyWith(showTestnetNetworks: showTestnet);
    wallet.updateAppSettings(appSetting.copyWith(walletSetting: setting));
    buildChains();
    updateState();
  }

  void initNetwork() {
    wallet = context.wallet;
    showTestnet = wallet.appSetting.walletSetting.showTestnetNetworks;
    allChains = wallet.wallet.getChains();
    for (final i in NetworkType.values) {
      if (i == NetworkType.bitcoinCash) continue;
      if (i == NetworkType.bitcoinAndForked) {
        allNetworks[i] = allChains.where((e) => e.network.type.isBitcoin).toList();
      } else {
        allNetworks[i] = allChains.where((e) => e.network.type == i).toList();
      }
    }
    currentNetwork = widget.selectedNetwork.type;
    if (currentNetwork.isBitcoin) {
      currentNetwork = NetworkType.bitcoinAndForked;
    }
    initialIndex = findIndex(currentNetwork);
    buildChains();
    progressKey.backToIdle();
  }

  void onDestinationSelected(int index) {
    if (index == initialIndex) return;
    currentNetwork = findNetworkType(index);
    initialIndex = index;
    buildChains();
    updateState();
  }

  void onChangeSearch(String v) {
    searched = v;
    if (v.isEmpty) {
      filteredNetworks = buildedNetwork.clone();
    } else {
      filteredNetworks = buildedNetwork
          .where((e) => e.network.networkName.toLowerCase().contains(v.toLowerCase()))
          .toList();
    }
    updateState();
  }

  NetworkType findNetworkType(int index) {
    switch (index) {
      case 1:
        return NetworkType.xrpl;
      case 2:
        return NetworkType.ethereum;
      case 3:
        return NetworkType.tron;
      case 4:
        return NetworkType.solana;
      case 5:
        return NetworkType.cardano;
      case 6:
        return NetworkType.cosmos;
      case 7:
        return NetworkType.ton;
      case 8:
        return NetworkType.substrate;
      case 9:
        return NetworkType.stellar;
      case 10:
        return NetworkType.monero;
      case 11:
        return NetworkType.sui;
      case 12:
        return NetworkType.aptos;
      case 13:
        return NetworkType.zcash;
      default:
        return NetworkType.bitcoinAndForked;
    }
  }

  int findIndex(NetworkType? type) {
    switch (type) {
      case NetworkType.xrpl:
        return 1;
      case NetworkType.ethereum:
        return 2;
      case NetworkType.tron:
        return 3;
      case NetworkType.solana:
        return 4;
      case NetworkType.cardano:
        return 5;
      case NetworkType.cosmos:
        return 6;
      case NetworkType.ton:
        return 7;
      case NetworkType.substrate:
        return 8;
      case NetworkType.stellar:
        return 9;
      case NetworkType.monero:
        return 10;
      case NetworkType.sui:
        return 11;
      case NetworkType.aptos:
        return 12;
      case NetworkType.zcash:
        return 13;
      default:
        return 0;
    }
  }

  void buildChains() {
    buildedNetwork = allNetworks[currentNetwork]!;
    if (!showTestnet) {
      buildedNetwork = buildedNetwork
          .where((e) =>
              e.network.coinParam.chainType.isMainnet ||
              e.network == widget.selectedNetwork)
          .toList();
    }
    switch (currentNetwork) {
      case NetworkType.ethereum:
      case NetworkType.cosmos:
      case NetworkType.substrate:
        showImport = currentNetwork;
        break;
      default:
        showImport = null;
        break;
    }
    onChangeSearch(searched);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    initNetwork();
  }

  @override
  void safeDispose() {
    allChains = [];
    progressKey.dispose();
    super.safeDispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstraintsBoxView(
      alignment: Alignment.center,
      maxHeight: APPConst.maxDialogHeight,
      padding: WidgetConstant.padding20,
      maxWidth: APPConst.dialogWidth,
      child: ClipRRect(
        borderRadius: WidgetConstant.border25,
        child: Scaffold(
          appBar: AppBar(
            title: AppTextField(
                prefixIcon: Icon(Icons.search),
                hint: "switch_network".tr,
                autofocus: false,
                onChanged: onChangeSearch),
            leading: const SizedBox(),
            leadingWidth: 0,
            actions: [
              TextButton.icon(
                  onPressed: toggleShowTestnet,
                  label: Text('testnets'.tr),
                  icon: APPCheckBox(
                    ignoring: true,
                    value: showTestnet,
                    onChanged: (_) {},
                  )),
              const CloseButton(),
              WidgetConstant.width8
            ],
          ),
          // shrinkWrap: true,
          body: StreamPageProgress(
            controller: progressKey,
            builder: (c) => Row(
              children: [
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
                                destinations: [
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.btc,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.xrp,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.eth,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.trx,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.sol,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.ada,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.atom,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.gram,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.substrate,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.stellar,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.monero,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.sui,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.aptos,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                  NavigationRailDestination(
                                      icon: CircleAssetsImageView(APPConst.zcash,
                                          radius: imageRadius),
                                      label: WidgetConstant.sizedBox),
                                ],
                                selectedIndex: initialIndex),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const VerticalDivider(),
                Expanded(
                    child: EmptyItemWidgetView(
                  isEmpty: filteredNetworks.isEmpty,
                  itemBuilder: () {
                    return AnimatedSwitcher(
                      duration: APPConst.animationDuraion,
                      child: _NetworksView(
                          widget.selectedNetwork, filteredNetworks, showImport,
                          key: ValueKey(initialIndex)),
                    );
                  },
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworksView extends StatelessWidget {
  const _NetworksView(this.selected, this.networks, this.import, {super.key});
  final WalletNetwork selected;
  final List<Chain> networks;
  final NetworkType? import;
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ConditionalWidget(
          onActive: (context) => SliverAppBar(
            pinned: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("import_new_network".tr,
                    style: context.textTheme.titleMedium
                        ?.copyWith(color: context.colors.surface)),
                Text("add_new_network".tr.replaceOne(import?.name ?? ''),
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: context.colors.surface))
              ],
            ),
            leading: WidgetConstant.sizedBox,
            leadingWidth: 0,
            floating: true,
            backgroundColor: context.colors.onSurface,
            foregroundColor: context.colors.surface,
            actions: [
              IconButton(
                  tooltip: "import".tr,
                  onPressed: () {
                    context.pop(import);
                  },
                  icon: const Icon(Icons.add_box)),
              WidgetConstant.width8,
            ],
          ),
          enable: import != null,
          onDeactive: (context) => SliverPadding(padding: EdgeInsets.zero),
        ),
        SliverList.separated(
          itemBuilder: (context, index) {
            final net = networks[index].network;
            final balance = networks[index].totalBalance;
            return Padding(
              padding: WidgetConstant.paddingHorizontal20,
              child: InkWell(
                borderRadius: WidgetConstant.border8,
                onTap: selected == net
                    ? null
                    : () {
                        context.pop(networks[index]);
                      },
                child: Padding(
                  padding: WidgetConstant.padding5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              CircleTokenImageView(net.coinParam.token, radius: 20),
                              if (net.coinParam.isTestNet)
                                ToolTipView(
                                  message: "testnet_price_desc".tr,
                                  child: Text(
                                    "testnet".tr,
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(color: context.colors.error),
                                  ),
                                ),
                            ],
                          ),
                          WidgetConstant.width8,
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(net.coinParam.token.symbol,
                                  style: context.textTheme.labelLarge),
                              OneLineTextWidget(net.coinParam.token.name),
                              CoinAndMarketLivePriceView(liveBalance: balance),
                            ],
                          )),
                          WidgetConstant.width8,
                          if (selected == net) const Icon(Icons.check_circle)
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          itemCount: networks.length,
          separatorBuilder: (context, index) => WidgetConstant.divider,
        )
      ],
    );
  }
}

class SwitchNetworkIcon extends StatelessWidget {
  final Chain account;
  const SwitchNetworkIcon({required this.account, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () async {
          await context
              .openDialogPage("switch_network".tr,
                  fullWidget: (context) =>
                      SwitchNetworkView(selectedNetwork: account.network))
              .then(
            (value) {
              if (value == null) return;
              if (context.mounted) {
                switch (value) {
                  case Chain network:
                    context.wallet.wallet
                        .doAction(WalletActionSwitchNetwork(network: network))
                        .then((e) {
                      if (e.isErr) context.showAlert(e.unwrapErr().localizationError);
                    });
                    break;
                  case NetworkType network:
                    context.mybeTo(PageRouter.importNetwork(network));
                }
              }
            },
          );
        },
        icon:
            CircleTokenImageView(account.network.token, radius: APPConst.circleRadius12));
  }
}
