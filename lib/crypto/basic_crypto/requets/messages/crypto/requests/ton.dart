import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/ton/mnemonic/ton_mnemonic_validator.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/types/coins/coins.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/networks/ton/ton.dart';

final class TonMnemonicToPrivateKeyMessage extends CryptoRequest<ImportCustomKeys> {
  final String mnemonic;
  final String? password;
  final bool validateTonMnemonic;
  final CryptoCoins coin;
  TonMnemonicToPrivateKeyMessage._({
    required this.mnemonic,
    required this.password,
    required this.validateTonMnemonic,
    required this.coin,
  });

  factory TonMnemonicToPrivateKeyMessage(
      {required String mnemonic,
      String? password,
      required bool validateTonMnemonic,
      required CryptoCoins coin}) {
    return TonMnemonicToPrivateKeyMessage._(
        mnemonic: mnemonic,
        password: password,
        validateTonMnemonic: validateTonMnemonic,
        coin: coin);
  }
  factory TonMnemonicToPrivateKeyMessage.deserialize(
      {List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.tonMnemonicToPrivateKey.tag);
    return TonMnemonicToPrivateKeyMessage(
        mnemonic: values.rawValueAt(0),
        password: values.rawValueAt(1),
        validateTonMnemonic: values.rawValueAt(2),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(3)));
  }

  @override
  ImportCustomKeys parsResult(MessageArgsComplete result) {
    return ImportCustomKeys.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.tonMnemonicToPrivateKey;

  @override
  Future<ImportCustomKeys> result(AppContext context, {List<int>? encryptedPart}) async {
    return CryptoKeyUtils.tonMnemonicToPrivateKey(
        coin: coin,
        mnemonic: mnemonic,
        password: password,
        validateTonMnemonic: validateTonMnemonic);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        mnemonic.toCbor(),
        password?.toCbor(),
        validateTonMnemonic.toCbor(),
        coin.identifier.toCbor(),
      ];
}

final class TonMenmonicGenerateMessage extends CryptoRequest<Mnemonic> {
  final String? password;
  final int wordsNum;
  TonMenmonicGenerateMessage({required this.password, required this.wordsNum});
  factory TonMenmonicGenerateMessage.deserialize(
      {List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.generateMnemonic.tag);
    return TonMenmonicGenerateMessage(
        password: values.rawValueAt(0), wordsNum: values.rawValueAt(1));
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.generateMnemonic;

  @override
  Mnemonic parsResult(MessageArgsComplete result) {
    return Mnemonic.deserialize(object: result.result);
  }

  @override
  Future<Mnemonic> result(AppContext context, {List<int>? encryptedPart}) async {
    return TonUtils.generateTonMnemonic(wordsNum: wordsNum, password: password);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [password?.toCbor(), wordsNum.toCbor()];
}

final class TonMnemonicValidateMessage extends CryptoRequest<AppSerializationBoolean> {
  final String mnemonic;
  final String? password;
  TonMnemonicValidateMessage._({required this.mnemonic, required this.password});

  factory TonMnemonicValidateMessage({required String mnemonic, String? password}) {
    return TonMnemonicValidateMessage._(mnemonic: mnemonic, password: password);
  }
  factory TonMnemonicValidateMessage.deserialize(
      {List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.tonMnemonicValidate.tag);
    return TonMnemonicValidateMessage(
        mnemonic: values.rawValueAt(0), password: values.rawValueAt(1));
  }

  @override
  AppSerializationBoolean parsResult(MessageArgsComplete result) {
    return AppSerializationBoolean.deserialize(obj: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.tonMnemonicValidate;

  @override
  Future<AppSerializationBoolean> result(AppContext context,
      {List<int>? encryptedPart}) async {
    try {
      TomMnemonicValidator()
          .validate(Mnemonic.fromString(mnemonic), password: password ?? "");
      return AppSerializationBoolean(true);
    } catch (e) {
      return AppSerializationBoolean(false);
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [mnemonic.toCbor(), password?.toCbor()];
}
