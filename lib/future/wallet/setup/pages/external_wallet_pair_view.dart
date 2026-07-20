import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

/// TODO
/// Implement external wallet pairing
class ExternalWalletParingView extends StatefulWidget {
  const ExternalWalletParingView({super.key});

  @override
  State<ExternalWalletParingView> createState() => _ExternalWalletParingViewState();
}

class _ExternalWalletParingViewState extends State<ExternalWalletParingView>
    with SafeState<ExternalWalletParingView> {
  late final _NewPairingClient controller;

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final password = context.getArgruments<String>();
    controller = _NewPairingClient(wallet: context.wallet, password: password);
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("external_wallet".tr),
      ),
      body: Form(
        key: controller.formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: UnfocusableChild(
          child: StreamPageProgress(
            controller: controller.pageController,
            builder: (context) => CustomScrollView(
              slivers: [
                SliverConstraintsBoxView(
                  padding: WidgetConstant.padding20,
                  sliver: APPStreamBuilder(
                    value: controller.notifier,
                    builder: (context, _) => _PairingView(controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PairingView extends StatelessWidget {
  final _NewPairingClient controller;
  const _PairingView(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Shimmer(
        enable: !controller.inPairing,
        onActive: (_, context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitleSubtitle(
                title: "wallet_pairing".tr, body: Text("wallet_pairing_desc".tr)),
            AppTextField(
              label: "pairing_link".tr,
              pasteIcon: true,
              initialValue: controller.pairingUrl,
              validator: controller.onValidatePairing,
              onChanged: controller.onChangePairUrl,
            ),
            ErrorTextContainer(error: controller.pairingError),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedElevatedButton(
                    padding: WidgetConstant.paddingVertical40,
                    onPressed: controller.pairing,
                    child: Text("connect".tr))
              ],
            )
          ],
        ),
      ),
    );
  }
}

// class _PairingPasswordView extends StatelessWidget {
//   final _PairingController controller;
//   const _PairingPasswordView(this.controller);
//   @override
//   Widget build(BuildContext context) {
//     return SliverToBoxAdapter(
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         PageTitleSubtitle(
//             title: "wallet_pairing".tr,
//             body: Text("validating_main_wallet_content_desc".tr)),
//         Text("password".tr, style: context.textTheme.titleMedium),
//         Text("input_main_wallet_password".tr),
//         WidgetConstant.height8,
//         AppTextField(
//             label: "password".tr,
//             validator: controller.onValidateMainWalletPassword,
//             onChanged: controller.onChangeMainWalletPassword,
//             initialValue: controller.mainWalletPassword,
//             obscureText: true),
//         WidgetConstant.height20,
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             FixedElevatedButton(
//                 onPressed: () {
//                   controller.validateBackup((v) => context.pop(v));
//                 },
//                 child: Text("setup".tr))
//           ],
//         )
//       ]),
//     );
//   }
// }

class _NewPairingClient with DisposableMixin, StreamStateController {
  final WalletProvider wallet;
  final String password;
  _NewPairingClient({required this.wallet, required this.password});
  // final BridgeClientOnChainPairing client =
  //     BridgeClientOnChainPairing(BridgeClientDefault(
  //   (topic) async {
  //     return null;
  //   },
  // ));
  GlobalKey<FormState> formKey = GlobalKey();
  final StreamPageProgressController pageController = StreamPageProgressController();
  bool inPairing = false;
  bool isSuccess = false;
  WCMExternalWalletBackup? backup;
  String pairingUrl = "";
  String? pairingError;

  void onStateUpdated() {
    notify();
  }

  void onChangePairUrl(String v) {
    pairingUrl = v;
  }

  String? onValidatePairing(String? v) {
    final uriData = MethodUtils.fallbackOnException(() {
      final uri = Uri.tryParse(v ?? '');
      if (uri == null) return null;
      return BridgeUtils.wcParseUri(uri);
    }, logOnDebug: false);
    if (uriData == null) {
      return "validate_pairing_id_desc".tr;
    }
    return null;
  }

  Future<void> pairing() async {
    // final connectorId = Uri.tryParse(pairingUrl);
    // if (connectorId == null || inPairing) return;
    // inPairing = true;
    // onStateUpdated();
    // final pairingResult = await client.pair(uri: connectorId);
    // final backup = pairingResult.ok();
    // if (pairingResult.isErr || backup == null) {
    //   pairingError = pairingResult.unwrapErr().localizationError;
    //   inPairing = false;
    //   onStateUpdated();
    //   return;
    // }
    // pageController.progressText("validate_backup_content".tr);
    // final result = await IResult.call(() async {
    //   final decodeBytes = await wallet.wallet.doAction(
    //       WalletActionDecryptExternalWalletBackup(
    //           key: backup.key, backup: backup.backup.key));
    //   if (decodeBytes.isOk) {
    //     return (
    //       backup: backup.backup.decrypt(decodeBytes.unwrap().encodedWallet),
    //       session: decodeBytes.unwrap().session
    //     );
    //   }
    //   if (decodeBytes.isError(WalletExceptionConst.wrongBackupPassword)) {
    //     throw AppException("wrong_wallet_password");
    //   }
    //   throw AppException("invalid_pairing_content");
    // });
    // final backupData = await wallet.wallet.doAction(
    //     WalletActionVerifyExternalWalletBackup(
    //         backup: result.unwrap().backup, password: password, key: backup.key));
    // if (backupData.isErr) {
    //   pageController.errorText(backupData.unwrapErr().localizationError,
    //       backToIdle: false, showBackButton: true);
    //   return;
    // }
    // final session = WCMSession(backupData.unwrap().wallet.connection);
    // client.listenOnSession(session);
    // isSuccess = true;
    // pageController.pop(ExternalWalletData(
    //     backup: backupData.unwrap(), client: client.client, session: session));
  }

  @override
  void dispose() {
    if (!isSuccess) {
      // client.dispose();
    }

    pageController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    // await client.init();
  }
}
