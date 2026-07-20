import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/requests/generate_mnemonic.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/requests/generate_monero_mnemonic.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/requests/ton.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/setup/types/types.dart';
import 'package:on_chain_wallet/future/widgets/widgets/progress_bar/widgets/stream_page_progress.dart';
import 'package:on_chain_wallet/future/widgets/widgets/text_field.dart';
import 'package:on_chain_wallet/future/widgets/widgets/text_or_file_picker.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ton.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class MnemonicStateController with DisposableMixin, StreamStateController {
  final WalletProvider walletProvider;
  SetupMnemonicPage page = SetupMnemonicPage.generate;
  MnemonicStateController({required this.walletProvider, this.allowMnemonicType});
  GeneratedMnemonic? _mnemonic;
  GeneratedMnemonic? get mnemonic => _mnemonic;
  late MnemonicType type = allowMnemonicType ?? MnemonicType.bip39;
  final MnemonicType? allowMnemonicType;
  bool isEnabled(MnemonicType type) {
    if (allowMnemonicType == null) return true;
    return allowMnemonicType == type;
  }

  final FocusNode nextFocus = FocusNode();
  final StreamPageProgressController pageController = StreamPageProgressController();
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "MnemonicStateController_formKey");

  bool _usePassphrase = false;
  bool get usePassphrase => _usePassphrase;
  MnemonicWordCountView? _wordCount;
  MnemonicWordCountView get wordCounts => _wordCount!;
  List<MnemonicWordCountView> _wordsCounts = [];
  List<MnemonicWordCountView> get wordsCounts => _wordsCounts;
  List<MenemonicLanguageView> _languages = [];
  List<MenemonicLanguageView> get languages => _languages;
  MenemonicLanguageView? _language;
  MenemonicLanguageView get language => _language!;

  String _passphrase = "";
  String _confirmPassphrase = "";
  String get passhrase => _passphrase;
  String get confirmPassphrase => _confirmPassphrase;

  List<MenemonicLanguageView> _buildLanguages() {
    switch (type) {
      case MnemonicType.bip39:
        return Bip39Languages.values
            .map((e) => MenemonicLanguageView(
                language: e, name: e.name.camelCase, identifier: e.name))
            .toList();
      case MnemonicType.monero:
        return MoneroLanguages.values
            .map((e) => MenemonicLanguageView(
                language: e, name: e.name.camelCase, identifier: e.name))
            .toList();
      case MnemonicType.ton:
        return [
          MenemonicLanguageView(
              language: Bip39Languages.english,
              name: Bip39Languages.english.name.camelCase,
              identifier: Bip39Languages.english.name)
        ];
    }
  }

  List<MnemonicWordCountView> _buildWordNumbers() {
    switch (type) {
      case MnemonicType.bip39:
        return Bip39WordsNum.values
            .map((e) => MnemonicWordCountView(
                number: e.value, name: "n_word".tr.replaceOne(e.value.toString())))
            .toList();
      case MnemonicType.monero:
        return MoneroWordsNum.values
            .map((e) => MnemonicWordCountView(
                number: e.value, name: "n_word".tr.replaceOne(e.value.toString())))
            .toList();
      case MnemonicType.ton:
        return List.generate(
            (TonConst.maxTonMnemonicWords - TonConst.minTonMnemonicWords) + 1, (i) {
          final value = TonConst.minTonMnemonicWords + i;
          return MnemonicWordCountView(
              number: value, name: "n_word".tr.replaceOne(value.toString()));
        });
    }
  }

  void _buildState() {
    _languages = _buildLanguages();
    _language = _languages.firstWhere((e) => e.identifier == Bip39Languages.english.name);
    _wordsCounts = _buildWordNumbers();
    _wordCount = wordsCounts.first;
  }

  void onStateUpdated() {
    notify();
    // MnemonicLanguages languages =
  }

  void onChangeMnemonicType(final MnemonicType? type) {
    if (type == null) return;
    this.type = type;
    _buildState();
    onStateUpdated();
  }

  void onChangeLanguage(final MenemonicLanguageView? language) {
    if (language == null) return;
    _language = language;
    onStateUpdated();
  }

  void onChangeWordsNumber(final MnemonicWordCountView? wordCount) {
    if (wordCount == null) return;
    _wordCount = wordCount;
    onStateUpdated();
  }

  void onChangeUsePassphrase(bool? v) {
    _usePassphrase = v ?? usePassphrase;
    _passphrase = "";
    onStateUpdated();
  }

  void onChangePassphrase(String v) {
    _passphrase = v;
  }

  void onChangeConfrimPassphrase(String v) {
    _confirmPassphrase = v;
  }

  String? onValidatePassphrase(String? v) {
    // if (!usePassphrase) return null;
    if (v?.isEmpty ?? true) {
      return "password_should_not_be_empty".tr;
    }
    return null;
  }

  String? onValidateConfirmPassphrase(String? v) {
    if (_passphrase == v) return null;
    return "p_does_not_match".tr;
  }

  Future<GeneratedMnemonic> _generateMnemonic({
    required String? passphrase,
    required String? languageIdentifier,
    required int wordCounts,
    required MnemonicType type,
  }) async {
    final language = switch (type) {
      MnemonicType.bip39 =>
        Bip39Languages.values.firstWhere((e) => e.name == languageIdentifier),
      MnemonicType.monero =>
        MoneroLanguages.values.firstWhere((e) => e.name == languageIdentifier),
      _ => null
    };
    IResult<Mnemonic> mnemonic;
    switch (type) {
      case MnemonicType.bip39:
        final wNum = Bip39WordsNum.fromValue(wordCounts);
        mnemonic = await walletProvider.wallet.doAction(WalletActionCryptoRequest(
            request: CryptoRequestGenerateBip39Mnemonic(
                language: language as Bip39Languages, wordNums: wNum!)));
        break;
      case MnemonicType.ton:
        mnemonic = await walletProvider.wallet.doAction(WalletActionCryptoRequest(
            request:
                TonMenmonicGenerateMessage(password: passphrase, wordsNum: wordCounts)));
        break;
      case MnemonicType.monero:
        mnemonic = await walletProvider.wallet.doAction(WalletActionCryptoRequest(
            request: MoneroMenmonicGenerateMessage(
                language: language as MoneroLanguages,
                wordsNum: MoneroWordsNum.fromValue(wordCounts))));
        break;
    }
    return GeneratedMnemonic(
        mnemonic: mnemonic.unwrap(),
        passphrase: passphrase,
        language: language,
        languageIdentifer: languageIdentifier,
        type: type);
  }

  Future<void> generateMnemonic() async {
    if (page == SetupMnemonicPage.generate && !formKey.ready()) return;
    pageController.progressText("generating_mnemonic_please_wait".tr);
    page = SetupMnemonicPage.generate;
    final result = await IResult.call(() async {
      return _generateMnemonic(
          passphrase: mnemonic?.passphrase ??
              (usePassphrase && type.supportPassPhrase ? _passphrase : null),
          languageIdentifier: mnemonic?.languageIdentifer ?? language.identifier,
          wordCounts: mnemonic?.mnemonicWords.length ?? wordCounts.number,
          type: type);
    }, delay: type == MnemonicType.bip39 ? APPConst.oneSecoundDuration : null);
    if (result.isOk) {
      _mnemonic = result.unwrap();
      page = SetupMnemonicPage.review;
      pageController.success();
    } else {
      pageController.errorText(result.unwrapErr().localizationError);
    }
    notify();
  }

  void goToVerifyPage() {
    if (_mnemonic == null) return;
    page = SetupMnemonicPage.verify;
    onStateUpdated();
  }

  void onValidateMnemonic(List<String> mnemonic, ONMNEMONICREADY onReady) {
    final generatedMnemonic = this.mnemonic;
    if (generatedMnemonic == null) return;
    if (CompareUtils.iterableIsEqual(mnemonic, generatedMnemonic.mnemonicWords)) {
      onReady(generatedMnemonic);
    }
  }

  void init() {
    _buildState();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    nextFocus.dispose();
    _passphrase = '';
    _mnemonic = null;
    _wordsCounts = [];
    _languages = [];
  }
}

class ExistsMnemonicStateController with DisposableMixin, StreamStateController {
  final WalletProvider walletProvider;
  ExistsMnemonicStateController({required this.walletProvider, this.allowMnemonicType});

  late MnemonicType type = allowMnemonicType ?? MnemonicType.bip39;
  final MnemonicType? allowMnemonicType;
  bool isEnabled(MnemonicType type) {
    if (allowMnemonicType == null) return true;
    return allowMnemonicType == type;
  }

  final FocusNode nextFocus = FocusNode();
  final StreamPageProgressController pageController = StreamPageProgressController();
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "MnemonicStateController_formKey");
  GlobalKey<AppTextFieldState> mnemonicTextFieldKey = GlobalKey();
  bool _usePassphrase = false;
  bool get usePassphrase => _usePassphrase;

  String _passphrase = "";
  String _confirmPassphrase = "";
  String get passhrase => _passphrase;
  String get confirmPassphrase => _confirmPassphrase;

  String mnemonic = "";

  void onChangeMnemonicType(final MnemonicType? type) {
    if (type == null) return;
    this.type = type;
    mnemonicTextFieldKey = GlobalKey();
    onStateUpdated();
  }

  void onStateUpdated() {
    notify();
    // MnemonicLanguages languages =
  }

  void onChangeUsePassphrase(bool? v) {
    if (!type.supportPassPhrase) return;
    _usePassphrase = v ?? usePassphrase;
    _passphrase = "";
    _confirmPassphrase = "";
    onStateUpdated();
  }

  void onChangePassphrase(String v) {
    _passphrase = v;
  }

  void onChangeConfrimPassphrase(String v) {
    _confirmPassphrase = v;
  }

  void onChangeMnemonic(String v) {
    mnemonic = v;
  }

  void onPasteMnemonic(String? v) {
    if (v == null) return;
    mnemonicTextFieldKey.currentState?.updateText(v);
  }

  String? onValidatePassphrase(String? v) {
    // if (!usePassphrase) return null;
    if (v?.isEmpty ?? true) {
      return "password_should_not_be_empty".tr;
    }
    return null;
  }

  String? onValidateConfirmPassphrase(String? v) {
    if (_passphrase == v) return null;
    return "p_does_not_match".tr;
  }

  String? onValidateMnemonicLength(int length) {
    return switch (type) {
      MnemonicType.bip39 => () {
          if (Bip39WordsNum.values.any((e) => e.value == length)) return null;
          return "invalid_bip39_mnemonic_words_length".tr;
        }(),
      MnemonicType.monero => () {
          if (MoneroWordsNum.values.any((e) => e.value == length)) return null;
          return "invalid_monero_mnemonic_words_length".tr;
        }(),
      MnemonicType.ton => () {
          if (length >= TonConst.minTonMnemonicWords &&
              length <= TonConst.maxTonMnemonicWords) {
            return null;
          }
          return "invalid_ton_mnemonic_words_length".tr;
        }(),
    };
  }

  MenemonicLanguageView? findMnemonicLanguage(Mnemonic mnemonic) {
    return switch (type) {
      MnemonicType.bip39 => () {
          try {
            final language =
                Bip39WordsListFinder(Bip39Languages.values).findLanguage(mnemonic).$2;
            return MenemonicLanguageView(
                language: language,
                name: language.name.camelCase,
                identifier: language.name);
          } catch (_) {
            return null;
          }
        }(),
      MnemonicType.monero => () {
          try {
            final language = MoneroWordsListFinder().findLanguage(mnemonic).$2;
            return MenemonicLanguageView(
                language: language,
                name: language.name.camelCase,
                identifier: language.name);
          } catch (_) {
            return null;
          }
        }(),
      MnemonicType.ton => () {
          if (mnemonic
              .toList()
              .every((e) => TonMnemonicLanguages.english.wordList.contains(e))) {
            return MenemonicLanguageView(
                language: TonMnemonicLanguages.english,
                name: TonMnemonicLanguages.english.name.camelCase,
                identifier: TonMnemonicLanguages.english.name);
          }
        }(),
    };
  }

  String? onValidateMnemonic(String? v) {
    final Mnemonic mnemonic = Mnemonic.fromString(v ?? '');
    final lengthError = onValidateMnemonicLength(mnemonic.wordsCount());
    if (lengthError != null) return lengthError;
    final language = findMnemonicLanguage(mnemonic);
    if (language == null) return "invalid_mnemonic_desc".tr;
    return null;
  }

  Future<void> validate(ONMNEMONICREADY onReady) async {
    if (!formKey.ready()) return;

    final Mnemonic mnemonic = Mnemonic.fromString(this.mnemonic);
    final lengthValidator = onValidateMnemonicLength(mnemonic.wordsCount());
    final language = findMnemonicLanguage(mnemonic);
    if (lengthValidator != null || language == null) return;
    pageController.progressText("verifying_mnemonic_please_wait".tr);
    final passphrase = (usePassphrase && type.supportPassPhrase ? _passphrase : null);
    final result = await IResult.call(() async {
      switch (type) {
        case MnemonicType.bip39:
          CryptoKeyUtils.validateMnemonic(mnemonic.toStr());
          return GeneratedMnemonic(
              mnemonic: mnemonic,
              passphrase: passphrase,
              language: language.language,
              languageIdentifer: language.identifier,
              type: type);

        case MnemonicType.ton:
          CryptoKeyUtils.validateMnemonicWords(mnemonic.toList());
          final isValid = (await walletProvider.wallet.doAction(WalletActionCryptoRequest(
                  request: TonMnemonicValidateMessage(
                      mnemonic: mnemonic.toStr(), password: passphrase))))
              .unwrap();
          if (!isValid.data) {
            throw AppCryptoExceptionConst.invalidMnemonic;
          }
          return GeneratedMnemonic(
              mnemonic: mnemonic,
              passphrase: passphrase,
              language: language.language,
              languageIdentifer: language.identifier,
              type: type);

        case MnemonicType.monero:
          MoneroMnemonicValidator().validate(mnemonic.toStr());
          return GeneratedMnemonic(
              mnemonic: mnemonic,
              passphrase: passphrase,
              language: language.language,
              languageIdentifer: language.identifier,
              type: type);
      }
    }, delay: APPConst.oneSecoundDuration);
    if (result.isOk) {
      pageController.backToIdle();
      onReady(result.unwrap());
    } else {
      pageController.errorText(result.unwrapErr().localizationError);
    }
    onStateUpdated();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    nextFocus.dispose();
    mnemonic = '';
    _passphrase = '';
    _confirmPassphrase = '';
  }
}

class WalletBackupStateController with DisposableMixin, StreamStateController {
  final WalletProvider walletProvider;
  final String password;
  WalletBackupStateController({required this.walletProvider, required this.password});
  final FocusNode nextFocus = FocusNode();
  final StreamPageProgressController pageController = StreamPageProgressController();
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "MnemonicStateController_formKey");
  final GlobalKey<BackupDataPickerViewState> backupKey =
      GlobalKey(debugLabel: "MnemonicStateController_backupKey");
  LivePercentProgressBar? progressBar;
  WalletBackupPage page = WalletBackupPage.backup;
  VerifiedMainWalletBackup? backupData;
  bool _usePassphrase = false;
  bool get usePassphrase => _usePassphrase;

  String passphrase = "";

  String backupPassword = "";
  // String get backupPassword => _backupPassword;
  bool verifyBackupContent = false;
  void onStateUpdated() {
    notify();
  }

  void onChangeVerifyBackup(bool? _) {
    verifyBackupContent = !verifyBackupContent;
    onStateUpdated();
  }

  void onChangeUsePassphrase(bool? v) {
    _usePassphrase = v ?? usePassphrase;
    passphrase = "";
    onStateUpdated();
  }

  void onChangeBackupPassword(String v) {
    backupPassword = v;
  }

  String? onValidateBackupPassword(String? v) {
    if (v?.isEmpty ?? true) {
      return "password_validator_desc".tr;
    }
    return null;
  }

  void onChangePassphrase(String v) {
    passphrase = v;
  }

  String? onValidatePassphrase(String? v) {
    if (v?.isEmpty ?? true) {
      return "password_should_not_be_empty".tr;
    }
    return null;
  }

  Future<void> validateBackup() async {
    if (!formKey.ready()) return;
    final backup = backupKey.currentState?.getData();
    if (backup == null) return;
    pageController.progressText("validate_backup_content".tr);
    final result = await IResult.call(() async {
      WalletBackup walletBackup;
      try {
        final b = WalletBackupCore.deserialize(bytes: backup);
        if (b.type != WalletBackupTypes.walletV3) {
          throw WalletExceptionConst.invalidBackupData;
        }
        walletBackup = b as WalletBackup;
      } on IException catch (_) {
        throw WalletExceptionConst.invalidBackupData;
      } catch (e) {
        throw WalletExceptionConst.invalidBackupData;
      }

      final decodeBytes =
          await walletProvider.wallet.doAction(WalletActionDecryptKeysBackup(
        backup: walletBackup.key,
        password: backupPassword,
        encoding: walletBackup.type.encoding,
      ));
      return walletBackup.decrypt(decodeBytes.unwrap());
    });
    if (result.isErr) {
      pageController.errorText(result.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    progressBar?.dispose();

    progressBar = LivePercentProgressBar();
    pageController.progressText("verifying_backup_please_wait".tr,
        progressBar: progressBar);
    final backupData = await walletProvider.wallet.doAction(
        WalletActionVerifyWalletBackup(
            backup: result.unwrap(),
            passhphrase: usePassphrase ? passphrase : null,
            password: password,
            progress: progressBar,
            verify: verifyBackupContent));

    if (backupData.isErr) {
      pageController.errorText(backupData.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    this.backupData = backupData.unwrap();
    page = WalletBackupPage.review;
    pageController.backToIdle();
    onStateUpdated();
    progressBar?.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    progressBar?.dispose();
    progressBar = null;
    pageController.dispose();
    nextFocus.dispose();
    passphrase = '';
    backupPassword = '';
    backupData = null;
  }
}
