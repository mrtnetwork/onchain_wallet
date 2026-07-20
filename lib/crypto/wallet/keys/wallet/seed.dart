part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

enum SeedTypes {
  bip39(name: "Bip39", value: 0),
  bip39Entropy(name: "Bip39Entropy", value: 1),
  byronLegacySeed(name: "ByronLegacySeed", value: 2),
  icarus(name: "icarus", value: 3);

  final String name;
  final int value;
  const SeedTypes({required this.name, required this.value});
  static SeedTypes fromValue(int? tag) {
    return values.firstWhere((e) => e.value == tag,
        orElse: () => throw AppInternalError.internalError("SeedTypes"));
  }
}

enum APPBip39Languages {
  /// Chinese (Simplified)
  chineseSimplified(0),

  /// Chinese (Traditional)
  chineseTraditional(1),

  /// Czech
  czech(2),

  /// English
  english(3),

  /// French
  french(4),

  /// Italian
  italian(5),

  /// Korean
  korean(6),

  /// Portuguese
  portuguese(7),

  /// Japanese
  japanese(8),

  /// Spanish
  spanish(9);

  final int value;
  const APPBip39Languages(this.value);

  static APPBip39Languages findLanguage(Mnemonic mnemonic) {
    try {
      final language = Bip39WordsListFinder(Bip39Languages.values).findLanguage(mnemonic);
      return fromBip39Language(language.$2);
    } catch (_) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
  }

  static APPBip39Languages fromBip39Language(Bip39Languages language) {
    return switch (language) {
      Bip39Languages.chineseSimplified => chineseSimplified,
      Bip39Languages.chineseTraditional => chineseTraditional,
      Bip39Languages.czech => czech,
      Bip39Languages.english => english,
      Bip39Languages.french => french,
      Bip39Languages.italian => italian,
      Bip39Languages.korean => korean,
      Bip39Languages.portuguese => portuguese,
      Bip39Languages.spanish => spanish,
      Bip39Languages.japanese => japanese,
      _ => throw AppCryptoExceptionConst.invalidMnemonic
    };
  }

  Bip39Languages get language {
    return switch (this) {
      chineseSimplified => Bip39Languages.chineseSimplified,
      chineseTraditional => Bip39Languages.chineseTraditional,
      czech => Bip39Languages.czech,
      english => Bip39Languages.english,
      french => Bip39Languages.french,
      italian => Bip39Languages.italian,
      korean => Bip39Languages.korean,
      portuguese => Bip39Languages.portuguese,
      spanish => Bip39Languages.spanish,
      japanese => Bip39Languages.japanese
    };
  }

  static APPBip39Languages fromValue(int? tag) {
    return values.firstWhere((e) => e.value == tag,
        orElse: () => throw AppInternalError.internalError("APPBip39Languages"));
  }
}

enum AppMoneroMnemonicLanguages {
  /// Chinese (Simplified)
  chineseSimplified(0),

  dutch(1),

  english(2),

  /// French
  french(3),

  /// Czech
  german(4),

  /// Italian
  italian(5),

  /// Japanese
  japanese(6),

  /// Portuguese
  portuguese(7),

  /// Spanish
  spanish(8),

  russian(9);

  final int value;
  const AppMoneroMnemonicLanguages(this.value);

  static AppMoneroMnemonicLanguages findLanguage(Mnemonic mnemonic) {
    try {
      final language = MoneroWordsListFinder().findLanguage(mnemonic);
      return fromBip39Language(language.$2);
    } catch (_) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
  }

  static AppMoneroMnemonicLanguages fromBip39Language(MoneroLanguages language) {
    return switch (language) {
      MoneroLanguages.chineseSimplified => chineseSimplified,
      MoneroLanguages.dutch => dutch,
      MoneroLanguages.russian => russian,
      MoneroLanguages.english => english,
      MoneroLanguages.french => french,
      MoneroLanguages.italian => italian,
      MoneroLanguages.portuguese => portuguese,
      MoneroLanguages.spanish => spanish,
      MoneroLanguages.japanese => japanese,
      MoneroLanguages.german => german,
      _ => throw AppCryptoExceptionConst.invalidMnemonic
    };
  }

  MoneroLanguages get language {
    return switch (this) {
      chineseSimplified => MoneroLanguages.chineseSimplified,
      dutch => MoneroLanguages.dutch,
      english => MoneroLanguages.english,
      french => MoneroLanguages.french,
      italian => MoneroLanguages.italian,
      russian => MoneroLanguages.russian,
      portuguese => MoneroLanguages.portuguese,
      spanish => MoneroLanguages.spanish,
      japanese => MoneroLanguages.japanese,
      german => MoneroLanguages.german,
    };
  }

  static AppMoneroMnemonicLanguages fromValue(int? tag) {
    return values.firstWhere((e) => e.value == tag,
        orElse: () => throw AppInternalError.internalError("AppMoneroMnemonicLanguages"));
  }
}
