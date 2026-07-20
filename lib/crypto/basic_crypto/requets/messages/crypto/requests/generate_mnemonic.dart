import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/app/core.dart';

class CryptoRequestGenerateBip39Mnemonic extends CryptoRequest<Mnemonic> {
  final Bip39Languages language;
  final Bip39WordsNum wordNums;
  CryptoRequestGenerateBip39Mnemonic._({required this.language, required this.wordNums});

  factory CryptoRequestGenerateBip39Mnemonic(
      {required Bip39Languages language, required Bip39WordsNum wordNums}) {
    return CryptoRequestGenerateBip39Mnemonic._(language: language, wordNums: wordNums);
  }
  factory CryptoRequestGenerateBip39Mnemonic.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.generateBip39Mnemonic.tag);
    return CryptoRequestGenerateBip39Mnemonic(
      language: Bip39Languages.values.firstWhere(
          (e) => e.name == values.rawValueAt<String?>(0),
          orElse: () => throw AppInternalError.internalError(
              "CryptoRequestGenerateBip39Mnemonic.deserialize")),
      wordNums: Bip39WordsNum.values.firstWhere(
          (e) => e.value == values.rawValueAt<int?>(1),
          orElse: () => throw AppInternalError.internalError(
              "CryptoRequestGenerateBip39Mnemonic.deserialize")),
    );
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.generateBip39Mnemonic;
  static Mnemonic generateMenemonic(
      {required Bip39Languages language, required Bip39WordsNum wordNums}) {
    final generator = Bip39MnemonicGenerator(language);
    final mnemonic = generator.fromWordsNumber(wordNums);
    return mnemonic;
  }

  @override
  Mnemonic parsResult(MessageArgsComplete result) {
    return Mnemonic.deserialize(object: result.result);
  }

  @override
  Future<Mnemonic> result(AppContext context, {List<int>? encryptedPart}) async {
    return generateMenemonic(language: language, wordNums: wordNums);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [language.name.toCbor(), wordNums.value.toCbor()];
}
