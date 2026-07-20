import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';

class ParingMainWalletView extends StatelessWidget {
  const ParingMainWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseCredential,
            WalletCredentialPasswordRequire>(
        request:
            WalletCredentialPasswordRequire(type: WalletCredentialType.pairingWallet),
        onAccsess: (credential) {
          return _ParingMainWalletView(credential.id);
        },
        title: "backup".tr,
        subtitle: PageTitleSubtitle(
            title: "backup_wallet".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("backup_wallet_desc".tr),
                WidgetConstant.height8,
                Text("enter_wallet_password_to_continue".tr),
              ],
            )));
  }
}

class _ParingMainWalletView extends StatefulWidget {
  final WalletCredentialResponseVerify credential;
  const _ParingMainWalletView(this.credential);

  @override
  State<_ParingMainWalletView> createState() => __ParingMainWalletViewState();
}

class __ParingMainWalletViewState extends State<_ParingMainWalletView>
    with SafeState<_ParingMainWalletView> {
  late final _NewPairingClient controller;

  @override
  void onInitOnce() {
    super.onInitOnce();
    controller = _NewPairingClient(wallet: context.wallet, credential: widget.credential);
    controller.pair();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamPageProgress(
        controller: controller.pageController,
        builder: (context) => APPStreamBuilder(
          value: controller.notifier,
          builder: (context, _) => Column(
            children: [
              ContainerWithBorder(
                child: CopyableTextWidget(text: controller.pairUrl ?? "Connection :D"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPairingClient with DisposableMixin, StreamStateController {
  final WalletProvider wallet;
  _NewPairingClient({required this.wallet, required this.credential});
  final StreamPageProgressController pageController = StreamPageProgressController();
  // final client = BridgeClientOnChainPairing(BridgeClientDefault((String topic) async {
  //   return null;
  // }));
  final WalletCredentialResponseVerify credential;
  String? pairUrl;

  Future<void> pair() async {
    // final result = await client.walletPairing(
    //   onPiringUri: (uri) {
    //     pairUrl = uri.toString();
    //     notify();
    //   },
    //   onSessionPropose: (proposal) async {
    //     return await wallet.wallet.doAction(
    //         WalletActionWalletExternalBackup(key: proposal.key, credential: credential));
    //   },
    //   onVerifyPairing: (WCMActionRequestVerifyPair p1, session) async {
    //     pageController.progressText("pairing_wallet_desc".tr);
    //     final result = await wallet.wallet.doAction(WalletActionImportExternalWallet(
    //         key: session.symKey,
    //         credential: credential,
    //         checksum: p1.checksum,
    //         clientId: p1.clientId));
    //     if (result.isErr) {
    //       pageController.errorText(result.unwrapErr().localizationError,
    //           backToIdle: false, showBackButton: false);
    //       return result;
    //     }
    //     pageController.successText("pairing_complete_successfully".tr, backToIdle: false);
    //     return result;
    //   },
    // );
    // if (result.isErr) {
    //   pageController.errorText(result.unwrapErr().localizationError, backToIdle: false);
    // }
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }
}
