import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class GenerateBackupView extends StatefulWidget {
  const GenerateBackupView(
      {super.key,
      required this.data,
      required this.credential,
      required this.type,
      this.walletBackupOptions,
      this.descriptions = const []});
  final String data;
  final WalletCredentialResponseVerify credential;
  final List<Widget> descriptions;
  final WalletBackupTypes type;
  final GenerateWalletBackupOptions? walletBackupOptions;

  @override
  State<GenerateBackupView> createState() => _SecureBackupViewState();
}

class _SecureBackupViewState extends State<GenerateBackupView>
    with SafeState<GenerateBackupView>, ProgressMixin<GenerateBackupView> {
  bool get canUseKeyStore => widget.type == WalletBackupTypes.privatekey;

  bool useKeyStore = false;

  void onChangeUseKeystore(bool? _) {
    useKeyStore = !useKeyStore;
    updateState();
  }

  String? backup;
  String? viewText;
  void createBackup() async {
    final wallet = context.wallet;
    progressKey.progressText("creating_backup_desc".tr);
    final IResult<String> result;
    if (widget.type == WalletBackupTypes.walletV3) {
      final options = widget.walletBackupOptions;
      if (options == null) {
        progressKey.errorText("invalid_backup_options".tr, backToIdle: false);
        return;
      }
      result = await wallet.wallet.doAction(
          WalletActionWalletBackup(credential: widget.credential, options: options));
    } else {
      result = await wallet.wallet.doAction(WalletActionKeyBackup(
          data: widget.data,
          backupType: useKeyStore ? WalletBackupTypes.keystore : widget.type,
          credential: widget.credential));
    }
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else {
      backup = result.unwrap();
      viewText = backup!.substring(0, IntUtils.min(200, backup!.length));
      progressKey.success();
    }
  }

  final GlobalKey<StreamWidgetState> shareState = GlobalKey();
  final GlobalKey<StreamWidgetState> saveState = GlobalKey();

  Future<void> share() async {
    final backup = this.backup;
    if (backup == null) return;

    shareState.process();
    final name = "credentials_${StrUtils.toFileName(DateTime.now())}";
    final result = await context.appContext.platformUtls.shareFile(
      buffer: IBuffer.string(backup),
      name: name,
      type: AppFileType.txt,
      subject: "account credentials",
    );

    result.watch(
      onErr: (error) {
        shareState.error();
      },
      onOk: (value) {
        shareState.success();
      },
    );
  }

  Future<void> save() async {
    final backup = this.backup;
    if (backup == null) return;
    saveState.process();
    final name = "credentials_${StrUtils.toFileName(DateTime.now())}";
    final result = await context.appContext.platformUtls
        .saveFile(buffer: IBuffer.string(backup), name: name, type: AppFileType.txt);
    result.watch(
      onErr: (error) {
        saveState.error();
        context.showAlert("file_save_failed".tr);
      },
      onOk: (value) {
        saveState.success();
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageTitleSubtitle(
            title: "b_using_web3_secret_defination".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextAndLinkView(
                  text: "about_web3_secret_defination".tr,
                  url: LinkConst.aboutWeb3StorageDefination,
                ),
                WidgetConstant.height8,
                Text("backup_desc2".tr),
                WidgetConstant.height8,
                APPAnimatedSwitcher(enable: useKeyStore, widgets: {
                  true: (c) => Text("use_key_store_backup_desc".tr),
                  false: (c) => ErrorTextContainer(
                      error: "backup_encoding_desc".tr, enableTap: false),
                }),
                if (widget.descriptions.isNotEmpty) ...[
                  WidgetConstant.height8,
                  ...widget.descriptions
                ]
              ],
            )),
        StreamPageProgress(
            controller: progressKey,
            builder: (c) => backup == null
                ? Column(
                    children: [
                      if (canUseKeyStore)
                        AppCheckListTile(
                          title: Text("generate_keystore".tr),
                          subtitle: Text("generate_keystore_desc".tr),
                          value: useKeyStore,
                          onChanged: onChangeUseKeystore,
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FixedElevatedButton(
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: createBackup,
                            child: Text("create_backup".tr),
                          )
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      ContainerWithBorder(
                        child: CopyableTextWidget(
                          text: backup!,
                          widget: OneLineTextWidget(viewText!, maxLine: 2),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ButtonProgress(
                            child: (context) => IconButton(
                              onPressed: share,
                              icon: const Icon(Icons.share),
                            ),
                            backToIdle: APPConst.oneSecoundDuration,
                            key: shareState,
                          ),
                          WidgetConstant.width8,
                          ButtonProgress(
                              child: (context) => IconButton(
                                    onPressed: save,
                                    icon: const Icon(Icons.save),
                                  ),
                              backToIdle: APPConst.oneSecoundDuration,
                              key: saveState),
                        ],
                      ),
                    ],
                  ))
      ],
    );
  }
}
