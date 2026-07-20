import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/restore_backup.dart';
import 'package:on_chain_wallet/future/wallet/setup/controller/form.dart';
import 'package:on_chain_wallet/future/wallet/setup/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';

class ExistsMnemonicView extends StatefulWidget {
  const ExistsMnemonicView({super.key});

  @override
  State<ExistsMnemonicView> createState() => _MnemonicViewState();
}

class _MnemonicViewState extends State<ExistsMnemonicView>
    with SafeState<ExistsMnemonicView> {
  StreamSubscription<void>? listener;
  late final ExistsMnemonicStateController controller;

  Future<void> onValidateMnemonic() async {
    await controller.validate((mnemonic) {
      context.pop(mnemonic);
    });
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final allowType = context.getNullArgruments<MnemonicType>();
    controller = ExistsMnemonicStateController(
        walletProvider: context.wallet, allowMnemonicType: allowType);
    listener = controller.stream.listen((v) => updateState());
  }

  @override
  void safeDispose() {
    super.safeDispose();
    listener?.cancel();
    listener = null;
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("setup_mnemonic".tr)),
      body: UnfocusableChild(
        child: SensitiveContent(
          sensitivity: ContentSensitivity.sensitive,
          child: StreamPageProgress(
            controller: controller.pageController,
            builder: (context) => CustomScrollView(
              slivers: [
                SliverConstraintsBoxView(
                    padding: WidgetConstant.padding20,
                    sliver: SliverToBoxAdapter(
                      child: Form(
                        key: controller.formKey,
                        child: APPAnimated(
                          onActive: (context) => Column(
                            key: ValueKey(controller.type),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("type_of_mnemonic".tr,
                                  style: context.textTheme.titleMedium),
                              Text("choose_your_mnemonic_type".tr),
                              WidgetConstant.height8,
                              AppDropDownBottom(
                                  isDense: false,
                                  value: controller.type,
                                  isExpanded: true,
                                  menuItems: MnemonicType.values.map((e) {
                                    final isEnable = controller.isEnabled(e);
                                    return DropdownMenuItem(
                                      value: e,
                                      enabled: isEnable,
                                      child: Opacity(
                                        opacity: isEnable ? 1 : APPConst.disabledOpacity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(e.tr.tr),
                                            Text(e.desc.tr,
                                                style: context.textTheme.bodySmall)
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: controller.onChangeMnemonicType),
                              WidgetConstant.height20,
                              Text("mnemonic".tr, style: context.textTheme.titleMedium),
                              Text("enter_mnemonic_desc".tr),
                              WidgetConstant.height8,
                              AppTextField(
                                key: controller.mnemonicTextFieldKey,
                                label: "enter_mne".tr,
                                validator: controller.onValidateMnemonic,
                                onChanged: controller.onChangeMnemonic,
                                minlines: 3,
                                maxLines: 5,
                                focusNode: controller.nextFocus,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PasteTextIcon(
                                        onPaste: controller.onPasteMnemonic,
                                        isSensitive: true),
                                    BarcodeScannerIconView(controller.onPasteMnemonic,
                                        isSensitive: true),
                                    IconButton(
                                        onPressed: () {
                                          context
                                              .openSliverBottomSheet<String>(
                                                  "restore_backup".tr,
                                                  child: RestoreBackupView(
                                                      accepted:
                                                          WalletBackupTypes.mnemonic))
                                              .then(controller.onPasteMnemonic);
                                        },
                                        icon:
                                            Icon(Icons.settings_backup_restore_outlined))
                                  ],
                                ),
                                initialValue: controller.mnemonic,
                              ),
                              WidgetConstant.height20,
                              ConditionalWidget(
                                enable: controller.type.supportPassPhrase,
                                onActive: (context) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppCheckListTile(
                                          value: controller.usePassphrase,
                                          title: Text("enable_mnemonic_password".tr),
                                          subtitle: Text("mnemonic_passphrase_desc".tr),
                                          onChanged: controller.onChangeUsePassphrase),
                                      APPAnimated(
                                          isActive: controller.usePassphrase,
                                          onActive: (context) => Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    WidgetConstant.height20,
                                                    AppTextField(
                                                      label: "mn_password".tr,
                                                      obscureText: true,
                                                      disableContextMenu: true,
                                                      initialValue: controller.passhrase,
                                                      onChanged:
                                                          controller.onChangePassphrase,
                                                      validator:
                                                          controller.onValidatePassphrase,
                                                    ),
                                                    AppTextField(
                                                        label: "c_password".tr,
                                                        obscureText: true,
                                                        disableContextMenu: true,
                                                        initialValue:
                                                            controller.confirmPassphrase,
                                                        onChanged: controller
                                                            .onChangeConfrimPassphrase,
                                                        focusNode: controller.nextFocus,
                                                        validator: controller
                                                            .onValidateConfirmPassphrase),
                                                  ]))
                                    ]),
                              ),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                FixedElevatedButton(
                                    padding: WidgetConstant.paddingVertical40,
                                    onPressed: onValidateMnemonic,
                                    child: Text("verify".tr))
                              ])
                            ],
                          ),
                        ),
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
