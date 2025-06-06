import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

Widget get initializeProgressWidget =>
    ProgressWithTextView(text: "initializing_requirements".tr);

class ProgressWithTextView extends StatelessWidget {
  const ProgressWithTextView(
      {super.key,
      required this.text,
      this.icon,
      this.style,
      this.bottomWidget});
  final String text;
  final Widget? icon;
  final TextStyle? style;
  final Widget? bottomWidget;

  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        text: Column(
          children: [
            LargeTextView([text],
                maxLine: 3, textAligen: TextAlign.center, style: style),
            if (bottomWidget != null) bottomWidget!
          ],
        ),
        icon: icon);
  }
}

class ProgressWithAPPLogo extends StatelessWidget {
  const ProgressWithAPPLogo({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAssetsImageView(APPConst.logo, radius: 120),
        WidgetConstant.height8,
        const CircularProgressIndicator()
      ],
    );
  }
}

class ErrorWithTextView extends StatelessWidget {
  const ErrorWithTextView({super.key, required this.text, this.progressKey});
  final String text;
  final GlobalKey<PageProgressBaseState>? progressKey;

  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        text: Column(
          children: [
            ContainerWithBorder(
              backgroundColor: context.colors.errorContainer,
              child: LargeTextContainer(
                  color: context.colors.onErrorContainer, text: text),
            ),
            if (progressKey != null) ...[
              WidgetConstant.height20,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                      onPressed: () {
                        progressKey?.backToIdle();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: Text("back_to_the_page".tr))
                ],
              )
            ],
          ],
        ),
        icon: WidgetConstant.errorIconLarge);
  }
}

class SuccessWithTextView extends StatelessWidget {
  const SuccessWithTextView({super.key, required this.text, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        text: Text(text, textAlign: TextAlign.center),
        icon: icon != null
            ? Icon(icon, size: APPConst.double80)
            : WidgetConstant.checkCircleLarge);
  }
}

class SuccessBarcodeProgressView extends StatefulWidget {
  const SuccessBarcodeProgressView(
      {super.key,
      required this.text,
      required this.bottomWidget,
      this.secure = false,
      this.secureButtonText});
  final String text;
  final Widget bottomWidget;
  final bool secure;
  final String? secureButtonText;

  @override
  State<SuccessBarcodeProgressView> createState() =>
      _SuccessBarcodeProgressViewState();
}

class _SuccessBarcodeProgressViewState extends State<SuccessBarcodeProgressView>
    with SafeState {
  late bool isSecure = widget.secure;
  void onShowContent() {
    isSecure = !isSecure;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        text: Column(
          children: [
            SecureContentView(
                isSensitive: isSecure,
                showButtonTitle:
                    widget.secureButtonText?.tr ?? "show_content".tr,
                content: widget.text),
            WidgetConstant.height8,
            widget.bottomWidget
          ],
        ),
        icon: WidgetConstant.checkCircleLarge);
  }
}

class SuccessWithButtonView extends StatelessWidget {
  const SuccessWithButtonView(
      {super.key,
      this.text,
      required this.buttonText,
      this.buttonWidget,
      required this.onPressed})
      : assert(text != null || buttonWidget != null,
            "use text or buttonWidget for child");
  final String? text;
  final String buttonText;
  final Widget? buttonWidget;
  final DynamicVoid onPressed;

  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        text: Column(
          children: [
            buttonWidget ?? Text(text!, textAlign: TextAlign.center),
            WidgetConstant.height8,
            FilledButton(onPressed: onPressed, child: Text(buttonText))
          ],
        ),
        icon: WidgetConstant.checkCircleLarge);
  }
}

class _ProgressWithTextView extends StatelessWidget {
  const _ProgressWithTextView({required this.text, this.icon});
  final Widget text;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon ?? const CircularProgressIndicator(),
        WidgetConstant.height8,
        text,
      ],
    );
  }
}

class SuccessTransactionTextView extends StatelessWidget {
  const SuccessTransactionTextView(
      {super.key,
      required this.txIds,
      required this.network,
      this.additionalWidget,
      this.error});
  final List<String> txIds;
  final WalletNetwork network;
  final WidgetContext? additionalWidget;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Widget successTrText = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleTokenImageView(network.coinParam.token,
            radius: APPConst.double80),
        Text(network.coinParam.token.name, style: context.textTheme.labelLarge),
        WidgetConstant.height20,
        ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final id = txIds[index];
              final txUrl = network.getTransactionExplorer(id);
              return ContainerWithBorder(
                  child: Row(
                children: [
                  Expanded(
                    child: CopyableTextWidget(
                        isSensitive: false,
                        text: txIds[index],
                        color: context.onPrimaryContainer),
                  ),
                  if (txUrl != null)
                    IconButton(
                        onPressed: () {
                          UriUtils.lunch(txUrl);
                        },
                        icon: Icon(Icons.open_in_new,
                            color: context.colors.onPrimaryContainer))
                ],
              ));
            },
            separatorBuilder: (context, index) => WidgetConstant.divider,
            itemCount: txIds.length),
        WidgetConstant.height20,
        if (additionalWidget != null) additionalWidget!(context),
        ErrorTextContainer(error: error),
      ],
    );

    return _ProgressWithTextView(
        text: successTrText, icon: WidgetConstant.sizedBox);
  }
}

enum ProgressMultipleTextViewStatus { error, success }

class ProgressMultipleTextViewObject {
  final ProgressMultipleTextViewStatus status;
  final String text;
  final bool enableCopy;
  final String? openUrl;
  bool get isSuccess => status == ProgressMultipleTextViewStatus.success;
  const ProgressMultipleTextViewObject(
      {required this.status,
      required this.text,
      required this.enableCopy,
      this.openUrl});
  factory ProgressMultipleTextViewObject.success({
    required String message,
    String? openUrl,
    bool enableCopy = true,
  }) {
    return ProgressMultipleTextViewObject(
        status: ProgressMultipleTextViewStatus.success,
        text: message,
        enableCopy: enableCopy,
        openUrl: openUrl);
  }
  factory ProgressMultipleTextViewObject.error(
      {required String message, bool enableCopy = false}) {
    return ProgressMultipleTextViewObject(
        status: ProgressMultipleTextViewStatus.error,
        text: message,
        enableCopy: enableCopy);
  }
}

class ProgressMultipleTextView extends StatelessWidget {
  const ProgressMultipleTextView(
      {super.key, required this.texts, required this.logo, this.title});
  final List<ProgressMultipleTextViewObject> texts;
  final APPImage? logo;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstraintsBoxView(
          padding: WidgetConstant.paddingHorizontal20,
          child: Column(
            children: [
              CircleAPPImageView(logo, radius: APPConst.double80),
              if (title != null)
                Text(title!, style: context.textTheme.labelLarge),
              WidgetConstant.height20,
              ListView.separated(
                  physics: WidgetConstant.noScrollPhysics,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final txt = texts[index];
                    return ContainerWithBorder(
                        enableTap: false,
                        onRemove: () {},
                        onRemoveIcon: txt.isSuccess
                            ? IconButton(
                                icon: txt.openUrl != null
                                    ? Icon(Icons.open_in_new,
                                        color:
                                            context.colors.onPrimaryContainer)
                                    : Icon(Icons.check_circle,
                                        color:
                                            context.colors.onPrimaryContainer),
                                color: context.colors.onPrimaryContainer,
                                onPressed: () {
                                  if (txt.openUrl != null) {
                                    UriUtils.lunch(txt.openUrl);
                                  }
                                },
                              )
                            : Icon(Icons.error, color: context.colors.error),
                        child: txt.enableCopy
                            ? CopyTextIcon(
                                isSensitive: false,
                                dataToCopy: txt.text,
                                widget: Text(
                                  txt.text,
                                  maxLines: 2,
                                  style: context.onPrimaryTextTheme.bodyMedium,
                                ))
                            : Text(
                                txt.text,
                                maxLines: 2,
                                style: context.onPrimaryTextTheme.bodyMedium,
                              ));
                  },
                  separatorBuilder: (context, index) => WidgetConstant.divider,
                  itemCount: texts.length),
            ],
          ),
        ),
      ),
    );
  }
}

class Web3SuccessTransactionTextView extends StatelessWidget {
  const Web3SuccessTransactionTextView(
      {super.key,
      required this.txIds,
      required this.network,
      this.additionalWidget,
      this.error});
  final List<String> txIds;
  final WalletNetwork network;
  final WidgetContext? additionalWidget;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstraintsBoxView(
          padding: WidgetConstant.paddingHorizontal20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleTokenImageView(network.coinParam.token,
                  radius: APPConst.double80),
              Text(network.coinParam.token.name,
                  style: context.textTheme.labelLarge),
              WidgetConstant.height20,
              ListView.separated(
                  shrinkWrap: true,
                  physics: WidgetConstant.noScrollPhysics,
                  itemBuilder: (context, index) {
                    final id = txIds[index];
                    final txUrl = network.getTransactionExplorer(id);
                    return ContainerWithBorder(
                        child: Row(
                      children: [
                        Expanded(
                          child: CopyableTextWidget(
                              isSensitive: false,
                              text: txIds[index],
                              color: context.onPrimaryContainer),
                        ),
                        if (txUrl != null)
                          IconButton(
                              onPressed: () {
                                UriUtils.lunch(txUrl);
                              },
                              icon: Icon(Icons.open_in_new,
                                  color: context.colors.onPrimaryContainer))
                      ],
                    ));
                  },
                  separatorBuilder: (context, index) => WidgetConstant.divider,
                  itemCount: txIds.length),
              WidgetConstant.height20,
              if (additionalWidget != null) additionalWidget!(context),
              ErrorTextContainer(error: error),
            ],
          ),
        ),
      ),
    );

    // return _ProgressWithTextView(
    //     text: successTrText, icon: WidgetConstant.sizedBox);
  }
}
