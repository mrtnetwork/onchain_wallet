import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';

import 'package:on_chain_wallet/future/wallet/web3/controller/web3_request_controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/future/wallet/web3/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/walletconnect/wallet_connect.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class ManageWeb3DapssView extends StatelessWidget {
  const ManageWeb3DapssView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "dapps_management".tr,
      onAccsess: (_) {
        return _ManageWeb3DapssView();
      },
    );
  }
}

class _ManageWeb3DapssView extends StatefulWidget {
  const _ManageWeb3DapssView();

  @override
  State<_ManageWeb3DapssView> createState() => _WalletConnectActiveSessionsState();
}

class _WalletConnectActiveSessionsState extends State<_ManageWeb3DapssView>
    with SafeState<_ManageWeb3DapssView> {
  Web3RequestControllerImpl? web3Controller;
  late IWeb3WalletConnectController walletConnect;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  late WalletProvider wallet;
  List<ShimmerAction<Web3DappInfo>> sessions = [];
  Future<void> loadSessions() async {
    final result = await wallet.wallet.doAction(WalletActionAllWeb3Applications());
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError, backToIdle: false);
      return;
    }
    sessions =
        result.unwrap().map((e) => ShimmerAction<Web3DappInfo>(object: e)).toList();
    progressKey.backToIdle();
  }

  Future<void> resetDappAuthenticated(ShimmerAction<Web3DappInfo> app) async {
    final accept = await context.openSliverDialog<bool>(
        widget: (context) => DialogTextView(
              text: "reset_dapp_desc".tr,
              buttonWidget: DialogDoubleButtonView(),
            ),
        label: 'clear_dapp_permissions'.tr);
    if (accept != true) return;
    app.toggleAction();
    updateState();

    try {
      switch (app.object.authentication.protocol) {
        case Web3APPProtocol.walletConnect:
          final updateDapp = await wallet.wallet.doAction(
              WalletActionDisconnectWeb3Application(
                  application: app.object.authentication, removeApplication: true));
          assert(updateDapp.isOk);
          if (!updateDapp.isOk) return;
          await walletConnect.disconnectSession(app.object.clientInfo);
          break;
        case Web3APPProtocol.injected:
          final clinetExists = web3Controller?.clientExists(app.object) ?? false;
          final updateDapp = await wallet.wallet.doAction(
              WalletActionDisconnectWeb3Application(
                  application: app.object.authentication,
                  removeApplication: !clinetExists));
          if (!clinetExists) return;
          final result = updateDapp.ok();
          assert(result != null);
          if (result == null) return;
          await web3Controller?.updateClientAuthenticated(Web3DappInfo(
              authentication: app.object.authentication,
              dappData: result,
              clientInfo: app.object.clientInfo));
          break;
      }
    } finally {
      sessions.remove(app);
      app.toggleAction();
      updateState();
      context.showAlert("application_removed".tr);
    }
  }

  Future<void> updateDappAuthenticated(Web3PermissionUpdateResponse updatedAuth) async {
    switch (updatedAuth.authentication.protocol) {
      case Web3APPProtocol.walletConnect:
        if (updatedAuth.hasRequiredPermission &&
            updatedAuth.appInfo.dappData.hasAnyPermission) {
          await walletConnect.updateAuthenticated(updatedAuth.appInfo);
        } else {
          await walletConnect.disconnectSession(updatedAuth.appInfo.clientInfo);
        }
        break;
      case Web3APPProtocol.injected:
        await web3Controller?.updateClientAuthenticated(updatedAuth.appInfo);
        break;
    }
    context.showAlert("application_updated".tr);
  }

  Future<void> updateApplicationAuthenticated(ShimmerAction<Web3DappInfo> app) async {
    app.toggleAction();
    updateState();
    List<Chain> lockedChains = [];
    if (app.object.authentication.protocol.isWalletConnect) {
      final session =
          walletConnect.getSession(peerKey: app.object.authentication.applicationId);

      if (session != null) {
        final walletChain = wallet.wallet.getChains();
        final chainIds = await walletConnect.getSessionRequiredChainIds(
            session: session, auth: app.object.dappData);
        chainIds.watch(
          onErr: (error) => context.showAlert(error.localizationError),
          onOk: (chainIds) => lockedChains =
              walletChain.where((e) => chainIds.contains(e.network.value)).toList(),
        );
      }
    }
    final request = Web3UpdatePermissionRequest.chain(
        lockedChains: lockedChains, authentication: app.object.authentication);
    await context.openDialogPage(
      "update_permission".tr,
      fullWidget: (context) => Web3PermissionUpdateView(
          authenticated: request,
          onPermissionUpdate: (update) async {
            await updateDappAuthenticated(update);
            return false;
          }),
    );
    app.toggleAction();
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    walletConnect = wallet.wallet.walletConnect;
    if (wallet.supportWebView) {
      web3Controller = wallet.webviewContoller;
    } else if (wallet.isExtension) {
      web3Controller = wallet.wallet as Web3RequestControllerImpl;
    }
    loadSessions();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
        controller: progressKey,
        initialWidget: ProgressWithTextView(text: "loading_applications_please_wait".tr),
        builder: (context) => CustomScrollView(slivers: [
              SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: EmptyItemSliverWidgetView(
                  isEmpty: sessions.isEmpty,
                  itemBuilder: (context) {
                    return SliverList.separated(
                        itemBuilder: (context, index) {
                          final client = sessions[index];
                          final authentication = client.object.authentication;
                          return ShimmerActionView(
                            action: client,
                            onActive: (enable, context) {
                              return ContainerWithBorder(
                                onRemove: () {},
                                enableTap: false,
                                onRemoveWidget:
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                      tooltip: "clear_dapp_permissions".tr,
                                      onPressed: () {
                                        resetDappAuthenticated(client);
                                      },
                                      icon: Icon(Icons.remove_circle,
                                          color: context.onPrimaryContainer)),
                                  IconButton(
                                      tooltip: "update_permission".tr,
                                      onPressed: () {
                                        updateApplicationAuthenticated(client);
                                      },
                                      icon: Icon(Icons.security,
                                          color: context.onPrimaryContainer)),
                                ]),
                                child: Row(
                                  children: [
                                    CircleAPPImageView(
                                      authentication.icon,
                                      radius: APPConst.circleRadius25,
                                      onError: (c) => const Icon(Icons.broken_image,
                                          size: APPConst.double40),
                                    ),
                                    WidgetConstant.width8,
                                    Flexible(
                                        child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        OneLineTextWidget(authentication.name,
                                            style: context.onPrimaryTextTheme.labelLarge),
                                        OneLineTextWidget(
                                            authentication.url ??
                                                authentication.applicationId,
                                            style: context.onPrimaryTextTheme.bodyMedium),
                                      ],
                                    )),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        itemCount: sessions.length,
                        separatorBuilder: (context, index) => WidgetConstant.divider);
                  },
                ),
              )
            ]));
  }
}
