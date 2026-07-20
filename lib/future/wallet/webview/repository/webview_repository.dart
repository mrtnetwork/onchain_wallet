import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/repository/repository.dart';

class WebViewRepository {
  WebViewRepository(IAppDatabaseApi database)
      : storage = StorageControllerDefault(
            tableId: MainTableDatabaseResources.appWebViewStorage.tableId,
            storage: MainTableDatabaseResources.appWebViewStorage.storage,
            database: database);
  final StorageControllerDefault storage;
  WebViewTabStorage _tabs = WebViewTabStorage(const []);
  WebViewHistoryStorage _histories = WebViewHistoryStorage(const []);
  WebViewBookmarkStorage _bookmarks = WebViewBookmarkStorage(const []);
  List<WebViewTab> get histories => _histories.tabs;
  List<WebViewTab> get bookmarks => _bookmarks.tabs;

  bool inBokmark(WebViewTab tab) {
    return _bookmarks.inBokmark(tab);
  }

  Future<IResult<List<WebViewTab>>> _getTabData(WebViewStorageType type,
      {int? limit}) async {
    final data = await storage.queriesStorage(
        storageId: type.storageId, actionId: StorageActionId.webview, createdAtGt: limit);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => WebViewTab.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "_getTabData",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  storage.removeStorageOperation(
                      operation: e.toRemoveOperation(),
                      actionId: StorageActionId.webview);
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<WebViewTab>().toList());
  }

  Future<WebViewTabStorage> _getTabs() async {
    final data = await _getTabData(WebViewStorageType.tab);
    return data.fold(
        onOk: (e) => WebViewTabStorage(e), onErr: (_) => WebViewTabStorage([]));
  }

  Future<WebViewHistoryStorage> _getHistories() async {
    final data = await _getTabData(WebViewStorageType.hisotry, limit: 500);
    return data.fold(
        onOk: (e) => WebViewHistoryStorage(e), onErr: (_) => WebViewHistoryStorage([]));
  }

  Future<WebViewBookmarkStorage> _getBookmarks() async {
    final data = await _getTabData(WebViewStorageType.bookmark);
    return data.fold(
        onOk: (e) => WebViewBookmarkStorage(e), onErr: (_) => WebViewBookmarkStorage([]));
  }

  Future<void> initRepository() async {
    _tabs = await _getTabs();
    _histories = await _getHistories();
    _bookmarks = await _getBookmarks();
  }

  WebViewTab? get lastTab => _tabs.getLastObject();

  List<WebViewTab> get tabs => _tabs.tabs;
  Future<IResult<void>> addOrRemoveFromBookMark(WebViewTab newTab) async {
    final add = _bookmarks.addOrRemoveFromBookMark(newTab);
    if (add) {
      return await storage.insertStorage(
          value: newTab,
          key: newTab.path ?? newTab.url,
          storageId: WebViewStorageType.bookmark.storageId,
          actionId: StorageActionId.webview);
    } else {
      return await storage.removeStorages(
          key: newTab.path ?? newTab.url,
          storageId: WebViewStorageType.bookmark.storageId,
          actionId: StorageActionId.webview);
    }
  }

  Future<IResult<void>> saveHistory(WebViewTab tab) async {
    if (tab.host != null && _histories.addNewTab(tab)) {
      return await storage.insertStorage(
          value: tab,
          key: tab.lastVisit.microsecondsSinceEpoch.toString(),
          storageId: WebViewStorageType.hisotry.storageId,
          actionId: StorageActionId.webview);
    }
    return ResultOk.okVoid;
  }

  Future<IResult<void>> updateTab(WebViewTab tab) async {
    _tabs.addOrUpdateTab(tab);
    return await storage.insertStorage(
        value: tab,
        key: tab.id,
        storageId: WebViewStorageType.tab.storageId,
        actionId: StorageActionId.webview);
  }

  Future<IResult<void>> removeTab(WebViewTab tab) async {
    _tabs.removeTab(tab);
    return await storage.removeStorages(
        key: tab.id,
        storageId: WebViewStorageType.tab.storageId,
        actionId: StorageActionId.webview);
  }

  Future<IResult<void>> removeHistory(WebViewTab tab) async {
    _histories.remove(tab);
    return await storage.removeStorages(
        key: tab.lastVisit.microsecondsSinceEpoch.toString(),
        storageId: WebViewStorageType.hisotry.storageId,
        actionId: StorageActionId.webview);
  }

  Future<IResult<void>> removeBookmark(WebViewTab tab) async {
    _bookmarks.remove(tab);
    return await storage.removeStorages(
        key: tab.path ?? tab.url,
        storageId: WebViewStorageType.bookmark.storageId,
        actionId: StorageActionId.webview);
  }

  Future<IResult<void>> clearHistory() async {
    _histories.clear();
    return await storage.removeStorages(
        storageId: WebViewStorageType.hisotry.storageId,
        actionId: StorageActionId.webview);
  }

  Future<IResult<void>> clearBookmark() async {
    _bookmarks.clear();
    return await storage.removeStorages(
        storageId: WebViewStorageType.bookmark.storageId,
        actionId: StorageActionId.webview);
  }
}
