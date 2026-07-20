import 'package:flutter/material.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart' show APPConst, IResult, ResultOk, StrUtils;
import 'package:on_chain_wallet/future/widgets/widgets/animated/widgets/animated_switcher.dart';
import 'package:on_chain_wallet/future/widgets/widgets/progress_bar/widgets/progress.dart';
import '../../constraints_box_view.dart';
import '../qr_code/qr_view.dart';
import '../../widget_constant.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class BarcodeImageView extends StatefulWidget {
  final String data;
  final bool isSensitive;
  final String? title;
  final String? shareTitle;
  final String? name;
  const BarcodeImageView(
      {required this.data,
      required this.name,
      this.shareTitle,
      this.title,
      this.isSensitive = false,
      super.key});

  @override
  State<BarcodeImageView> createState() => _BarcodeImageViewState();
}

class _BarcodeImageViewState extends State<BarcodeImageView>
    with SafeState<BarcodeImageView> {
  final buttonState = GlobalKey<StreamWidgetState>();
  final saveButtonState = GlobalKey<StreamWidgetState>();
  IBuffer? barcodeBytes;
  Future<IResult<IBuffer?>> getBarcodeBytes() async {
    final barcodeBytes = this.barcodeBytes;
    if (barcodeBytes != null) {
      return ResultOk(barcodeBytes);
    }
    final data = await QrUtils.qrCodeToBytes(
        data: widget.data,
        uderImage: '',
        color: context.theme.colorScheme,
        context: context.appContext);
    return data.map((value) {
      this.barcodeBytes = value;
      return value;
    });
  }

  Future<void> share() async {
    buttonState.process();
    final bytes = await getBarcodeBytes();
    final result = await bytes.andThenAsync((e) async {
      if (e == null) return ResultOk(false);
      return await context.appContext.platformUtls.shareFile(
          buffer: e,
          name: StrUtils.toFileName(DateTime.now()),
          type: AppFileType.imagePng,
          text: widget.shareTitle);
    });
    result.fold(
      onErr: (error) {
        buttonState.error();
        context.showAlert(error.localizationError);
      },
      onOk: (value) async {
        if (!value) {
          buttonState.error();
          return;
        }

        buttonState.success();
      },
    );
  }

  Future<void> save() async {
    saveButtonState.process();
    final bytes = await getBarcodeBytes();
    bytes.fold(
      onErr: (error) {
        saveButtonState.error();
        context.showAlert(error.localizationError);
      },
      onOk: (value) async {
        if (value == null) {
          saveButtonState.error();
          return;
        }
        await context.appContext.platformUtls.saveFile(
            buffer: value,
            name: StrUtils.toFileName(DateTime.now()),
            type: AppFileType.imagePng,
            title: widget.shareTitle);
        saveButtonState.success();
      },
    );
  }

  bool show = false;
  double opacity = 0.1;
  void showContent() {
    show = !show;
    opacity = 1;
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    if (!widget.isSensitive) {
      show = true;
      opacity = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverAppBar(
          title: Text(widget.title ?? ''),
          actions: [
            ButtonProgress(
                child: (context) => IconButton(onPressed: save, icon: Icon(Icons.save)),
                backToIdle: Duration.zero,
                key: saveButtonState),
            ButtonProgress(
                child: (context) => IconButton(onPressed: share, icon: Icon(Icons.share)),
                backToIdle: Duration.zero,
                key: buttonState),
          ],
        ),
        SliverConstraintsBoxView(
          padding: WidgetConstant.padding20,
          sliver: SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: WidgetConstant.border8,
              child: Center(
                child: SizedBox(
                  width: 500,
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: opacity,
                        duration: APPConst.animationDuraion,
                        child: QrImageView(
                          data: widget.data,
                          backgroundColor: Colors.white,
                          embeddedImage: AssetImage(APPConst.logo.uri),
                          errorStateBuilder: (context, error) => WidgetConstant.errorIcon,
                          eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.circle, color: Colors.black),
                          dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Colors.black),
                        ),
                      ),
                      Positioned.fill(
                        child: APPAnimatedSwitcher(enable: show, widgets: {
                          true: (context) => WidgetConstant.sizedBox,
                          false: (context) => FilledButton.icon(
                              onPressed: showContent,
                              icon: const Icon(Icons.remove_red_eye),
                              label: Text("show_barcode".tr))
                        }),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BarcodeImageIconView extends StatelessWidget {
  const BarcodeImageIconView(
      {required this.data,
      this.color,
      super.key,
      this.isSensitive = false,
      this.title,
      this.shareTitle,
      this.name});
  final String data;
  final Color? color;
  final bool isSensitive;
  final String? title;
  final String? shareTitle;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        color: color,
        tooltip: "show_barcode".tr,
        onPressed: () {
          context.openDialogPage(
            '',
            child: (context) => BarcodeImageView(
                data: data,
                isSensitive: isSensitive,
                shareTitle: shareTitle,
                name: name,
                title: title),
            maxWidth: 500,
          );
        },
        icon: Icon(Icons.qr_code_2));
  }
}
