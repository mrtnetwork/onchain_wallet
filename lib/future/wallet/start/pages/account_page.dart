import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/impls/tabs.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/manage_provider.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/cosmos.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/account/pages/account.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/monero.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/substrate.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/account/pages/account.dart';
import 'package:on_chain_wallet/future/wallet/start/pages/drawer_view.dart';
import 'package:on_chain_wallet/future/wallet/start/pages/platform_widgets/widgets.dart';
import 'package:on_chain_wallet/future/wallet/swap/pages/pages/swap.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/wallet_connect.dart';
import 'package:on_chain_wallet/future/wallet/webview/pages/web_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'account_no_adress.dart';
import 'account_appbar.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class NetworkAccountPageView extends StatelessWidget {
  const NetworkAccountPageView({super.key, required this.wallet, required this.account});
  final WalletProvider wallet;
  final Chain account;
  @override
  Widget build(BuildContext context) {
    final bool isReady = wallet.wallet.homePageStatus.isReady;
    final bool isOpen = wallet.wallet.isOpen;
    return ChainStreamBuilder(
        progressEventDelay: APPConst.oneSecoundDuration,
        allowNotify: [
          DefaultChainNotify.account,
          DefaultChainNotify.address,
          DefaultChainNotify.client,
          DefaultChainNotify.config
        ],
        builder: (context, lastEvent) {
          bool enableShimmer =
              lastEvent?.isProgressOf(DefaultChainNotify.address) ?? false;
          return Shimmer(
              onActive: (enable, context) => Scaffold(
                  drawer: Drawer(child: DrawerView()),
                  appBar: AppBar(
                    centerTitle: false,
                    toolbarHeight: isReady ? kToolbarHeight : 0,
                    actions: [
                      APPAnimatedSwitcher<WalletPage>(
                          enable: wallet.walletPage,
                          widgets: {
                            WalletPage.swap: (context) =>
                                SwitchNetworkIcon(account: account),
                            WalletPage.webview: (context) =>
                                WebViewAppBar(wallet.webviewContoller),
                          }),
                      ProviderStatusView(account.clientStatus),
                      WalletConnectIcon(),
                      appbarWidgets(true),
                    ],
                    title: ConditionalWidget(
                        onActive: (context) {
                          if (isOpen) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneLineTextWidget(account.network.networkName,
                                    style: context.textTheme.titleMedium),
                                if (account.network.coinParam.isTestNet)
                                  ToolTipView(
                                    message: "testnet_price_desc".tr,
                                    child: Text("testnet".tr,
                                        style: context.textTheme.labelSmall
                                            ?.copyWith(color: context.colors.error)),
                                  ),
                              ],
                            );
                          }
                          return Text(wallet.wallet.wallet.name);
                        },
                        enable: isReady),
                  ),
                  floatingActionButton: APPAnimatedSwitcher<
                      WalletPage>(enable: wallet.walletPage, widgets: {
                    WalletPage.webview: (context) =>
                        WalletPageFloatingActionButton(account: account, wallet: wallet),
                    WalletPage.wallet: (context) =>
                        WalletPageFloatingActionButton(account: account, wallet: wallet),
                  }),
                  bottomNavigationBar: ConditionalWidget(
                    enable: wallet.multipleTab,
                    onActive: (context) => BottomNavigationBar(
                        currentIndex: wallet.homepageIndex,
                        onTap: wallet.onChangeIndex,
                        items: [
                          BottomNavigationBarItem(
                              icon: Icon(Icons.wallet), label: 'wallet'.tr),
                          if (wallet.enableSwap)
                            BottomNavigationBarItem(
                                icon: Icon(Icons.swap_horiz_rounded), label: 'swap'.tr),
                          if (wallet.enableWebView)
                            BottomNavigationBarItem(
                                icon: Icon(Icons.travel_explore_outlined),
                                label: 'webview'.tr),
                        ]),
                  ),
                  body: ConditionalWidget(
                      enable: wallet.multipleTab,
                      onDeactive: (context) => _WalletPage(account),
                      onActive: (context) => IndexedStack(
                            index: wallet.homepageIndex,
                            children: [
                              _WalletPage(account),
                              if (wallet.enableSwap)
                                SwapView(swapController: wallet.swap!, account: account),
                              if (wallet.enableWebView) WebView(wallet.webviewContoller!)
                            ],
                          ))),
              enable: !enableShimmer);
        },
        account: account);
  }
}

class _WalletPage extends StatelessWidget {
  const _WalletPage(this.account);
  final Chain account;

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    return DefaultTabController(
      length: account.services.length,
      key: ValueKey(account.services.length),
      child: NestedScrollView(headerSliverBuilder: (context, innerBoxIsScrolled) {
        if (!account.haveAddress) return [];
        return [
          SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate:
                      AccountPageSliverHeaderDelegate(wallet: wallet, account: account))),
        ];
      }, body: Builder(builder: (context) {
        if (!account.haveAddress) {
          return NoAccountFoundInChainWidget(account);
        }
        return _AccountPageView(account);
      })),
    );
  }
}

class _AccountPageView extends StatelessWidget {
  const _AccountPageView(this.account);
  final Chain account;

  @override
  Widget build(BuildContext context) {
    final network = account.network;
    switch (network.type) {
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        return BitcoinAccountPageView(chainAccount: account.cast());
      case NetworkType.xrpl:
        return RippleAccountPageView(account: account.cast());
      case NetworkType.solana:
        return SolanaAccountPageView(chainAccount: account.cast());
      case NetworkType.monero:
        return MoneroAccountPageView(chainAccount: account.cast());
      case NetworkType.stellar:
        return StellarAccountPageView(chainAccount: account.cast());
      case NetworkType.ethereum:
        return ETHAccountPageView(chainAccount: account.cast());
      case NetworkType.tron:
        return TronAccountPageView(chainAccount: account.cast());
      case NetworkType.cardano:
        return CardanoAccountPageView(chainAccount: account.cast());
      case NetworkType.ton:
        return TonAccountPageView(account: account.cast());
      case NetworkType.substrate:
        return SubstrateAccountPageView(chainAccount: account.cast());
      case NetworkType.cosmos:
        return CosmosAccountPageView(chainAccount: account.cast());
      case NetworkType.sui:
        return SuiAccountPageView(chainAccount: account.cast());
      case NetworkType.aptos:
        return AptosAccountPageView(chainAccount: account.cast());
      case NetworkType.zcash:
        return ZcashAccountPageView(chainAccount: account.cast());
    }
  }
}

class WalletPageFloatingActionButton extends StatelessWidget {
  final WalletProvider wallet;
  final Chain account;
  const WalletPageFloatingActionButton(
      {required this.wallet, required this.account, super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: context.colors.transparent,
        onPressed: () async {
          await context
              .openDialogPage("switch_network".tr,
                  fullWidget: (context) =>
                      SwitchNetworkView(selectedNetwork: account.network))
              .then(
            (value) {
              switch (value) {
                case Chain network:
                  wallet.wallet
                      .doAction(WalletActionSwitchNetwork(network: network))
                      .then((e) {
                    if (e.isErr) context.showAlert(e.unwrapErr().localizationError);
                  });
                  break;
                case NetworkType network:
                  context.mybeTo(PageRouter.importNetwork(network));
              }
            },
          );
        },
        child:
            CircleTokenImageView(account.network.token, radius: APPConst.circleRadius25));
  }
}
