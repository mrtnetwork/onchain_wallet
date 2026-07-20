// import 'dart:developer';
// import 'dart:js_interop';

// import 'package:on_chain_bridge/web/api/window/window.dart';
// import 'package:test/expect.dart';

// @JS("encodeURIComponent")
// external String encodeURIComponent(String uriComponent);
// @JS("workerListener_")
// external set workerListener(JSFunction? f);
// @JS("workerListener_")
// external JSFunction get workerListener;

// @JS("errorListener_")
// external set onWorkerErrorListener(JSFunction? f);
// @JS("errorListener_")
// external JSFunction get onWorkerErrorListener;
// void main() async {
//   log("its jafar");
//   // return;
//   final data = await jsWindow.fetchText("http://localhost:8080/pkg/http.js");
//   final url = "data:text/javascript,${encodeURIComponent(data)}";

//   final worker = Worker(url, WorkerOptions()..type = "module");
//   int i = 0;
//   String r = "";
//   onWorkerErrorListener = (MessageEvent event) {
//     r = "error";
//   }.toJS;
//   worker.addEventListener("error", onWorkerErrorListener);
//   workerListener = (MessageEvent e) {
//     r = (e.data as JSString?)?.toDart ?? "no msg";
//   }.toJS;
//   worker.addEventListener("message", workerListener);
//   worker.postMessage("jafar".toJS);
//   // int i = 100;
//   // r.onmessage = (JSAny r) {
//   //   i = -1;
//   // }.toJS;
//   // r.onerror = () {
//   //   i = 10;
//   // }.toJS;
//   await Future.delayed(const Duration(seconds: 5));
// }
