import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/client_info.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/future/wallet/webview/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/webview/controller/controller/tab_handler.dart';
import 'package:on_chain_wallet/future/wallet/webview/pages/tabs.dart';
import 'package:on_chain_wallet/future/wallet/webview/pages/webview_search_bar.dart';
import 'package:on_chain_wallet/future/wallet/webview/view/native_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'history.dart';
import 'menu.dart';

class WebView extends StatelessWidget {
  const WebView(this.model, {super.key});
  final WebViewController model;

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: model.notifier,
        builder: (context, value) {
          return APPAnimated(
            isActive: model.inited,
            onActive: (context) => NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverPinnedHeaderSurface(
                      child: APPPreferredSizeWidget(
                          height: model.inBrowser ? 80 : 0,
                          child: APPAnimatedContainer(
                              isActive: model.inBrowser,
                              onActive: (c) => Column(
                                    children: [
                                      Row(
                                        children: [
                                          ConditionalWidget(
                                            enable: model.enableBackForwardKey,
                                            onActive: (context) => APPStreamBuilder(
                                              value: model.navigatorStatus,
                                              builder: (context, value) {
                                                return Row(
                                                  key: ValueKey(value),
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    _BooleanFutureIcon(
                                                        callBack: model.goBack,
                                                        icon: Icons.arrow_back,
                                                        enable: value.back),
                                                    _BooleanFutureIcon(
                                                        callBack: model.goForward,
                                                        icon: Icons.arrow_forward,
                                                        enable: value.forward),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          Flexible(
                                            child: APPStreamBuilder(
                                              value: model.controller.tab,
                                              builder: (context, value) => Padding(
                                                padding:
                                                    WidgetConstant.paddingHorizontal10,
                                                child: AppTextField(
                                                  controller: model.textController,
                                                  maxLines: 1,
                                                  canRequestFocus: false,
                                                  onTap: () {
                                                    model.onTapTextFeield(
                                                      () {
                                                        return context
                                                            .openDialogPage<String>('',
                                                                routeName:
                                                                    PageRouter
                                                                        .web3Permission_,
                                                                fullWidget: (context) =>
                                                                    WebViewSearchBarView(
                                                                        model));
                                                      },
                                                    );
                                                  },
                                                  keyboardType: TextInputType.url,
                                                  initialValue:
                                                      model.controller.tab.value.url,
                                                  prefixIcon: CircleAPPImageView(
                                                    model.controller.image,
                                                    radius: APPConst.circleRadius12,
                                                    onError: (c) => const Icon(
                                                        Icons.travel_explore_rounded),
                                                    onProgress: (c) => const Icon(
                                                        Icons.travel_explore_rounded),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          WebViewPopupMenu(model)
                                        ],
                                      ),
                                      APPStreamBuilder(
                                          value: model.progress,
                                          builder: (context, value) {
                                            if (value != null) {
                                              return SizedBox(
                                                height: 8,
                                                child:
                                                    LinearProgressIndicator(value: value),
                                              );
                                            }
                                            return WidgetConstant.height8;
                                          }),
                                    ],
                                  ),
                              onDeactive: (c) => WidgetConstant.sizedBox)))
                ];
              },
              body: APPAnimatedSwitcher(
                enable: model.page,
                widgets: {
                  WebViewTabPage.hide: (c) => Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.travel_explore, size: APPConst.double80)],
                      ),
                  WebViewTabPage.tabs: (c) => WebViewTabsView(model),
                  WebViewTabPage.browser: (c) => APPNativeView(
                        controller: model.controller.controller,
                        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                        platform: context.appContext.platform,
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer2()),
                        },
                      ),
                  WebViewTabPage.bookmarks: (c) =>
                      WebViewHistoriesView(model: model, items: model.bookmarks),
                  WebViewTabPage.history: (c) => WebViewHistoriesView(
                      model: model, items: model.histories, isHistory: true)
                },
                height: context.mediaQuery.size.height,
              ),
            ),
            onDeactive: (context) => const PageProgressChildWidget(
                Icon(Icons.travel_explore, size: APPConst.double80)),
          );
        });
  }
}

class _BooleanFutureIcon extends StatelessWidget {
  const _BooleanFutureIcon(
      {required this.callBack, required this.icon, required this.enable});
  final IconData icon;
  final bool enable;
  final DynamicVoid callBack;
  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: enable ? callBack : null, icon: Icon(icon));
  }
}

class EagerGestureRecognizer2 extends OneSequenceGestureRecognizer {
  /// Create an eager gesture recognizer.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  EagerGestureRecognizer2({super.supportedDevices, super.allowedButtonsFilter});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
    stopTrackingPointer(event.pointer);
  }

  @override
  String get debugDescription => 'eager';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {}
}

class WebViewAppBar extends StatelessWidget {
  final WebViewController? webviewController;
  const WebViewAppBar(this.webviewController, {super.key});

  @override
  Widget build(BuildContext context) {
    final model = webviewController;
    if (model == null) return WidgetConstant.sizedBox;
    return APPStreamBuilder(
        value: model.latestClient,
        builder: (context, client) => Web3ClientInfoIconView(
            client: client,
            onTap: (s) {
              model.updateApplicationAuthenticated(
                (authenticated, onPermissionUpdate) async {
                  if (authenticated == null) return;
                  context.openDialogPage(
                    "update_permission".tr,
                    fullWidget: (context) => Web3PermissionUpdateView(
                        authenticated: authenticated,
                        onPermissionUpdate: onPermissionUpdate),
                  );
                },
              );
            }));
  }
}
