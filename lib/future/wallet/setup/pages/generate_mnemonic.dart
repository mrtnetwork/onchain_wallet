import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/setup/controller/form.dart';
import 'package:on_chain_wallet/future/wallet/setup/pages/mnemonic_view.dart';
import 'package:on_chain_wallet/future/wallet/setup/pages/verify_mnemonic.dart';
import 'package:on_chain_wallet/future/wallet/setup/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class SetupMnemonicView extends StatefulWidget {
  const SetupMnemonicView({super.key});

  @override
  State<SetupMnemonicView> createState() => _MnemonicViewState();
}

class _MnemonicViewState extends State<SetupMnemonicView>
    with SafeState<SetupMnemonicView> {
  StreamSubscription<void>? listener;
  late final MnemonicStateController controller;

  @override
  void onInitOnce() {
    super.onInitOnce();
    final allowType = context.getNullArgruments<MnemonicType>();
    controller = MnemonicStateController(
        walletProvider: context.wallet, allowMnemonicType: allowType);
    controller.init();
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
                    sliver: APPSliverAnimatedSwitcher<SetupMnemonicPage>(
                        enable: controller.page,
                        widgets: {
                          SetupMnemonicPage.generate: (context) =>
                              _SetupMnemonicView(controller),
                          SetupMnemonicPage.review: (context) =>
                              _ReviewMnemonic(controller),
                          SetupMnemonicPage.verify: (context) =>
                              _VerifyMnemonic(controller),
                        }))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupMnemonicView extends StatelessWidget {
  final MnemonicStateController controller;
  const _SetupMnemonicView(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Form(
        key: controller.formKey,
        child: APPAnimated(
          onActive: (context) => Column(
            key: ValueKey(controller.type),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("type_of_mnemonic".tr, style: context.textTheme.titleMedium),
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
                            Text(e.desc.tr, style: context.textTheme.bodySmall)
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.onChangeMnemonicType),
              WidgetConstant.height20,
              Text("Language".tr, style: context.textTheme.titleMedium),
              Text("choose_mnemonic_lang_desc".tr),
              WidgetConstant.height8,
              AppDropDownBottom(
                  isDense: false,
                  value: controller.language,
                  isExpanded: true,
                  items: {
                    for (final i in controller.languages) i: Text(i.name),
                  },
                  onChanged: controller.onChangeLanguage),
              WidgetConstant.height20,
              Text("count_of_mnemonic_word".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              AppDropDownBottom(
                  isDense: false,
                  value: controller.wordCounts,
                  isExpanded: true,
                  items: {
                    for (final i in controller.wordsCounts) i: Text(i.name),
                  },
                  onChanged: controller.onChangeWordsNumber),
              WidgetConstant.height20,
              ConditionalWidget(
                enable: controller.type.supportPassPhrase,
                onActive: (context) =>
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppCheckListTile(
                      value: controller.usePassphrase,
                      title: Text("enable_mnemonic_password".tr),
                      subtitle: Text("mnemonic_passphrase_desc".tr),
                      onChanged: controller.onChangeUsePassphrase),
                  APPAnimated(
                      isActive: controller.usePassphrase,
                      onActive: (context) =>
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            WidgetConstant.height20,
                            AppTextField(
                              label: "mn_password".tr,
                              obscureText: true,
                              nextFocus: controller.nextFocus,
                              disableContextMenu: true,
                              initialValue: controller.passhrase,
                              onChanged: controller.onChangePassphrase,
                              validator: controller.onValidatePassphrase,
                            ),
                            AppTextField(
                                label: "c_password".tr,
                                obscureText: true,
                                disableContextMenu: true,
                                initialValue: controller.confirmPassphrase,
                                onChanged: controller.onChangeConfrimPassphrase,
                                focusNode: controller.nextFocus,
                                validator: controller.onValidatePassphrase),
                          ]))
                ]),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FixedElevatedButton(
                    padding: WidgetConstant.paddingVertical40,
                    onPressed: controller.generateMnemonic,
                    child: Text("generate".tr))
              ])
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewMnemonic extends StatefulWidget {
  final MnemonicStateController controller;
  const _ReviewMnemonic(this.controller);

  @override
  State<_ReviewMnemonic> createState() => _ReviewMnemonicState();
}

class _ReviewMnemonicState extends State<_ReviewMnemonic>
    with SafeState<_ReviewMnemonic> {
  GeneratedMnemonic get mnemonic => widget.controller.mnemonic!;
  bool showMnemonic = false;

  void onToggleShowMnemonic() {
    showMnemonic = !showMnemonic;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("mnemonic".tr, style: context.textTheme.titleMedium),
        Text("show_mnemonic_desc".tr),
        WidgetConstant.height8,
        CustomizedContainer(
          onStackIcon: Icons.remove_red_eye,
          onTapStackIcon: onToggleShowMnemonic,
          enableTap: false,
          child: Column(
            children: [
              Stack(
                children: [
                  MnemonicView(
                      padding: EdgeInsets.zero,
                      mnemonic: mnemonic.mnemonicWords,
                      color: context.onPrimaryContainer,
                      reverse: context.primaryContainer),
                  Positioned.fill(
                    child: APPAnimatedSwitcher(enable: showMnemonic, widgets: {
                      true: (context) => WidgetConstant.sizedBox,
                      false: (context) => SizedBox.expand(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: context.colors.secondary.wOpacity(0.99),
                                  borderRadius: WidgetConstant.border8),
                              child: Center(
                                child: FilledButton.icon(
                                    onPressed: onToggleShowMnemonic,
                                    icon: const Icon(Icons.remove_red_eye),
                                    label: Text("show_mnemonic".tr)),
                              ),
                            ),
                          )
                    }),
                  )
                ],
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(
                    tooltip: 'r_generate'.tr,
                    onPressed: widget.controller.generateMnemonic,
                    icon: Icon(
                      Icons.refresh,
                      color: context.onPrimaryContainer,
                    )),
                CopyTextIcon(
                    dataToCopy: mnemonic.mnemonic.toStr(),
                    color: context.onPrimaryContainer),
              ]),
            ],
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: widget.controller.goToVerifyPage,
              child: Text('continue'.tr)),
        ])
      ]),
    );
  }
}

class _VerifyMnemonic extends StatelessWidget {
  final MnemonicStateController controller;
  const _VerifyMnemonic(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerifyMnemonicView(
              mnemonic: controller.mnemonic!.mnemonicWords,
              onValidate: (v) {
                controller.onValidateMnemonic(v, (mn) => context.pop(mn));
              },
              submitText: "verify".tr),
        ],
      ),
    );
  }
}
