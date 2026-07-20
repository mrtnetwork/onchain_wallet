import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

Widget get initializeProgressWidget =>
    ProgressWithTextView(text: "initializing_requirements".tr);

class ProgressWithTextView extends StatelessWidget {
  const ProgressWithTextView(
      {super.key,
      required this.text,
      this.progressBar,
      this.icon,
      this.style,
      this.bottomWidget});
  final String text;
  final Widget? icon;
  final TextStyle? style;
  final Widget? bottomWidget;
  final LivePercentProgressBar? progressBar;

  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        progressBar: progressBar,
        text: Column(
          children: [
            LargeTextView([text], maxLine: 3, textAligen: TextAlign.center, style: style),
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
              child:
                  LargeTextContainer(color: context.colors.onErrorContainer, text: text),
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
  State<SuccessBarcodeProgressView> createState() => _SuccessBarcodeProgressViewState();
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
                showButtonTitle: widget.secureButtonText?.tr ?? "show_content".tr,
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
      : assert(
            text != null || buttonWidget != null, "use text or buttonWidget for child");
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
  const _ProgressWithTextView({this.progressBar, required this.text, this.icon});
  final Widget text;
  final Widget? icon;
  final LivePercentProgressBar? progressBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConditionalWidget(
          enable: icon != null,
          onActive: (context) => icon!,
          onDeactive: (context) {
            if (progressBar != null) {
              return APPStreamBuilder(
                value: progressBar!.progress,
                builder: (context, value) {
                  return Column(
                    children: [
                      LinearProgressIndicator(value: value),
                      WidgetConstant.height8,
                    ],
                  );
                },
              );
            }

            return const CircularProgressIndicator();
          },
        ),
        WidgetConstant.height8,
        text,
      ],
    );
  }
}

class TrackTransactionStatusView extends StatelessWidget {
  final String txId;
  final Chain account;
  final ChainTransaction? transaction;
  final WidgetContext? onTxSuccess;
  const TrackTransactionStatusView({
    super.key,
    required this.account,
    required this.txId,
    required this.transaction,
    this.onTxSuccess,
  });
  @override
  Widget build(BuildContext context) {
    final txUrl = account.network.getTransactionExplorer(txId);

    return ChainStreamBuilder(
        debugName: "SuccessTransactionTextView",
        allowNotify: [DefaultChainNotify.transaction],
        builder: (context, _) {
          final status = transaction?.status;
          final bool inBlock = status == WalletTransactionStatus.block;
          return Shimmer(
              ignoring: false,
              onActive: (_, context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContainerWithBorder(
                        enableTap: false,
                        onRemove: () {},
                        onRemoveWidget: Row(mainAxisSize: MainAxisSize.min, children: [
                          ConditionalWidget(
                              enable: txUrl != null,
                              onActive: (context) => IconButton(
                                    icon: Icon(Icons.open_in_new,
                                        color: context.colors.onPrimaryContainer),
                                    color: context.colors.onPrimaryContainer,
                                    onPressed: () {
                                      final url = txUrl;
                                      if (url != null) {
                                        context.appContext.platformUtls.lunchUri(url);
                                      }
                                    },
                                  )),
                          ConditionalWidgets<WalletTransactionStatus>(
                              enable: status,
                              widgets: {
                                null: (context) => Icon(Icons.check_circle),
                                WalletTransactionStatus.block: (context) =>
                                    TappedTooltipView(
                                        tooltipWidget: ToolTipView(
                                            message: "transaction_confirmed_in_block".tr,
                                            child: Icon(Icons.check_circle,
                                                color: context.onPrimaryContainer))),
                                WalletTransactionStatus.failed: (context) =>
                                    TappedTooltipView(
                                        tooltipWidget: ToolTipView(
                                            message: "transaction_submission_failed".tr,
                                            child: Icon(Icons.error,
                                                color: context.onPrimaryContainer))),
                                WalletTransactionStatus.unknown: (context) =>
                                    TappedTooltipView(
                                        tooltipWidget: ToolTipView(
                                            message: "unable_to_confirm_transaction".tr,
                                            child: Icon(Icons.warning,
                                                color: context.onPrimaryContainer))),
                              })
                        ]),
                        child: CopyableTextWidget(
                            text: txId, color: context.onPrimaryContainer),
                      ),
                      ConditionalWidget(
                        onActive: (context) => onTxSuccess!(context),
                        enable: inBlock && onTxSuccess != null,
                      )
                    ],
                  ),
              enable: status != WalletTransactionStatus.pending);
        },
        account: account);
  }
}

class SuccessTransactionTextView extends StatelessWidget {
  const SuccessTransactionTextView(
      {super.key,
      required this.txId,
      required this.account,
      this.address,
      this.transaction,
      this.additionalWidget,
      this.warning});
  final String txId;
  final ChainTransaction? transaction;
  final WidgetContext? additionalWidget;
  final String? warning;
  final Chain account;

  final ChainAccount? address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleTokenImageView(account.network.coinParam.token, radius: APPConst.double80),
        Text(account.network.coinParam.token.name, style: context.textTheme.labelLarge),
        ConditionalWidget(
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WidgetConstant.height20,
            ContainerWithBorder(
              onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
              child: AddressDetailsView(
                address: address!,
                color: context.onPrimaryContainer,
                chain: account,
              ),
            ),
          ]),
          enable: address != null,
        ),
        WidgetConstant.height20,
        TrackTransactionStatusView(
          account: account,
          txId: txId,
          transaction: transaction,
        ),
        WidgetConstant.height20,
        if (additionalWidget != null) additionalWidget!(context),
        AlertTextContainer(message: warning),
      ],
    );
  }
}

enum ProgressMultipleTextViewStatus { error, success }

abstract class ProgressTxStatusView {
  final ProgressMultipleTextViewStatus status;
  final String message;
  const ProgressTxStatusView({required this.status, required this.message});
  bool get isSuccess => status == ProgressMultipleTextViewStatus.success;
}

class ProgressTxStatusSuccessView extends ProgressTxStatusView {
  final String? warning;
  final bool enableCopy;
  final String? openUrl;
  final ChainTransaction? transaction;

  const ProgressTxStatusSuccessView._(
      {required super.status,
      required super.message,
      required this.enableCopy,
      required this.transaction,
      this.warning,
      this.openUrl});
  factory ProgressTxStatusSuccessView({
    required String txId,
    required ChainTransaction? transaction,
    String? warning,
    String? openUrl,
    bool enableCopy = true,
  }) {
    return ProgressTxStatusSuccessView._(
        status: ProgressMultipleTextViewStatus.success,
        transaction: transaction,
        message: txId,
        enableCopy: enableCopy,
        warning: warning,
        openUrl: openUrl);
  }
}

class ProgressTxStatusErrorView extends ProgressTxStatusView {
  const ProgressTxStatusErrorView({
    required super.message,
  }) : super(status: ProgressMultipleTextViewStatus.error);
}

class ProgressMultipleTextView extends StatelessWidget {
  const ProgressMultipleTextView(
      {super.key,
      required this.texts,
      required this.account,
      required this.logo,
      this.title});
  final List<ProgressTxStatusView> texts;
  final APPImage? logo;
  final String? title;
  final Chain account;

  @override
  Widget build(BuildContext context) {
    return ChainStreamBuilder(
      account: account,
      allowNotify: [DefaultChainNotify.transaction],
      builder: (context, _) => Center(
        child: SingleChildScrollView(
          child: ConstraintsBoxView(
            padding: WidgetConstant.paddingHorizontal20,
            child: Column(
              children: [
                CircleAPPImageView(logo, radius: APPConst.double80),
                if (title != null) Text(title!, style: context.textTheme.labelLarge),
                WidgetConstant.height20,
                ListView.separated(
                    physics: WidgetConstant.noScrollPhysics,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final tx = texts[index];
                      if (tx.isSuccess) {
                        final sucessTx = tx as ProgressTxStatusSuccessView;
                        final status = sucessTx.transaction?.status;
                        return Shimmer(
                            ignoring: false,
                            onActive: (_, context) => ContainerWithBorder(
                                enableTap: false,
                                onRemove: () {},
                                onRemoveWidget:
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                  ConditionalWidget(
                                      enable: tx.openUrl != null,
                                      onActive: (context) => IconButton(
                                            icon: Icon(Icons.open_in_new,
                                                color: context.colors.onPrimaryContainer),
                                            color: context.colors.onPrimaryContainer,
                                            onPressed: () {
                                              final url = tx.openUrl;
                                              if (url != null) {
                                                context.appContext.platformUtls
                                                    .lunchUri(url);
                                              }
                                            },
                                          )),
                                  ConditionalWidgets<
                                      WalletTransactionStatus>(enable: status, widgets: {
                                    null: (context) => Icon(Icons.check_circle,
                                        color: context.onPrimaryContainer),
                                    WalletTransactionStatus.block: (context) =>
                                        TappedTooltipView(
                                            tooltipWidget: ToolTipView(
                                                message:
                                                    "transaction_confirmed_in_block".tr,
                                                child: Icon(Icons.check_circle,
                                                    color: context.onPrimaryContainer))),
                                    WalletTransactionStatus.failed: (context) =>
                                        TappedTooltipView(
                                            tooltipWidget: ToolTipView(
                                                message:
                                                    "transaction_submission_failed".tr,
                                                child: Icon(Icons.error,
                                                    color: context.onPrimaryContainer))),
                                    WalletTransactionStatus.unknown: (context) =>
                                        TappedTooltipView(
                                            tooltipWidget: ToolTipView(
                                                message:
                                                    "unable_to_confirm_transaction".tr,
                                                child: Icon(Icons.warning,
                                                    color: context.onPrimaryContainer))),
                                  })
                                ]),
                                child: CopyableTextWidget(
                                    text: tx.message, color: context.onPrimaryContainer)),
                            enable: !(status?.inMempool ?? false));
                      }
                      return ContainerWithBorder(
                        enableTap: false,
                        backgroundColor: context.colors.errorContainer,
                        onRemove: () {},
                        child: LargeTextContainer(
                            color: context.colors.onErrorContainer,
                            text: tx.message,
                            copyable: true),
                      );
                    },
                    separatorBuilder: (context, index) => WidgetConstant.divider,
                    itemCount: texts.length),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StreamPageProgressErrorView extends StatelessWidget {
  const StreamPageProgressErrorView(
      {super.key,
      required this.text,
      this.onTapBackButton,
      this.controller,
      this.progressBar});
  final String text;
  final StreamPageProgressController? controller;
  final DynamicVoid? onTapBackButton;
  final LivePercentProgressBar? progressBar;

  @override
  Widget build(BuildContext context) {
    return _ProgressWithTextView(
        text: Column(
          children: [
            ContainerWithBorder(
              backgroundColor: context.colors.errorContainer,
              child:
                  LargeTextContainer(color: context.colors.onErrorContainer, text: text),
            ),
            if (controller != null) ...[
              WidgetConstant.height20,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                      onPressed: () {
                        controller?.backToIdle();
                        if (onTapBackButton != null) onTapBackButton!();
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
