import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/lifecycle/lifecycle.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'login.dart';

typedef ONACCESSCREDENTIALWIDGET<RESPONSE extends WalletCredentialResponse> = Widget
    Function(RESPONSE credential);

class AccessWalletView<RESPONSE extends WalletCredentialResponse,
    REQUEST extends WalletCredential<RESPONSE>> extends StatefulWidget {
  const AccessWalletView(
      {required this.request,
      this.onWalletAccess,
      super.key,
      this.onAccsess,
      this.title,
      this.subtitle,
      this.controller,
      this.backgroundColor,
      this.appbar});
  final ONACCESSCREDENTIALWIDGET<RESPONSE>? onAccsess;
  final ONSUCCESSWALLETACCESS<RESPONSE>? onWalletAccess;
  final REQUEST request;
  final String? title;
  final Widget? subtitle;
  final ScrollController? controller;
  final AppBar? appbar;

  final Color? backgroundColor;

  @override
  State<AccessWalletView<RESPONSE, REQUEST>> createState() =>
      _AccessWalletViewState<RESPONSE, REQUEST>();
}

class _AccessWalletViewState<RESPONSE extends WalletCredentialResponse,
        REQUEST extends WalletCredential<RESPONSE>>
    extends State<AccessWalletView<RESPONSE, REQUEST>>
    with SafeState<AccessWalletView<RESPONSE, REQUEST>> {
  late final WalletProvider walletProvider;
  late final IMainWallet wallet;
  late final bool platformCredential;
  late final AppLifecycle _lifeCycle =
      AppLifecycle(onLostFocus: _onPause, onLostTimeout: const Duration(seconds: 10));
  RESPONSE? credentials;

  void _onPause() {
    if (kDebugMode) return;
    credentials = null;
    context.backToCurrent();
    updateState();
  }

  Future<void> getCredential(RESPONSE credential) async {
    try {
      if (widget.onWalletAccess != null) {
        await widget.onWalletAccess!.call(credential);
        context.pop();
        return;
      }
      credentials = credential;
    } finally {
      updateState();
    }
  }

  void listener(WalletEvent status) {
    if (status.walletStatus != WStatus.unlock) {
      credentials = null;
      context.backToCurrent();
    } else {
      if (widget.onWalletAccess == null &&
          widget.request.type.isLogin &&
          walletProvider.wallet.isUnlock) {
        credentials = WalletCredentialResponseLogin.instance as RESPONSE;
      }
    }

    updateState();
  }

  StreamSubscription<WalletEvent>? _onWalletStatus;
  void init() {
    walletProvider = context.wallet;
    wallet = walletProvider.wallet.wallet;
    platformCredential =
        widget.request.type.allowPlatformCredential && wallet.platformCredential != null;
    _onWalletStatus = walletProvider.wallet.status.stream.listen(listener);
    listener(walletProvider.wallet.status.value);
    switch (widget.request.type) {
      case WalletCredentialType.mnemonic:
      case WalletCredentialType.importedKey:
      case WalletCredentialType.accountKey:
        _lifeCycle.init();
        break;
      default:
    }
  }

  @override
  void safeDispose() {
    super.safeDispose();
    final verificationId = credentials?.verificationId;
    if (verificationId != null) {
      walletProvider.wallet
          .doAction(WalletActionRemoveCredential(credential: verificationId));
    }
    _onWalletStatus?.cancel();
    _onWalletStatus = null;
    _lifeCycle.dispose();
  }

  PreferredSizeWidget? appBar() {
    if (widget.appbar == null && widget.title == null) {
      if (credentials == null) return AppBar(title: Text(widget.title ?? ''));
      return null;
    }
    return widget.appbar ?? AppBar(title: Text(widget.title ?? ''));
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: credentials == null ? null : widget.backgroundColor,
      appBar: appBar(),
      body: UnfocusableChild(
        child: APPAnimatedSwitcher(
          duration: APPConst.animationDuraion,
          enable: credentials != null,
          widgets: {
            true: (c) => widget.onAccsess?.call(credentials!),
            false: (c) => WalletLoginView<RESPONSE, REQUEST>(
                onWalletAccess: getCredential,
                request: widget.request,
                subtitle: widget.subtitle)
          },
        ),
      ),
    );
  }
}
