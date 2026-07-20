import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/setup/types/types.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/subwallet.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class SetupWalletStateController with DisposableMixin, StreamStateController {
  final WalletProvider walletProvider;
  SetupWalletStateController({required this.walletProvider, required this.type})
      : mainWallet = type.isMainWallet ? null : walletProvider.wallet.wallet;
  bool isSetup = true;

  WalletStupPage page = WalletStupPage.main;
  SetupWalletMode mode = SetupWalletMode.generate;
  final APPWalletType type;
  final FocusNode nextFocus = FocusNode();
  String password = "";
  String confirmPassword = "";
  String subWalletName = "";
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();
  IMainWallet? mainWallet;
  VerifiedMainWalletBackup? backup;
  ExternalWalletData? externalWallet;
  final StreamPageProgressController pageController = StreamPageProgressController();
  void onStateUpdated() {
    notify();
  }

  PasswordStrength passwordStrength = PasswordStrength.weak;

  void onChangePassword(String v) {
    password = v;
    final passwordStrength = PasswordUtils.checkPasswordStrength(v);
    if (passwordStrength != this.passwordStrength) {
      this.passwordStrength = passwordStrength;
      onStateUpdated();
    }
  }

  void onChangeConfirmPassword(String v) {
    confirmPassword = v;
  }

  void onChangeSubWalletName(String v) {
    subWalletName = v;
  }

  String? onValidateWalletName(String? v) {
    if (v == null || v.trim().isEmpty || v.length < 3 || v.length > 15) {
      return "wallet_name_validator".tr;
    }
    if (mainWallet!.subWallets.any((e) => e.name == v)) {
      return "wallet_name_validator2".tr;
    }
    return null;
  }

  String? onValidatePassword(String? value) {
    final passwordStrength = PasswordUtils.checkPasswordStrength(value ?? '');
    if (passwordStrength == PasswordStrength.weak) {
      return "weak_password_validator".tr;
    }
    return null;
  }

  String? onValidateConfirmPassword(String? value) {
    if (value != password) {
      return "p_does_not_match".tr;
    }
    return null;
  }

  Future<void> onSetupMainWalletPassword(
      ONGENERATEMNEMONIC onGenerateMnemonic, FuncFutureNullableBool onShowTerms) async {
    final password = this.password;
    if (passwordFormKey.ready()) {
      final mnemonic = await onGenerateMnemonic(MnemonicType.bip39, mode);
      if (mnemonic == null) return;
      final acceptTerms = await onShowTerms();
      if (acceptTerms != true) return;
      pageController.progressText("setup_wallet_please_wait".tr);
      final newWallet = await walletProvider.wallet.doAction(WalletActionCreateWallet(
          mnemonic: mnemonic.mnemonic.toStr(),
          passphrase: mnemonic.passphrase,
          password: password));
      if (newWallet.isErr) {
        pageController.errorText(newWallet.unwrapErr().localizationError,
            backToIdle: false, showBackButton: true);
      } else {
        mainWallet = newWallet.unwrap();
        page = WalletStupPage.mainWalletSetting;
        pageController.backToIdle();
      }
    }
    onStateUpdated();
  }

  Future<void> onSetupSubWallet(
      ONGENERATEMNEMONIC onGenerateMnemonic, FuncFutureNullableBool onShowTerms) async {
    if (passwordFormKey.ready()) {
      final mnemonic = await onGenerateMnemonic(null, mode);
      if (mnemonic == null) return;
      final acceptTerms = await onShowTerms();
      if (acceptTerms != true) return;
      pageController.progressText("launch_the_wallet".tr);
      final subWalletData = WalletImportSubWalletData(
          mnemonic: mnemonic.mnemonic.toStr(),
          passphrase: mnemonic.passphrase,
          type: mnemonic.type.walletType,
          name: subWalletName,
          mainWalletId: mainWallet!.id);
      final result = await walletProvider.wallet
          .doAction(WalletActionSetupSubWallet(subWallet: subWalletData));
      if (result.isErr) {
        pageController.errorText(result.unwrapErr().localizationError,
            backToIdle: false, showBackButton: true);
        return;
      }
      pageController.successText("wallet_has_been_imported".tr, backToIdle: false);
    }
  }

  Future<void> onRestoreMainWalletPassword(
      ONRESTOREWALLETBACKUP onGenerateMnemonic) async {
    final password = this.password;
    if (passwordFormKey.ready()) {
      backup = await onGenerateMnemonic(password);
      if (backup == null) return;
      mainWallet = backup?.wallet;
      if (mainWallet != null) {
        page = WalletStupPage.mainWalletSetting;
      }
    }
    onStateUpdated();
  }

  Future<void> onConnectToExternalWallet(ONSETUPEXTERNALWALLET onGenerateMnemonic) async {
    final password = this.password;
    if (passwordFormKey.ready()) {
      externalWallet = await onGenerateMnemonic(password);
      if (externalWallet == null) return;
      mainWallet = externalWallet?.backup.wallet;
      if (mainWallet != null) {
        page = WalletStupPage.mainWalletSetting;
      }
    }
    onStateUpdated();
  }

  Future<void> onSetupMainWallet(WalletUpdateInfosData setting) async {
    final mainWallet = this.mainWallet;
    if (mainWallet == null) return;
    final externalWallet = this.externalWallet;

    pageController.progressText("launch_the_wallet".tr);

    /// TODO
    /// Implement external wallet pairing.
    if (externalWallet != null) {
      // final result = await externalWallet.client.client.sendSessionRequest(
      //     WCMActionVerifyPair(
      //         checksum: externalWallet.backup.checksum,
      //         clientId: externalWallet.session.session.clientId),
      //     externalWallet.session);
      // if (result.hasError) {
      //   pageController.errorText(result.localizationError,
      //       backToIdle: false, showBackButton: true);
      //   return;
      // }
    }
    final params = WalletActionSetup(
      hdWallet: backup?.wallet ?? mainWallet,
      password: password,
      walletInfos: setting,
      backup: externalWallet?.backup ?? backup,
    );
    final result = await walletProvider.wallet.doAction(params);
    if (result.isErr) {
      pageController.errorText(result.unwrapErr().localizationError);
    } else {
      pageController.successText("wallet_has_been_imported".tr, backToIdle: false);
    }
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    nextFocus.dispose();
    backup = null;
    backup = null;
    externalWallet?.client.dispose();
    externalWallet = null;
  }
}
