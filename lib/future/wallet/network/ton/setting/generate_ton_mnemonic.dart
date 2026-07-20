import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';

enum _MnemonicOption { import, generate }

enum _MnemonicPage {
  import,
  generate,
  importKey,
  viewMnemonic,
  verifyMnemonic;

  static _MnemonicPage fromOption(_MnemonicOption option) {
    return values.firstWhere((element) => element.name == option.name);
  }
}

class GenerateTonMnemonicView extends StatelessWidget {
  const GenerateTonMnemonicView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<TonNetworkClient?, ITonAddress?, TonChain>(
      title: "ton_mnemonic".tr,
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) {
        return _GenerateTonMnemonicView(network: account.network, wallet: wallet);
      },
    );
  }
}

class _GenerateTonMnemonicView extends StatefulWidget {
  const _GenerateTonMnemonicView({
    required this.network,
    required this.wallet,
  });
  final WalletTonNetwork network;
  final WalletProvider wallet;

  @override
  State<_GenerateTonMnemonicView> createState() => __GenerateTonMnemonicViewState();
}

class __GenerateTonMnemonicViewState extends State<_GenerateTonMnemonicView>
    with SafeState<_GenerateTonMnemonicView>, ProgressMixin<_GenerateTonMnemonicView> {
  bool hasPassword = false;
  bool validateTonMnemonic = true;
  bool showKeys = false;
  bool showMnemonic = false;
  final GlobalKey<AppTextFieldState> passwordKey =
      GlobalKey<AppTextFieldState>(debugLabel: "__GenerateTonMnemonicViewState");
  final GlobalKey<AppTextFieldState> mnemonicKey =
      GlobalKey<AppTextFieldState>(debugLabel: "__GenerateTonMnemonicViewState_1");
  final GlobalKey<NumberTextFieldState> mnemonicWordsKey =
      GlobalKey<NumberTextFieldState>(debugLabel: "__GenerateTonMnemonicViewState_2");
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  _MnemonicOption option = _MnemonicOption.import;
  _MnemonicPage? page;
  String mnemonic = "";
  List<String> mnemonicList = [];
  String? password;

  ImportCustomKeys? keyPair;

  void onChangeOption(_MnemonicOption? op) {
    option = op ?? option;
    updateState();
  }

  void onChangePassword(bool? v) {
    hasPassword = !hasPassword;
    if (!hasPassword) {
      passwordKey.currentState?.clear();
      password = null;
    }
    updateState();
  }

  String? validator(String? v) {
    if (v?.isEmpty ?? true) {
      return "password_empty_validator".tr;
    }
    return null;
  }

  void onTapContinue() {
    if (formKey.ready()) {
      if (hasPassword) {
        password = passwordKey.currentState!.getValue();
        if (password!.isEmpty) return;
      }
      page = _MnemonicPage.fromOption(option);
      updateState();
    }
  }

  String? mnemonicLengthForm(String? v) {
    if (TonUtils.isValidTonMnemonicLength(v)) return null;
    return "enter_mnemonic_desc3".tr;
  }

  void onPasteMnemonic(String v) {
    mnemonicKey.currentState?.updateText(v);
  }

  void onCheckValidateTonMnemonic(bool? _) {
    validateTonMnemonic = !validateTonMnemonic;
    updateState();
  }

  void onChangeShowKeys() {
    showKeys = !showKeys;
    updateState();
  }

  void onChangeShowMnemonic() {
    showMnemonic = !showMnemonic;
    updateState();
  }

  String? onValidateMnemonic(String? v) {
    final int? count = int.tryParse(v ?? "");
    if (count == null ||
        count < TonConst.minTonMnemonicWords ||
        count > TonConst.maxTonMnemonicWords) {
      return "ton_mnemonic_words_length_validator".tr;
    }
    return null;
  }

  void tapOnVerifyMnemonic() {
    page = _MnemonicPage.verifyMnemonic;
    updateState();
  }

  void verifyMnemonic(List<String> mnemonic) {
    if (CompareUtils.iterableIsEqual(mnemonic, mnemonicList)) {
      _generatePrivateKey();
    }
  }

  void generateMnemonic() async {
    if (!formKey.ready()) return;
    final int? wordsNum = mnemonicWordsKey.currentState?.getValue();
    if (wordsNum == null) return;
    progressKey.progressText("generating_mnemonic".tr);
    final result = await widget.wallet.wallet.doAction(WalletActionCryptoRequest(
        request: TonMenmonicGenerateMessage(password: password, wordsNum: wordsNum)));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else {
      mnemonic = result.unwrap().toStr();
      mnemonicList = CryptoKeyUtils.normalizeMnemonic(mnemonic);
      page = _MnemonicPage.viewMnemonic;
      progressKey.success();
      updateState();
    }
  }

  void generatePrivateKey() async {
    if (!formKey.ready()) return;
    mnemonic = mnemonicKey.currentState?.getValue() ?? "";
    mnemonicList = CryptoKeyUtils.normalizeMnemonic(mnemonic);
    _generatePrivateKey();
  }

  void _generatePrivateKey() async {
    if (formKey.ready()) {
      progressKey.progressText("validating_mnemonic".tr);
      final result = await IResult.call(
          () async => CryptoKeyUtils.validateMnemonicWords(mnemonicList));
      if (result.isErr) {
        progressKey.errorText(result.unwrapErr().localizationError);
      } else {
        progressKey.progressText("generating_private_key".tr);
        final key = await widget.wallet.wallet.doAction(WalletActionCryptoRequest(
            request: TonMnemonicToPrivateKeyMessage(
                mnemonic: mnemonicList.join(" "),
                password: password,
                validateTonMnemonic: validateTonMnemonic,
                coin: widget.network.coins.first)));
        if (key.isErr) {
          progressKey.errorText(key.unwrapErr().localizationError);
        } else {
          keyPair = key.unwrap();
          page = _MnemonicPage.importKey;
          progressKey.success();
        }
      }
    }
  }

  void onBackButton() {
    switch (page) {
      case _MnemonicPage.viewMnemonic:
      case _MnemonicPage.verifyMnemonic:
        mnemonic = '';
        mnemonicList.clear();
        page = _MnemonicPage.generate;
        showMnemonic = false;
        break;
      case _MnemonicPage.importKey:
        keyPair = null;
        page = _MnemonicPage.fromOption(option);
        break;
      case _MnemonicPage.import:
      case _MnemonicPage.generate:
        mnemonic = '';
        mnemonicList.clear();
        page = null;
        break;
      default:
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: page == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          onBackButton();
        }
      },
      child: Form(
        key: formKey,
        child: StreamPageProgress(
          controller: progressKey,
          builder: (context) {
            return UnfocusableChild(
              child: CustomScrollView(
                slivers: [
                  SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver: APPSliverAnimatedSwitcher(
                      enable: page,
                      widgets: {
                        null: (context) => _TonMnemonicChooseOptionPage(state: this),
                        _MnemonicPage.import: (context) =>
                            _TonMnemonicImportMnemonic(state: this),
                        _MnemonicPage.importKey: (context) =>
                            ImportCustomKeyToWalletView(keypair: keyPair!),
                        _MnemonicPage.generate: (context) =>
                            _TonMnemonicGeneratePage(state: this),
                        _MnemonicPage.viewMnemonic: (context) =>
                            _GenerateMnemonicView(state: this),
                        _MnemonicPage.verifyMnemonic: (context) =>
                            _VerifyMnemonicView(state: this)
                      },
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerifyMnemonicView extends StatelessWidget {
  const _VerifyMnemonicView({required this.state});
  final __GenerateTonMnemonicViewState state;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerifyMnemonicView(
            mnemonic: state.mnemonicList,
            onValidate: state.verifyMnemonic,
            submitText: "generate_private_key".tr,
          )
        ],
      ),
    );
  }
}

class _GenerateMnemonicView extends StatelessWidget {
  const _GenerateMnemonicView({required this.state});
  final __GenerateTonMnemonicViewState state;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "show_mnemonic".tr,
              body: LargeTextView(["show_mnemonic_desc".tr, "p_note3".tr, "p_note4".tr])),
          Stack(
            children: [
              MnemonicView(mnemonic: state.mnemonicList),
              Positioned.fill(
                child: APPAnimatedSwitcher(enable: state.showMnemonic, widgets: {
                  true: (context) => WidgetConstant.sizedBox,
                  false: (context) => SizedBox.expand(
                        child: Container(
                          decoration: BoxDecoration(
                              color: context.colors.secondary,
                              borderRadius: WidgetConstant.border8),
                          child: Center(
                            child: FilledButton.icon(
                                onPressed: state.onChangeShowMnemonic,
                                icon: const Icon(Icons.remove_red_eye),
                                label: Text("show_mnemonic".tr)),
                          ),
                        ),
                      )
                }),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: state.tapOnVerifyMnemonic,
                child: Text("v_mnemonic".tr),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _TonMnemonicGeneratePage extends StatelessWidget {
  const _TonMnemonicGeneratePage({required this.state});
  final __GenerateTonMnemonicViewState state;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
            title: "generate_ton_mnemonic".tr,
            body: LargeTextView(
              [
                "external_mnemonic_desc2".tr,
                "ton_mnemonic_words_desc".tr,
                "p_note3".tr,
                "p_note4".tr,
              ],
              maxLine: 6,
            ),
          ),
          NumberTextField(
            label: "n_of_mnemonic_words".tr,
            onChangeValue: (p0) {},
            defaultValue: TonConst.defaultTonMnemonicWordsLength,
            validator: state.onValidateMnemonic,
            max: TonConst.maxTonMnemonicWords,
            min: TonConst.minTonMnemonicWords,
            key: state.mnemonicWordsKey,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: state.generateMnemonic,
              child: Text("generate_mnemonic".tr),
            )
          ])
        ],
      ),
    );
  }
}

class _TonMnemonicChooseOptionPage extends StatelessWidget {
  const _TonMnemonicChooseOptionPage({required this.state});
  final __GenerateTonMnemonicViewState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "ton_mnemonic".tr,
              body: LargeTextView(
                ["ton_mnemonic_desc".tr, "external_mnemonic_desc2".tr],
              )),
          AppSwitchListTile(
            value: state.hasPassword,
            onChanged: state.onChangePassword,
            title: Text(
              "mnemonic_password".tr,
              style: context.textTheme.titleMedium,
            ),
            subtitle: Text("mnemonic_password_desc".tr),
            contentPadding: EdgeInsets.zero,
            maxLine: 4,
          ),
          APPAnimatedSize(
            isActive: state.hasPassword,
            onActive: (p0) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WidgetConstant.height8,
                AppTextField(
                  obscureText: true,
                  key: state.passwordKey,
                  label: "mnemonic_password".tr,
                  validator: state.validator,
                  initialValue: state.password,
                ),
              ],
            ),
            onDeactive: (p0) => WidgetConstant.sizedBox,
          ),
          WidgetConstant.height20,
          Text("create_import_mnemonic".tr, style: context.textTheme.titleMedium),
          Text("choose_an_action".tr),
          WidgetConstant.height8,
          RadioGroup<_MnemonicOption>(
            groupValue: state.option,
            onChanged: state.onChangeOption,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  _MnemonicOption.values.length,
                  (index) => RadioListTile<_MnemonicOption>(
                    value: _MnemonicOption.values[index],
                    title: Text(_MnemonicOption.values[index].name.tr),
                  ),
                )),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: state.onTapContinue,
                child: Text("continue".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _TonMnemonicImportMnemonic extends StatelessWidget {
  const _TonMnemonicImportMnemonic({required this.state});
  final __GenerateTonMnemonicViewState state;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          PageTitleSubtitle(
            title: "enter_mnemonic".tr,
            body: LargeTextView(
              ["enter_mnemonic_desc3".tr],
            ),
          ),
          AppTextField(
            label: "enter_mne".tr,
            key: state.mnemonicKey,
            validator: state.mnemonicLengthForm,
            minlines: 3,
            initialValue: state.mnemonic,
            suffixIcon: PasteTextIcon(onPaste: state.onPasteMnemonic, isSensitive: false),
          ),
          WidgetConstant.height20,
          AppCheckListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("validate_ton_mnemonic".tr, style: context.textTheme.titleMedium),
            subtitle: Text("validate_ton_mnemonic_desc".tr),
            value: state.validateTonMnemonic,
            onChanged: state.onCheckValidateTonMnemonic,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: state.generatePrivateKey,
                child: Text("generate_private_key".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}
