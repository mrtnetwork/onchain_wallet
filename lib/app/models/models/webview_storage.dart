import 'package:on_chain_wallet/app/models/models/webview_tab.dart';
import 'package:on_chain_wallet/app/utils/list/extension.dart';

enum WebViewStorageType {
  tab(storageId: 0),
  hisotry(storageId: 1),
  bookmark(storageId: 2);

  const WebViewStorageType({required this.storageId});
  final int storageId;
}

abstract class WebViewStorage {
  abstract final WebViewStorageType type;
  List<WebViewTab> _tabs;
  List<WebViewTab> get tabs => _tabs;
  WebViewStorage(List<WebViewTab> tabs) : _tabs = tabs.immutable;

  void clear() {
    _tabs = <WebViewTab>[].immutable;
  }

  void remove(WebViewTab tab) {
    if (!_tabs.contains(tab)) return;
    final tabs = List<WebViewTab>.from(_tabs);
    tabs.remove(tab);
    _tabs = tabs.immutable;
  }

  bool addNewTab(WebViewTab newTab) {
    final tabs = List<WebViewTab>.from(_tabs);
    tabs.add(newTab);
    tabs.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
    _tabs = tabs.immutable;
    return _tabs.firstOrNull?.url != newTab.url;
  }

  WebViewTab? getLastObject() {
    if (_tabs.isEmpty) return null;
    return _tabs.first;
  }
}

class WebViewTabStorage extends WebViewStorage {
  WebViewTabStorage(super.tabs);

  @override
  WebViewStorageType get type => WebViewStorageType.tab;

  void removeTab(WebViewTab removeTab) {
    final tabs = List<WebViewTab>.from(_tabs);
    tabs.removeWhere((e) => e.id == removeTab.id);
    _tabs = tabs.immutable;
  }

  void addOrUpdateTab(WebViewTab newTab) {
    final find = _tabs.indexWhere((e) => e.id == newTab.id);
    if (find < 0) {
      addNewTab(newTab);
      return;
    }

    final tabs = List<WebViewTab>.from(_tabs);
    tabs[find] = newTab;
    tabs.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
    _tabs = List<WebViewTab>.unmodifiable(tabs);
  }
}

class WebViewHistoryStorage extends WebViewStorage {
  WebViewHistoryStorage(super.tabs);

  @override
  WebViewStorageType get type => WebViewStorageType.hisotry;
}

class WebViewBookmarkStorage extends WebViewStorage {
  WebViewBookmarkStorage(super.tabs);

  @override
  WebViewStorageType get type => WebViewStorageType.bookmark;

  bool inBokmark(WebViewTab tab) {
    return tabs.any((e) {
      if (tab.path != null) {
        return e.path == tab.path;
      }
      return tab.url == e.url;
    });
  }

  bool addOrRemoveFromBookMark(WebViewTab newTab) {
    final find = _tabs.indexWhere((e) {
      if (newTab.path != null) {
        return e.path == newTab.path;
      }
      return newTab.url == e.url;
    });
    if (find < 0) {
      addNewTab(newTab);
      return true;
    }
    final tabs = List<WebViewTab>.from(_tabs);
    tabs.removeAt(find);
    _tabs = tabs.immutable;
    return false;
  }
}
