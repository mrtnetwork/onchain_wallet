import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/utils.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/future/wallet/web3/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/walletconnect/wallet_connect.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

enum _PairingStatus {
  idle,
  connecting;

  bool get isIdle => this == idle;
}

class WalletConnectView extends StatefulWidget {
  const WalletConnectView({super.key});

  @override
  State<WalletConnectView> createState() => _WalletConnectViewState();
}

class _WalletConnectViewState extends State<WalletConnectView>
    with SafeState<WalletConnectView> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  late WalletProvider wallet;
  late IWeb3WalletConnectController walletConnect;
  SocketConnectionStatus get status => walletConnect.connectionStatus.value;

  List<ShimmerAction<Web3ClientInfo>> sessions = [];
  Future<void> loadSessions() async {
    final result = await walletConnect.getActiveSessions();
    sessions = result.map((e) => ShimmerAction<Web3ClientInfo>(object: e)).toList();
    progressKey.backToIdle();
  }

  Future<IResult<void>> connect(
      {required Uri pairUrl,
      required OnceCancelableTemplate<BridgeEventWeb3PairingPropose> cancelable}) async {
    final result = await walletConnect.pair(pairUrl, cancelable: cancelable);
    return result.map((e) {
      context.backToCurrent();
    }).mapErr((e) {
      if (e.exception != AppExceptionConst.requestCanceled) {
        context.showAlert(e.localizationError);
      }
      return e.exception;
    });
    // await loadSessions();
  }

  Future<void> onRemoveSession(ShimmerAction<Web3ClientInfo> session) async {
    final accept = await context.openSliverDialog(
        widget: (context) {
          return DialogTextView(
              text: "remove_session_desc".tr, buttonWidget: DialogDoubleButtonView());
        },
        label: "remove_session".tr);
    if (accept != true) return;
    session.setAction(true);
    updateState();
    await walletConnect.disconnectSession(session.object);
    sessions.remove(session);
    session.setAction(false);
    updateState();
    context.showAlert('session_has_been_removed'.tr);
  }

  Future<void> updateDappAuthenticated(Web3PermissionUpdateResponse update) async {
    if (update.hasRequiredPermission) {
      if (update.chains.isEmpty) return;
      await walletConnect.updateAuthenticated(update.appInfo);
    } else {
      await walletConnect.disconnectSession(update.appInfo.clientInfo);
    }
    context.showAlert("application_updated".tr);
  }

  Future<void> updateApplicationAuthenticated(
      ShimmerAction<Web3ClientInfo> client) async {
    client.setAction(true);
    final app =
        (await wallet.wallet.doAction(WalletActionWeb3Dapp(client: client.object)))
            .unwrap();
    updateState();
    List<Chain> lockedChains = [];
    final session = walletConnect.getSession(peerKey: app.authentication.applicationId);
    if (session != null) {
      final walletChain = wallet.wallet.getChains();
      final chainIds = await walletConnect.getSessionRequiredChainIds(
          session: session, auth: app.dappData);
      chainIds.watch(
        onErr: (error) => context.showAlert(error.localizationError),
        onOk: (chainIds) {
          lockedChains =
              walletChain.where((e) => chainIds.contains(e.network.value)).toList();
        },
      );
    }
    final request = Web3UpdatePermissionRequest.chain(
        lockedChains: lockedChains,
        authentication: app.authentication,
        client: client.object);
    await context.openDialogPage(
      "update_permission".tr,
      fullWidget: (context) => Web3PermissionUpdateView(
          authenticated: request,
          onPermissionUpdate: (update) async {
            await updateDappAuthenticated(update);
            return false;
          }),
    );
    client.setAction(false);
    updateState();
  }

  Future<void> newPair() async {
    if (!status.connected) return;
    await context.openDialogPage<bool>('',
        child: (context) => _ConnectPairingView(this),
        routeName: PageRouter.walletConnectPairing);
  }

  void toggleConnection() {
    if (status.closed) {
      walletConnect.connect();
    } else {
      walletConnect.close();
    }
  }

  Future<void> _onSessionUpdated(var _) async {
    await loadSessions();
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    walletConnect = wallet.wallet.walletConnect;
    walletConnect.onSessionUpdated.stream.listen(_onSessionUpdated);
    loadSessions();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('wallet_connect_management'.tr)),
      body: StreamPageProgress(
          controller: progressKey,
          initialWidget: ProgressWithTextView(text: "loading_sessions_please_wait".tr),
          builder: (context) {
            return CustomScrollView(
              slivers: [
                APPStreamBuilder(
                  value: walletConnect.connectionStatus,
                  builder: (context, value) => MultiSliver(children: [
                    SliverToBoxAdapter(
                      child: Column(children: [
                        Shimmer(
                            ignoring: false,
                            onActive: (_, context) => AppSwitchListTile(
                                  value: !value.closed,
                                  onChanged: (p0) => toggleConnection(),
                                  title: Text("enable_wallet_connect".tr),
                                  subtitle: Text(value.status.tr),
                                  leading: APPAnimated(onActive: (context) => value.icon),
                                ),
                            enable: !value.isPending),
                        APPAnimated(
                            isActive: value.connected,
                            onActive: (context) => AppListTile(
                                title: Text("pair_with_new_client".tr),
                                subtitle: Text("tap_to_pair_with_new_client".tr),
                                leading: Icon(Icons.add_box),
                                onTap: newPair),
                            onDeactive: (context) => WidgetConstant.sizedBox),
                        WidgetConstant.height20,
                      ]),
                    ),
                    SliverConstraintsBoxView(
                        padding: WidgetConstant.paddingHorizontal20,
                        sliver: SliverVisibility(
                            visible: sessions.isNotEmpty && value.connected,
                            sliver: MultiSliver(children: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("sessions".tr,
                                        style: context.textTheme.titleMedium),
                                    WidgetConstant.height8,
                                  ],
                                ),
                              ),
                              SliverList.separated(
                                  itemBuilder: (context, index) {
                                    final obj = sessions[index];
                                    final client = sessions[index].object;
                                    return Shimmer(
                                        onActive: (enable, context) {
                                          return ContainerWithBorder(
                                            onRemove: () {},
                                            enableTap: false,
                                            onRemoveWidget: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                      tooltip: "remove_session".tr,
                                                      onPressed: () =>
                                                          onRemoveSession(obj),
                                                      icon: Icon(Icons.remove_circle,
                                                          color: context
                                                              .onPrimaryContainer)),
                                                  IconButton(
                                                      tooltip: "update_permission".tr,
                                                      onPressed: () {
                                                        updateApplicationAuthenticated(
                                                            obj);
                                                      },
                                                      icon: Icon(Icons.security,
                                                          color: context
                                                              .onPrimaryContainer)),
                                                ]),
                                            child: Row(
                                              children: [
                                                CircleAPPImageView(
                                                  client.image,
                                                  radius: APPConst.circleRadius25,
                                                  onError: (c) => const Icon(
                                                      Icons.broken_image,
                                                      size: APPConst.double40),
                                                ),
                                                WidgetConstant.width8,
                                                Flexible(
                                                    child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    OneLineTextWidget(client.name,
                                                        style: context.onPrimaryTextTheme
                                                            .labelLarge),
                                                    OneLineTextWidget(client.url,
                                                        style: context.onPrimaryTextTheme
                                                            .bodyMedium),
                                                  ],
                                                )),
                                              ],
                                            ),
                                          );
                                        },
                                        enable: !obj.action);
                                  },
                                  itemCount: sessions.length,
                                  separatorBuilder: (context, index) =>
                                      WidgetConstant.divider)
                            ])))
                  ]),
                )
              ],
            );
          }),
    );
  }
}

class _ConnectPairingView extends StatefulWidget {
  final _WalletConnectViewState state;
  const _ConnectPairingView(this.state);

  @override
  State<_ConnectPairingView> createState() => _ConnectPairingViewState();
}

class _ConnectPairingViewState extends State<_ConnectPairingView>
    with SafeState<_ConnectPairingView> {
  late WalletProvider wallet;
  // late Web3WalletController walletConnect;
  final GlobalKey<AppTextFieldState> fieldKey = GlobalKey<AppTextFieldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  OnceCancelableTemplate<BridgeEventWeb3PairingPropose>? cancelable;
  String? error;
  void onBarcodeScanner(String url) {
    fieldKey.currentState?.updateText(url);
  }

  void onChangeUrl(String v) {
    pairUrl = v;
  }

  String pairUrl = "";
  StreamValue<SocketConnectionStatus> get status =>
      widget.state.walletConnect.connectionStatus;

  String? onValidatePairUrl(String? v) {
    if (v == null) return "invalid_pairing_url".tr;
    try {
      BridgeUtils.wcParseUri(Uri.parse(v));
      return null;
    } on AppException catch (e) {
      return e.message.tr;
    } catch (e) {
      return "invalid_pairing_url".tr;
    }
  }

  _PairingStatus pairingStatus = _PairingStatus.idle;

  Future<void> connect() async {
    if (!formKey.ready()) return;
    final cancelable = this.cancelable = OnceCancelableTemplate();
    error = null;
    pairingStatus = _PairingStatus.connecting;
    updateState();
    final url = Uri.parse(pairUrl);
    final result = await widget.state.connect(pairUrl: url, cancelable: cancelable);

    if (result.err()?.canceled() ?? false) return;
    if (result.isErr) {
      error = result.unwrapErr().localizationError;
      pairingStatus = _PairingStatus.idle;
      fieldKey.currentState?.clear();
      updateState();
    }
  }

  void disconnect() {
    cancelable?.cancel();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
  }

  @override
  void safeDispose() {
    super.safeDispose();
    cancelable?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverAppBar(
            title: Text("pair_with_new_client".tr),
            centerTitle: false,
            actions: [
              WalletConnectIcon(
                openPage: false,
              ),
              WidgetConstant.width8,
            ],
          ),
          SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: MultiSliver(children: [
                SliverToBoxAdapter(
                  child: APPStreamBuilder(
                    value: status,
                    builder: (context, value) {
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("pairing_url".tr, style: context.textTheme.titleMedium),
                            Text("enter_pairing_url_for_connect".tr),
                            WidgetConstant.height8,
                            Shimmer(
                                onActive: (enable, context) => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppTextField(
                                            key: fieldKey,
                                            validator: onValidatePairUrl,
                                            label: 'pairing_url'.tr,
                                            prefixIcon: Icon(Icons.insert_link),
                                            initialValue: pairUrl,
                                            onChanged: onChangeUrl,
                                            pasteIcon: true,
                                            readOnly: !pairingStatus.isIdle,
                                            maxLines: 2,
                                            suffixIcon: Row(children: [
                                              BarcodeScannerIconView(onBarcodeScanner),
                                            ])),
                                      ],
                                    ),
                                enable: pairingStatus.isIdle),
                            ErrorTextContainer(error: error),
                            Padding(
                              padding: WidgetConstant.paddingVertical40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FixedElevatedButton(
                                      activePress:
                                          pairingStatus.isIdle && value.connected,
                                      onPressed: connect,
                                      child: ConditionalWidget(
                                        onActive: (context) => Text("connect".tr),
                                        enable: pairingStatus.isIdle,
                                        onDeactive: (context) =>
                                            Text("pairing_please_wait".tr),
                                      )),
                                ],
                              ),
                            ),
                          ]);
                    },
                  ),
                ),
              ])),
        ],
      ),
    );
  }
}

extension ExtSocketConnectionTranslate on SocketConnectionStatus {
  Widget get icon => switch (this) {
        SocketConnectionClosed() => Icon(Icons.block),
        SocketConnectionDisposed() => Icon(Icons.block),
        SocketConnectionPending() => Icon(Icons.sync),
        SocketConnectionDisconnected() => Icon(Icons.error),
        SocketConnectionConnected() => Icon(Icons.link),
      };
  String get status => switch (this) {
        SocketConnectionClosed() => "disconnect".tr,
        SocketConnectionDisposed() => "disable".tr,
        SocketConnectionPending() => "pending".tr,
        SocketConnectionDisconnected() => "disconnect".tr,
        SocketConnectionConnected() => "connect".tr,
      };
}

class WalletConnectIcon extends StatelessWidget {
  final bool openPage;
  const WalletConnectIcon({this.openPage = true, super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    return APPStreamBuilder(
      value: wallet.wallet.walletConnect.connectionStatus,
      builder: (context, value) {
        return IconButton(
          tooltip: value.status,
          onPressed: () {
            if (!openPage) return;
            context.to(PageRouter.walletConnect);
          },
          icon: BlinkingIcon(
              builder: (context) => Icon(
                    CustomIcons.wc,
                    color: switch (value) {
                      SocketConnectionPending() => context.colors.primary,
                      SocketConnectionDisconnected() => context.colors.error,
                      SocketConnectionConnected() => context.colors.primary,
                      _ => context.colors.primary.disabled
                    },
                  ),
              blinking: value.isPending),
        );
      },
    );
  }
}
