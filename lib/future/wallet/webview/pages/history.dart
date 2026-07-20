import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/webview/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class WebViewHistoriesView extends StatefulWidget {
  final WebViewController model;
  final List<WebViewTab> items;
  final bool isHistory;
  const WebViewHistoriesView({
    super.key,
    required this.model,
    required this.items,
    this.isHistory = false,
  });

  @override
  State<WebViewHistoriesView> createState() => _HistoriesPageState();
}

class _HistoriesPageState extends State<WebViewHistoriesView> with SafeState {
  late final List<WebViewTab> _tabs = List<WebViewTab>.from(widget.items);
  late List<WebViewTab> filteredTabs = List<WebViewTab>.from(widget.items);
  Map<DateTime, List<WebViewTab>> items = {};
  static Map<DateTime, List<WebViewTab>> groupVisitsByDate(List<WebViewTab> visits) {
    final Map<DateTime, List<WebViewTab>> groupedVisits = {};
    for (final visit in visits) {
      final DateTime dateKey = visit.lastVisit.toOnlyDate();
      groupedVisits[dateKey] ??= [];
      groupedVisits[dateKey]!.add(visit);
    }
    return groupedVisits;
  }

  void onChange(String v) {
    if (v.isEmpty) {
      filteredTabs = _tabs.clone();
    } else {
      filteredTabs = _tabs
          .where((e) => e.url.contains(v) || (e.title?.contains(v) ?? false))
          .toList();
    }
    items = groupVisitsByDate(filteredTabs);
    listKey = GlobalKey();
    updateState();
  }

  void remove(DateTime key, WebViewTab tab, int index) {
    _tabs.remove(tab);
    filteredTabs.remove(tab);
    items[key]?.remove(tab);
    if (items[key]?.isEmpty ?? false) {
      items.remove(key);
    }
    updateState();
    if (widget.isHistory) {
      widget.model.removeHistory(tab);
    } else {
      widget.model.removeBookmars(tab);
    }
    listKey.currentState?.removeIndex(index);
  }

  Future<void> clearHistories() async {
    final accept = await context.openSliverDialog(
      routeName: PageRouter.webviewRemoveHistory,
      widget: (context) => DialogTextView(
        text: widget.isHistory ? "remove_all_histories".tr : "remove_bookmarks".tr,
        buttonWidget: DialogDoubleButtonView(),
      ),
      label: widget.isHistory ? 'remove_histories'.tr : 'remove_all_bookmarks'.tr,
    );
    if (accept != true) return;
    if (widget.isHistory) {
      widget.model.clearHistory();
    } else {
      widget.model.clearBookmark();
    }
  }

  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  GlobalKey<APPRemovableListState> listKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MethodUtils.executeAfterDelay(() async {
      items = groupVisitsByDate(_tabs);
      progressKey.backToIdle();
    });
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
      builder: (c) => CustomScrollView(
        slivers: [
          SliverAppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                  onPressed: () {
                    widget.model.backToBorwser();
                  },
                  icon: Icon(Icons.arrow_back)),
              title: AppTextField(
                prefixIcon: Icon(Icons.search),
                onChanged: onChange,
                maxLines: 1,
                minlines: 1,
              ),
              actions: [
                TextButton.icon(
                  onPressed: clearHistories,
                  label: Text("remove_all".tr),
                  icon: const Icon(Icons.clear),
                )
              ],
              pinned: true),
          SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: EmptyItemSliverWidgetView(
                isEmpty: items.isEmpty,
                itemBuilder: (context) => APPAnimatedRemovableList(
                  length: filteredTabs.length,
                  shrinkWrap: true,
                  key: listKey,
                  itemBuilder: (context, int pos, animated, [bool? inRemove]) {
                    if (inRemove == true && filteredTabs.isEmpty ||
                        pos >= filteredTabs.length) {
                      return WidgetConstant.sizedBox;
                    }
                    final tab = filteredTabs[pos];
                    final DateTime dateKey = tab.lastVisit.toOnlyDate();
                    final index = items[dateKey]?.indexOf(tab) ?? -1;
                    final bool haveTitle = tab.viewTitle != null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      key: ValueKey(tab),
                      children: [
                        if (inRemove != true) ...[
                          if (pos > 0 && index == 0) WidgetConstant.height20,
                          if (index == 0) ...[
                            WidgetConstant.height8,
                            Text(dateKey.toOnlyDateStr(),
                                style: context.textTheme.titleMedium),
                          ],
                        ],
                        FadeTransition(
                          opacity: animated,
                          child: ContainerWithBorder(
                            padding: WidgetConstant.padding10,
                            onRemove: () {},
                            enableTap: false,
                            onRemoveWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      widget.model.openTabPage(tab);
                                    },
                                    icon: Icon(Icons.open_in_browser,
                                        color: context.onPrimaryContainer)),
                                IconButton(
                                    onPressed: () {
                                      remove(dateKey, tab, pos);
                                    },
                                    icon: Icon(Icons.delete,
                                        color: context.onPrimaryContainer)),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAPPImageView(
                                  tab.image,
                                  radius: APPConst.circleRadius12,
                                  onError: (c) => Icon(Icons.travel_explore_rounded,
                                      color: context.onPrimaryContainer),
                                  onProgress: (c) => Icon(Icons.travel_explore_rounded,
                                      color: context.onPrimaryContainer),
                                ),
                                WidgetConstant.width8,
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            tab.lastVisit.toTimeOnlyStr(),
                                            style: context.onPrimaryTextTheme.bodySmall,
                                          )
                                        ],
                                      ),
                                      if (haveTitle)
                                        OneLineTextWidget(tab.viewTitle!,
                                            style: context.onPrimaryTextTheme.labelLarge),
                                      OneLineTextWidget(tab.url,
                                          style: context.onPrimaryTextTheme.bodySmall),
                                    ])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ))
        ],
      ),
    );
  }
}
