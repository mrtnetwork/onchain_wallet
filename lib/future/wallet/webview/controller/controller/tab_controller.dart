import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/webview/view/native_view.dart';

class WebViewTabController {
  final APPAndroidViewController controller;
  final StreamValue<WebViewTab> _tab;
  final List<int> viewTypeBytes;
  final String viewId;
  WebViewTabController(
      {required this.controller,
      required this.viewId,
      required List<int> key,
      required WebViewTab tab})
      : viewTypeBytes = BytesUtils.fromHexString(viewId),
        _tab = StreamValue<WebViewTab>(tab, name: "WebViewTabController");
  StreamValue<WebViewTab> get tab => _tab;
  bool _inBookmark = false;
  bool get inBookmark => _inBookmark;

  String get url => tab.value.url;

  String get title => tab.value.title ?? "";

  String get tabId => _tab.value.id;
  APPImage? get image => _tab.value.image;

  void setTab(WebViewTab tab, bool inBookmark) {
    _inBookmark = inBookmark;
    _tab.value = tab;
  }

  void setBookmark(WebViewTab tab, bool inBookmark) {
    if (tab != _tab.value) return;
    _inBookmark = inBookmark;
  }

  // void dispose() {
  //   _tab.dispose();
  //   // await controller.dispose();
  // }
}
