import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
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

class GenerateMoneroMnemonicView extends StatelessWidget {
  const GenerateMoneroMnemonicView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<MoneroNetworkClient?, IMoneroAddress?,
        MoneroChain>(
      title: "monero_mnemonic".tr,
      addressRequired: false,
      clientRequired: false,
      childBulder: (wallet, account, client, address) {
        return _GenerateMoneroMnemonicView(network: account.network, wallet: wallet);
      },
    );
  }
}

class _GenerateMoneroMnemonicView extends StatefulWidget {
  const _GenerateMoneroMnemonicView({
    required this.network,
    required this.wallet,
  });
  final WalletMoneroNetwork network;
  final WalletProvider wallet;

  @override
  State<_GenerateMoneroMnemonicView> createState() => __GenerateMoneroMnemonicViewState();
}

class __GenerateMoneroMnemonicViewState extends State<_GenerateMoneroMnemonicView>
    with
        SafeState<_GenerateMoneroMnemonicView>,
        ProgressMixin<_GenerateMoneroMnemonicView> {
  bool showKeys = false;
  bool showMnemonic = false;
  final GlobalKey<AppTextFieldState> mnemonicKey =
      GlobalKey<AppTextFieldState>(debugLabel: "__GenerateTonMnemonicViewState_1");
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // final GlobalKey<PageProgressState> progressKey = GlobalKey();

  _MnemonicOption option = _MnemonicOption.import;
  _MnemonicPage? page;
  String mnemonic = "";
  List<String> mnemonicList = [];
  ImportCustomKeys? keyPair;

  MoneroWordsNum wordsNum = MoneroWordsNum.wordsNum25;
  MoneroLanguages language = MoneroLanguages.english;
  Map<MoneroLanguages, Widget> languagesItem = {};
  Map<MoneroWordsNum, Widget> wordsNumsItems = {};

  void onChangeWordsNum(MoneroWordsNum? wordsNum) {
    if (wordsNum == null) return;
    this.wordsNum = wordsNum;
    updateState();
  }

  void onChangeLanguage(MoneroLanguages? language) {
    if (language == null) return;
    this.language = language;
    updateState();
  }

  void onChangeOption(_MnemonicOption? op) {
    option = op ?? option;
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
      page = _MnemonicPage.fromOption(option);
      updateState();
    }
  }

  String? mnemonicLengthForm(String? v) {
    if (MoneroMnemonicUtils.isValidMnemonicLength(v)) return null;

    return "monero_menonic_validator".tr;
  }

  void onPasteMnemonic(String v) {
    mnemonicKey.currentState?.updateText(v);
  }

  void onChangeShowKeys() {
    showKeys = !showKeys;
    updateState();
  }

  void onChangeShowMnemonic() {
    showMnemonic = !showMnemonic;
    updateState();
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
    progressKey.progressText("generating_mnemonic".tr);
    final result = await widget.wallet.wallet.doAction(WalletActionCryptoRequest(
        request: MoneroMenmonicGenerateMessage(language: language, wordsNum: wordsNum)));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else {
      mnemonic = result.unwrap().toStr();
      mnemonicList = CryptoKeyUtils.normalizeMnemonic(mnemonic);
      page = _MnemonicPage.viewMnemonic;
      progressKey.success();
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
      progressKey.progressText("generating_private_key".tr);
      final key = await widget.wallet.wallet.doAction(WalletActionCryptoRequest(
          request: MoneroMnemonicToPrivateKeyMessage(
              mnemonic: mnemonicList.join(" "), coin: widget.network.coins.first)));
      if (key.isErr) {
        progressKey.errorText(key.unwrapErr().localizationError);
      } else {
        keyPair = key.unwrap();
        page = _MnemonicPage.importKey;
        progressKey.success();
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
    updateState();
  }

  void init() {
    wordsNumsItems = {
      for (final i in MoneroWordsNum.values)
        i: Text("count_words".tr.replaceOne(i.value.toString()))
    };
    languagesItem = {for (final i in MoneroLanguages.values) i: Text(i.name.camelCase)};
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    MethodUtils.executeAfterDelay(() async => init());
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
            return CustomScrollView(
              slivers: [
                SliverConstraintsBoxView(
                  padding: WidgetConstant.paddingHorizontal20,
                  sliver: APPSliverAnimatedSwitcher(
                    enable: page,
                    widgets: {
                      null: (context) => _MoneroMnemonicChooseOptionPage(state: this),
                      _MnemonicPage.import: (context) =>
                          _MoneroMnemonicImportMnemonic(state: this),
                      _MnemonicPage.importKey: (context) =>
                          ImportCustomKeyToWalletView(keypair: keyPair!),
                      _MnemonicPage.generate: (context) =>
                          _MoneroMnemonicGeneratePage(state: this),
                      _MnemonicPage.viewMnemonic: (context) =>
                          _GenerateMnemonicView(state: this),
                      _MnemonicPage.verifyMnemonic: (context) =>
                          _VerifyMnemonicView(state: this)
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VerifyMnemonicView extends StatelessWidget {
  const _VerifyMnemonicView({required this.state});
  final __GenerateMoneroMnemonicViewState state;
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
  final __GenerateMoneroMnemonicViewState state;
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

class _MoneroMnemonicGeneratePage extends StatelessWidget {
  const _MoneroMnemonicGeneratePage({required this.state});
  final __GenerateMoneroMnemonicViewState state;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "monero_mnemonic".tr,
              body: Column(
                children: [
                  Text("monero_mnemonic_desc".tr),
                  WidgetConstant.height8,
                  ErrorTextContainer(
                      error: "external_mnemonic_desc2".tr, enableTap: false),
                ],
              )),
          Text("n_of_mnemonic_words".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppDropDownBottom(
            items: state.wordsNumsItems,
            value: state.wordsNum,
            onChanged: state.onChangeWordsNum,
            hint: "n_of_mnemonic_words".tr,
          ),
          WidgetConstant.height20,
          Text("Language".tr, style: context.textTheme.titleMedium),
          Text("choose_mnemonic_lang_desc".tr),
          WidgetConstant.height8,
          AppDropDownBottom(
            items: state.languagesItem,
            value: state.language,
            onChanged: state.onChangeLanguage,
            hint: "Language".tr,
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

class _MoneroMnemonicChooseOptionPage extends StatelessWidget {
  const _MoneroMnemonicChooseOptionPage({required this.state});
  final __GenerateMoneroMnemonicViewState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "monero_mnemonic".tr,
              body: Column(
                children: [
                  Text("monero_mnemonic_desc".tr),
                  WidgetConstant.height8,
                  ErrorTextContainer(
                      error: "external_mnemonic_desc2".tr, enableTap: false),
                ],
              )),
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
                      title: Text(_MnemonicOption.values[index].name.tr)),
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

class _MoneroMnemonicImportMnemonic extends StatelessWidget {
  const _MoneroMnemonicImportMnemonic({required this.state});
  final __GenerateMoneroMnemonicViewState state;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          PageTitleSubtitle(
            title: "enter_mnemonic".tr,
            body: LargeTextView(
              ["monero_menonic_validator".tr],
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
