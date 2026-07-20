import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/start/pages/start_wallet_page.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'account_page.dart';
import 'login_page.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    return UnfocusableChild(
      child: StateBuilder(
          controller: () => wallet,
          disposeStrategy: StateBuilderDisposeStrategy.never,
          builder: (controller) {
            final status = wallet.appStatus;
            return PopScope(
              canPop: controller.canPop,
              onPopInvokedWithResult: controller.onAppBackButton,
              child: APPAnimatedSwitcher(enable: status.status, widgets: {
                APPStatusType.ready: (context) => _APPPage(wallet),
                APPStatusType.init: (context) => ProgressWithAPPLogo(),
                APPStatusType.failed: (context) => Text(status.error!)
              }),
            );
          },
          repositoryId: StateConst.main),
    );
  }
}

class _APPPage extends StatelessWidget {
  final WalletProvider wallet;
  const _APPPage(this.wallet);
  @override
  Widget build(BuildContext context) {
    return APPStreamWidget<WalletEvent>(
      stream: wallet.wallet.status,
      allowNotify: (value) {
        if (value.action.isLogin) {
          return value.status.isSuccess;
        }
        return value.action.rebuild;
      },
      builder: (context, value) {
        return APPAnimated(
            isActive: wallet.wallet.isOpen,
            onDeactive: (context) {
              if (value.inProgress) {
                return ProgressWithAPPLogo();
              }
              return switch (value.walletStatus) {
                WStatus.init => ProgressWithAPPLogo(),
                WStatus.setup => const StartWalletPage(),
                WStatus.lock => const WalletLoginPageView(),
                _ => WidgetConstant.sizedBox
              };
            },
            onActive: (context) => _UnlockWalletView(wallet: wallet, status: value));
      },
    );
  }
}

class _UnlockWalletView extends StatelessWidget {
  final WalletProvider wallet;
  final WalletEvent status;
  const _UnlockWalletView({required this.wallet, required this.status});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: wallet.onRefresh,
      notificationPredicate: (notification) {
        return wallet.allowRefresh;
      },
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
              hasScrollBody: false,
              child: Shimmer(
                  onActive: (e, context) => NetworkAccountPageView(
                      wallet: wallet, account: wallet.wallet.currentChain),
                  enable: !status.inProgress)),
        ],
      ),
    );
  }
}
