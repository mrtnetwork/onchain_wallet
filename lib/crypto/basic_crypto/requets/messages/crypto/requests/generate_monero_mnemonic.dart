import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/types/coins/coins.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

final class MoneroMnemonicToPrivateKeyMessage extends CryptoRequest<ImportCustomKeys> {
  final String mnemonic;
  final CryptoCoins coin;
  MoneroMnemonicToPrivateKeyMessage._({required this.mnemonic, required this.coin});

  factory MoneroMnemonicToPrivateKeyMessage(
      {required String mnemonic, required CryptoCoins coin}) {
    return MoneroMnemonicToPrivateKeyMessage._(mnemonic: mnemonic, coin: coin);
  }
  factory MoneroMnemonicToPrivateKeyMessage.deserialize(
      {List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.moneroMnemonicToPrivateKey.tag);
    return MoneroMnemonicToPrivateKeyMessage(
        mnemonic: values.rawValueAt(0),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)));
  }

  @override
  ImportCustomKeys parsResult(MessageArgsComplete result) {
    return ImportCustomKeys.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.moneroMnemonicToPrivateKey;

  @override
  Future<ImportCustomKeys> result(AppContext context, {List<int>? encryptedPart}) async {
    return CryptoKeyUtils.tonMoneroPrivateSpendKey(coin: coin, mnemonic: mnemonic);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        mnemonic.toCbor(),
        coin.identifier.toCbor(),
      ];
}

final class MoneroMenmonicGenerateMessage extends CryptoRequest<Mnemonic> {
  final MoneroWordsNum wordsNum;
  final MoneroLanguages language;
  MoneroMenmonicGenerateMessage({required this.wordsNum, required this.language});
  factory MoneroMenmonicGenerateMessage.deserialize(
      {List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.generateMoneroMnemonic.tag);
    return MoneroMenmonicGenerateMessage(
        wordsNum: MoneroWordsNum.fromValue(values.rawValueAt(0)),
        language: MoneroLanguages.fromValue(values.rawValueAt(1)));
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.generateMoneroMnemonic;

  @override
  Mnemonic parsResult(MessageArgsComplete result) {
    return Mnemonic.deserialize(object: result.result);
  }

  @override
  Future<Mnemonic> result(AppContext context, {List<int>? encryptedPart}) async {
    return MoneroMnemonicGenerator(language).fromWordsNumber(wordsNum);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [wordsNum.value.toCbor(), language.name.toCbor()];
}
