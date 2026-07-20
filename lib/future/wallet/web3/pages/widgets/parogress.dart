import 'dart:async';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

sealed class Web3RequestStatus with Equality {
  final bool updateble;
  const Web3RequestStatus(this.updateble);
  bool get inProgress => false;

  @override
  List<dynamic> get variables => [];
}

class Web3RequestStatusProgress extends Web3RequestStatus {
  const Web3RequestStatusProgress() : super(true);
  @override
  bool get inProgress => true;
}

class Web3RequestStatusError extends Web3RequestStatus {
  const Web3RequestStatusError() : super(true);
}

class Web3RequestStatusIdle extends Web3RequestStatus {
  const Web3RequestStatusIdle() : super(true);
}

class Web3RequestStatusSuccessResponse extends Web3RequestStatus {
  const Web3RequestStatusSuccessResponse() : super(false);
}

class Web3RequestStatusErrorResponse extends Web3RequestStatus {
  const Web3RequestStatusErrorResponse() : super(false);
}

class Web3RequestStatusSuccessRequest extends Web3RequestStatus {
  const Web3RequestStatusSuccessRequest() : super(false);
}

class Web3RequestStatusErrorRequest extends Web3RequestStatus {
  final bool pageClosed;
  const Web3RequestStatusErrorRequest(this.pageClosed) : super(false);
}

class StreamWeb3PageProgressController extends StreamValue<Web3RequestStatus> {
  final Web3RequestStatus initialStatus;
  StreamWeb3PageProgressController(
      {this.initialStatus = const Web3RequestStatusIdle(),
      this.idleTimeout = APPConst.oneSecoundDuration})
      : super(initialStatus, name: "StreamWeb3PageProgressController");
  final Duration idleTimeout;

  Widget? _responseWidget;

  Widget? getWidget() {
    return _responseWidget;
  }

  void _updateStream(Web3RequestStatus status) {
    value = status;
  }

  void _update({required Web3RequestStatus status, Widget? widget}) {
    if (value.updateble) {
      _responseWidget = widget;
      _updateStream(status);
    }
  }

  void response({String? text, Widget? widget}) {
    _update(
        status: Web3RequestStatusSuccessResponse(),
        widget: widget ??
            PageProgressChildWidget(ProgressWithTextView(
                text: text ?? "request_has_been_processed_successfully".tr,
                icon: WidgetConstant.checkCircleLarge)));
  }

  void responseTx(
      {required List<SubmitTransactionResult> txIds,
      required List<ChainTransaction> transactions,
      required Chain account}) {
    response(
        widget: ProgressMultipleTextView(
            account: account,
            texts: txIds.map((e) {
              if (e.status.isFailed) {
                return ProgressTxStatusErrorView(
                    message: e.cast<SubmitTransactionFailed>().error);
              }
              final txId = e.cast<SubmitTransactionSuccess>();
              return ProgressTxStatusSuccessView(
                  txId: txId.txId,
                  warning: txId.warning,
                  openUrl: account.network.getTransactionExplorer(txId.txId),
                  transaction: transactions.firstWhereOrNull((e) => e.txId == txId.txId));
            }).toList(),
            logo: account.network.token.assetLogo,
            title: account.network.networkName));
  }

  void processs({String? text}) {
    _update(
        status: Web3RequestStatusProgress(),
        widget: PageProgressChildWidget(ProgressWithTextView(text: text ?? "")));
  }

  void error({
    Object? error,
    String? message,
    Duration backToIdle = APPConst.twoSecoundDuration,
    bool showBackButton = false,
  }) {
    _errorResponseFromException(
        status: Web3RequestStatusError(),
        showBackButton: showBackButton,
        backToIdle: backToIdle,
        error: error,
        message: message);
  }

  void errorResponse({Object? error, String? message}) {
    _errorResponseFromException(
        status: Web3RequestStatusErrorResponse(),
        error: error,
        message: message,
        backToIdle: null);
  }

  void _errorResponseFromException(
      {Object? error,
      String? message,
      Duration? backToIdle = APPConst.twoSecoundDuration,
      bool showBackButton = false,
      required Web3RequestStatus status}) {
    showBackButton = showBackButton && status.updateble;
    if (error == WalletExceptionConst.rejectSigning) {
      showBackButton = false;
      backToIdle = APPConst.oneSecoundDuration;
    }
    if (showBackButton) {
      backToIdle = null;
    }
    if (!status.updateble) {
      backToIdle = null;
      showBackButton = false;
    }
    final key = showBackButton ? this : null;

    if (error is APIError) {
      _error(
          backToIdle: backToIdle,
          widget: _Web3ErrorMessageView(error.message.tr, key),
          status: status);
    } else if (error is AppException) {
      _error(
          widget: _Web3ErrorMessageView(null, key, message: error.message.tr),
          backToIdle: backToIdle,
          status: status);
    } else if (error is Web3RequestException) {
      _error(
          backToIdle: backToIdle,
          widget: _Web3ErrorMessageView(error.message, key),
          status: status);
    } else if (error is BlockchainUtilsException) {
      _error(
          backToIdle: backToIdle,
          widget: _Web3ErrorMessageView(error.message, key),
          status: status);
    } else {
      _error(
          widget: _Web3ErrorMessageView(null, key, message: message),
          backToIdle: backToIdle,
          status: status);
    }
  }

  void _error(
      {String? text,
      Widget? widget,
      Duration? backToIdle = APPConst.twoSecoundDuration,
      required Web3RequestStatus status}) {
    _update(
        status: status,
        widget: widget ??
            PageProgressChildWidget(ProgressWithTextView(
                text: text ?? "", icon: WidgetConstant.errorIconLarge)));
    if (backToIdle != null) {
      Future.delayed(backToIdle, () => _update(status: Web3RequestStatusIdle()));
    }
  }

  void closedRequest({String? error, bool pageClosed = false}) {
    if (_responseWidget == null || value.inProgress) {
      _responseWidget = PageProgressChildWidget(ProgressWithTextView(
          text: error?.tr ?? "client_closed_durning_request".tr,
          icon: WidgetConstant.errorIconLarge));
    }

    _updateStream(Web3RequestStatusErrorRequest(pageClosed));
  }

  void successRequest() {
    switch (value) {
      case Web3RequestStatusSuccessResponse():
      case Web3RequestStatusErrorResponse():
        break;
      default:
        if (_responseWidget == null || value.inProgress) {
          _responseWidget = PageProgressChildWidget(ProgressWithTextView(
              text: "web3_response_successfully_desc".tr,
              icon: WidgetConstant.checkCircleLarge));
        }
        break;
    }
    _updateStream(Web3RequestStatusSuccessRequest());
  }

  void idle() {
    _update(status: Web3RequestStatusIdle());
  }

  void setInitialState() {
    _responseWidget = null;
    // silent = initialStatus;
  }
}

class StreamWeb3PageProgress extends StatefulWidget {
  final StreamWeb3PageProgressController controller;
  final FuncWidgetContext builder;

  final Widget? initialWidget;
  const StreamWeb3PageProgress(
      {required this.controller, required this.builder, this.initialWidget, super.key});
  @override
  State<StreamWeb3PageProgress> createState() => _StreamWeb3PageProgressState();
}

class _StreamWeb3PageProgressState extends State<StreamWeb3PageProgress>
    with SafeState<StreamWeb3PageProgress> {
  StreamWeb3PageProgressController get controller => widget.controller;
  StreamSubscription<Web3RequestStatus>? _listener;
  Web3RequestStatus status = Web3RequestStatusIdle();
  Widget? child;
  Widget? currentWidget;
  late WalletProvider wallet;
  SnackbarController? snackbar;

  void onChangeStatus(Web3RequestStatus status) {
    this.status = status;
    currentWidget = controller.getWidget();
    updateState();
    if (status.updateble) return;
    if (status case Web3RequestStatusErrorRequest(:final pageClosed)) {
      if (pageClosed) return;
    }
    context.showSnackbar(
      _buildRequestSnackBar(
        context: context,
        status: controller,
        onHide: () {
          snackbar?.close();
          snackbar = null;
        },
      ),
      onShow: (controller) => snackbar = controller,
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    status = controller.value;
    _listener = controller.stream.listen(onChangeStatus);
    currentWidget = switch (status) {
      Web3RequestStatusProgress() => widget.initialWidget,
      _ => controller.getWidget()
    };
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.setInitialState();
    currentWidget = null;
    child = null;
    _listener?.cancel();
    _listener = null;
    snackbar?.close();
  }

  @override
  Widget build(BuildContext context) {
    return APPAnimatedSwitcher<Web3RequestStatus>(
      duration: APPConst.animationDuraion,
      enable: status,
      widgets: {
        Web3RequestStatusIdle(): (c) => FutureBuilder(
              future: MethodUtils.executeAfterDelay(() async => widget.builder(c)),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      WidgetConstant.errorIcon,
                      Text(snapshot.error?.toString() ?? "")
                    ],
                  );
                }
                if (snapshot.hasData) {
                  child = snapshot.data!;
                }
                return child ?? WidgetConstant.sizedBox;
              },
            ),

        // Web3RequestStatusProgress(): (c) => currentWidget,
        // Web3RequestStatus.error: (c) => currentWidget,
        // Web3RequestStatus.errorResponse: (c) => currentWidget,
        // Web3RequestStatus.successResponse: (c) => currentWidget,
        // Web3RequestStatus.failedRequest: (c) => currentWidget,
        // Web3RequestStatus.successRequest: (c) => currentWidget
      },
      defaultBuilder: (context) => currentWidget,
    );
  }
}

SnackBar _buildRequestSnackBar(
    {required BuildContext context,
    required StreamValue<Web3RequestStatus> status,
    required DynamicVoid onHide}) {
  return SnackBar(
      duration: switch (status.value) {
        Web3RequestStatusSuccessRequest() => APPConst.tenSecoundDuration,
        Web3RequestStatusErrorRequest() => APPConst.tenSecoundDuration,
        _ => const Duration(minutes: 10)
      },
      action: SnackBarAction(label: 'close'.tr, onPressed: onHide),
      content: APPStreamBuilder(
        value: status,
        builder: (context, status) => Row(
          children: [
            switch (status) {
              Web3RequestStatusSuccessResponse() ||
              Web3RequestStatusErrorResponse() =>
                APPCircularProgressIndicator(color: context.colors.onInverseSurface),
              Web3RequestStatusErrorRequest() =>
                Icon(Icons.error, color: context.colors.onInverseSurface),
              _ => Icon(Icons.check_circle, color: context.colors.onInverseSurface)
            },
            WidgetConstant.width8,
            Flexible(
                child: switch (status) {
              Web3RequestStatusSuccessResponse() ||
              Web3RequestStatusErrorResponse() =>
                OneLineTextWidget(
                    maxLine: 2,
                    "web3_sending_response_to_client".tr,
                    style: context.textTheme.labelLarge
                        ?.copyWith(color: context.colors.onInverseSurface)),
              Web3RequestStatusErrorRequest() => OneLineTextWidget(
                  maxLine: 2,
                  "web3_sending_response_error_desc".tr,
                  style: context.textTheme.labelLarge
                      ?.copyWith(color: context.colors.onInverseSurface)),
              _ => OneLineTextWidget(
                  maxLine: 2,
                  "web3_response_successfully_desc".tr,
                  style: context.textTheme.labelLarge
                      ?.copyWith(color: context.colors.onInverseSurface)),
            }),
          ],
        ),
      ));
}

class _Web3ErrorMessageView extends StatelessWidget {
  const _Web3ErrorMessageView(this.error, this.progressKey, {this.message});
  final String? message;
  final String? error;
  final StreamWeb3PageProgressController? progressKey;

  @override
  Widget build(BuildContext context) {
    return PageProgressChildWidget(_Web3ProgressWithTextView(
      progressKey: progressKey,
      text: message ?? "request_error".tr,
      icon: WidgetConstant.errorIconLarge,
      bottomWidget: ErrorTextContainer(error: error, enableTap: false, copyable: true),
    ));
  }
}

class _Web3ProgressWithTextView extends StatelessWidget {
  const _Web3ProgressWithTextView(
      {required this.text, required this.progressKey, this.icon, this.bottomWidget});
  final String text;
  final Widget? icon;
  final Widget? bottomWidget;
  final StreamWeb3PageProgressController? progressKey;

  @override
  Widget build(BuildContext context) {
    final updateble = progressKey?.value.updateble ?? false;
    return _ProgressWithTextView(
        text: Column(
          children: [
            LargeTextView([text], maxLine: 3, textAligen: TextAlign.center),
            if (bottomWidget != null) bottomWidget!,
            if (updateble) ...[
              WidgetConstant.height20,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                      onPressed: () {
                        progressKey?.idle();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: Text("back_to_the_page".tr))
                ],
              )
            ]
          ],
        ),
        icon: icon);
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
      children: [icon ?? const CircularProgressIndicator(), WidgetConstant.height8, text],
    );
  }
}
