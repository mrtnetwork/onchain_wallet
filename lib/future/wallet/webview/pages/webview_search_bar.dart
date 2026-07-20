import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class WebViewSearchBarView extends StatefulWidget {
  final WebViewController controller;
  const WebViewSearchBarView(this.controller, {super.key});

  @override
  State<WebViewSearchBarView> createState() => _WebViewSearchBarViewState();
}

class _WebViewSearchBarViewState extends State<WebViewSearchBarView>
    with SafeState<WebViewSearchBarView> {
  String initialText = '';
  List<_SearchSuggest> searchSuggest = [];
  List<_SearchSuggest> tabs = [];
  void filterTabs(String v) {
    searchSuggest = [
      ...tabs
          .where((e) => e.url.contains(v) || (e.title?.contains(v) ?? false)),
      ..._suggest(v),
    ];
  }

  static const String https = 'https://';
  static const String http = 'http://';
  List<_SearchSuggest> _suggest(String v) {
    if (v.length <= http.length && http.startsWith(v)) {
      return [];
    } else if (v.length <= https.length && https.startsWith(v)) {
      return [];
    }
    if (v.startsWith(http)) {
      return [
        _SearchSuggest(
            url: v.replaceFirst(http, ''), type: _SearchSuggestType.search),
        _SearchSuggest(url: v, type: _SearchSuggestType.url),
        _SearchSuggest(
            url: v.replaceFirst(http, https), type: _SearchSuggestType.search),
      ];
    }
    if (v.startsWith(https)) {
      return [
        _SearchSuggest(
            url: v.replaceFirst(https, ''), type: _SearchSuggestType.search),
        _SearchSuggest(url: v, type: _SearchSuggestType.url),
        _SearchSuggest(
            url: v.replaceFirst(https, http), type: _SearchSuggestType.search),
      ];
    }
    return [
      _SearchSuggest(url: "$https$v", type: _SearchSuggestType.url),
      _SearchSuggest(url: "$http$v", type: _SearchSuggestType.url),
      _SearchSuggest(url: v, type: _SearchSuggestType.search)
    ];
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    tabs = {
      ...widget.controller.histories.map((e) => _SearchSuggest(
          url: e.url, type: _SearchSuggestType.history, title: e.title)),
      ...widget.controller.bookmarks.map((e) => _SearchSuggest(
          url: e.url, type: _SearchSuggestType.bookmark, title: e.title))
    }.toImutableList;

    initialText = widget.controller.textController.text;

    filterTabs(initialText);
  }

  void onSubmitField(String v) {
    if (v.startsWith(http) || v.startsWith(https)) {
      context.pop(v);
      return;
    }
    context.pop("${WebViewStateControllerConst.googleSerchUrl}$v");
  }

  void submit(_SearchSuggest suggest) {
    switch (suggest.type) {
      case _SearchSuggestType.search:
        context
            .pop("${WebViewStateControllerConst.googleSerchUrl}${suggest.url}");
        break;
      default:
        context.pop(suggest.url);
    }
  }

  void onChangeField(String v) {
    initialText = v;
    filterTabs(v);
    updateState();
  }

  final GlobalKey<AppTextFieldState> textFieldKey = GlobalKey();
  void onClearIcon() {
    textFieldKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialPageView(
        child: CustomScrollView(slivers: [
      SliverAppBar(
          pinned: true,
          title: AppTextField(
              initialValue: initialText,
              key: textFieldKey,
              onChanged: onChangeField,
              prefixIcon: Icon(Icons.search),
              autofocus: true,
              maxLines: 1,
              suffixIcon: APPAnimated(
                  isActive: initialText.trim().isNotEmpty,
                  onActive: (context) => IconButton(
                      onPressed: onClearIcon, icon: Icon(Icons.clear)),
                  onDeactive: (context) => null),
              onSubmitField: onSubmitField)),
      SliverPadding(
        padding: WidgetConstant.paddingHorizontal20,
        sliver: SliverList.builder(
            itemBuilder: (context, index) {
              final suggest = searchSuggest[index];
              return AppListTile(
                leading: ConditionalWidgets<_SearchSuggestType>(
                    enable: suggest.type,
                    widgets: {
                      _SearchSuggestType.bookmark: (context) =>
                          Icon(Icons.bookmark),
                      _SearchSuggestType.history: (context) =>
                          Icon(Icons.history),
                      _SearchSuggestType.search: (context) =>
                          Icon(Icons.search),
                      _SearchSuggestType.url: (context) =>
                          Icon(Icons.open_in_browser),
                    }),
                onTap: () => submit(suggest),
                title: OneLineTextWidget(suggest.url),
              );
            },
            itemCount: searchSuggest.length),
      ),
    ]));
  }
}

class _SearchSuggest with Equality {
  final String url;
  final String? title;
  final _SearchSuggestType type;

  const _SearchSuggest({required this.url, this.title, required this.type});

  @override
  List get variables => [url];
}

enum _SearchSuggestType { search, url, bookmark, history }
