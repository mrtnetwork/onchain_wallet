// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/qr_code_scanner/state/barcode_scanner.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'dart:ui_web' as ui_web;

State<BarcodeScannerView> barcodeScannerState() => _WebBarcodeScannerViewState();

class _WebBarcodeScannerViewState extends State<BarcodeScannerView> with SafeState {
  late bool isSecure;
  String id = "barcode_scanner_camera";
  bool supported = false;
  bool hasVideo = false;
  String? barcde;
  final GlobalKey globalKey = GlobalKey();
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  MediaStream? stream;
  HTMLVideoElement? videoElement;
  StreamSubscription<String>? onData;

  Future<HTMLVideoElement> _loadVideo() async {
    stream ??=
        await jsWindow.navigator.mediaDevices.getUserMedia_(video: true, audio: false);
    final String id = DateTime.now().microsecondsSinceEpoch.toString();
    final HTMLVideoElement videoElement = jsWindow.document.createVideoElement()
      ..id = id
      ..autoplay = true
      ..srcObject = stream;
    ui_web.platformViewRegistry.registerViewFactory(id, (int viewId) => videoElement);
    return videoElement;
  }

  void detectBarcode(String message) async {
    _dispose();
    progressKey.success(
        progressWidget: SuccessBarcodeProgressView(
          text: message,
          secure: isSecure,
          bottomWidget: Column(
            children: [
              FilledButton(
                  onPressed: () {
                    context.pop(message);
                  },
                  child: Text("submit".tr)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        progressKey.progress(
                            ProgressWithTextView(text: "getting_scanner_ready".tr));
                        init();
                      },
                      icon: const Icon(Icons.camera))
                ],
              ),
            ],
          ),
        ),
        backToIdle: false);
  }

  Future<void> init() async {
    final result = await IResult.call(() async {
      supported = jsWindow.barcode != null;
      final stream = await _loadVideo();
      final detector = BarcodeDetector(null);
      return (stream, detector);
    });
    result.fold(
      onOk: (value) async {
        id = value.$1.id ?? id;
        videoElement = value.$1;
        progressKey.backToIdle();
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            if (closed) return;
            onData = value.$2.stream(value.$1).listen((v) {
              detectBarcode(v);
            });
          },
        );
      },
      onErr: (error) {
        _dispose();
        if (!supported) {
          progressKey.errorText("barcode_scanner_not_supported_browser".tr,
              backToIdle: false);
        } else {
          progressKey.errorText(error.localizationError, backToIdle: false);
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isSecure = context.getNullArgruments<bool>() ?? false;
    init();
  }

  void _dispose() {
    progressKey.dispose();
    onData?.cancel();
    videoElement?.srcObject = null;
    stream?.stop();
    stream = null;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialPageView(
        child: ScaffoldPageView(
            appBar: AppBar(title: Text("qr_code_scanner".tr)),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: WidgetConstant.padding20,
                    child: Container(
                      key: globalKey,
                      child: StreamPageProgress(
                        initialWidget:
                            ProgressWithTextView(text: "getting_scanner_ready".tr),
                        controller: progressKey,
                        builder: (c) => HtmlElementView(viewType: id),
                      ),
                    ),
                  ),
                ),
              ],
            )));
  }
}
