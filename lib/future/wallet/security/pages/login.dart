import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

typedef ONSUCCESSWALLETACCESS<RESPONSE extends WalletCredentialResponse> = FutureOr<void>
    Function(RESPONSE credential);

class WalletLoginView<RESPONSE extends WalletCredentialResponse,
    REQUEST extends WalletCredential<RESPONSE>> extends StatefulWidget {
  const WalletLoginView(
      {required this.request,
      required this.onWalletAccess,
      this.controller,
      this.appBar,
      super.key,
      this.subtitle});
  final ONSUCCESSWALLETACCESS<RESPONSE> onWalletAccess;
  final REQUEST request;
  final Widget? subtitle;
  final AppBar? appBar;
  final ScrollController? controller;

  @override
  State<WalletLoginView<RESPONSE, REQUEST>> createState() =>
      _WalletLoginViewState<RESPONSE, REQUEST>();
}

class _WalletLoginViewState<RESPONSE extends WalletCredentialResponse,
        REQUEST extends WalletCredential<RESPONSE>>
    extends State<WalletLoginView<RESPONSE, REQUEST>>
    with SafeState<WalletLoginView<RESPONSE, REQUEST>> {
  late final WalletProvider walletProvider;
  // late final MainWallet wallet;
  bool platformCredential = false;
  String _entredPassword = "";
  final GlobalKey<FormState> form = GlobalKey<FormState>(debugLabel: "ExportSeedView");
  final GlobalKey<StreamWidgetState> progressKey =
      GlobalKey<StreamWidgetState>(debugLabel: "ExportSeedView");
  final GlobalKey<AppTextFieldState> textFildState =
      GlobalKey<AppTextFieldState>(debugLabel: "AppTextFieldState");

  RESPONSE? credentials;
  String? error;

  String? psaswordForm(String? v) {
    if (v == null || v.isEmpty) return "invalid_password".tr;
    return null;
  }

  void onChange(String v) {
    _entredPassword = v;
    if (error != null) {
      error = null;
      updateState();
    }
  }

  Future<void> onSubmit({bool usePlatformCredential = false}) async {
    if (!usePlatformCredential && !form.ready()) return;
    if (error != null) {
      error = null;
      updateState();
    }
    await getCredential(usePlatformCredential: usePlatformCredential);
  }

  Future<void> getCredential(
      {bool firstTry = false, bool usePlatformCredential = false}) async {
    if (closed) return;
    if (firstTry) {
      if (!platformCredential || walletProvider.wallet.hasWalletKey) return;
    }
    if (!mounted) return;
    String? password = textFildState.currentState?.getValue().nullOnEmpty;
    progressKey.process();
    try {
      final request = WalletActionAccess(
          request: WalletCredentialRequest(
              credential: widget.request,
              password: usePlatformCredential ? null : password,
              platformCredential: platformCredential));

      final result = await walletProvider.wallet.doAction(request);
      if (result.isErr) {
        error = result.unwrapErr().localizationError;
        progressKey.error();
      } else {
        final r = await IResult.call(() async {
          return widget.onWalletAccess.call(result.unwrap());
        });
        if (r.isErr) {
          error = result.unwrapErr().localizationError;
          progressKey.error();
          return;
        }
        credentials = result.unwrap();
        progressKey.success();
      }
    } finally {
      updateState();
    }
  }

  void init() {
    walletProvider = context.wallet;
    if (walletProvider.wallet.isSetup) return;
    final wallet = walletProvider.wallet.wallet;
    platformCredential = walletProvider.wallet.hasWalletKey &&
        widget.request.type.allowPlatformCredential &&
        wallet.platformCredential != null;
    MethodUtils.executeAfterDelay(() => getCredential(firstTry: true),
        duration: APPConst.animationDuraion);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: Center(
        child: CustomScrollView(
          controller: widget.controller,
          shrinkWrap: true,
          slivers: [
            SliverConstraintsBoxView(
                padding: WidgetConstant.padding20,
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConditionalWidget(
                          enable: widget.subtitle != null,
                          onActive: (context) => widget.subtitle!,
                          onDeactive: (context) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.security,
                                        size: APPConst.double80,
                                        color: context.colors.green)
                                  ],
                                ),
                                WidgetConstant.height8,
                              ]),
                        ),
                        AppTextField(
                            label: "wallet_password".tr,
                            obscureText: true,
                            key: textFildState,
                            validator: psaswordForm,
                            initialValue: _entredPassword,
                            onChanged: onChange,
                            error: error,
                            suffixIcon: Row(
                              children: [
                                ConditionalWidget(
                                    enable: platformCredential,
                                    onActive: (context) => IconButton(
                                        onPressed: () {
                                          onSubmit(usePlatformCredential: true);
                                        },
                                        icon: Icon(Icons.fingerprint)))
                              ],
                            ),
                            helperText: "enter_wallet_password_to_continue".tr),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ButtonProgress(
                                key: progressKey,
                                initialStatus: StreamWidgetStatus.idle,
                                child: (context) => FixedElevatedButton(
                                      onPressed: onSubmit,
                                      child: Text("unlock".tr),
                                    ),
                                backToIdle: APPConst.milliseconds100,
                                padding: WidgetConstant.paddingVertical20)
                          ],
                        )
                      ],
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
