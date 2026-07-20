import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/zcash_context.dart';
import 'package:on_chain_wallet/crypto/types/coins/utils/coins.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

final class CryptoRequestGenerateImportedKey extends CryptoRequest<ImportedKeyStorage> {
  final String key;
  final CryptoCoins coin;
  final CustomKeyType keyType;
  final String keyName;

  CryptoRequestGenerateImportedKey(
      {required this.key,
      required this.coin,
      required this.keyType,
      required this.keyName});

  factory CryptoRequestGenerateImportedKey.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.generateImportKey.tag);
    return CryptoRequestGenerateImportedKey(
        key: values.rawValueAt(0),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt<int>(1)),
        keyType: CustomKeyType.fromValue(values.rawValueAt(2)),
        keyName: values.rawValueAt(3));
  }

  @override
  ImportedKeyStorage parsResult(MessageArgsComplete result) {
    return ImportedKeyStorage.deserialize(object: result.result);
  }

  @override
  Future<ImportedKeyStorage> result(AppContext context,
      {List<int>? encryptedPart}) async {
    switch (keyType) {
      case CustomKeyType.extendedKey:
        return CryptoKeyUtils.extendeKeyToStorage(
            extendedKey: key, coin: coin, keyName: keyName);
      case CustomKeyType.privateKey:
        return CryptoKeyUtils.privateKeyToStorage(
            privateKey: key, coin: coin, keyName: keyName);
      case CustomKeyType.wif:
        return CryptoKeyUtils.wifToStorage(coin: coin, wifKey: key, keyName: keyName);
      case CustomKeyType.orchardSpendKey:
        final (crypto, _) = (await OnChainCryptoContext.inst(context)).unwrap();
        return CryptoKeyUtils.orchardSpendKeyToStorage(
            coin: coin, keyData: key, keyName: keyName, context: crypto);
      case CustomKeyType.saplingExtendedSpandingKey:
        return CryptoKeyUtils.saplingExtendedSpandingKeyToStorage(
            coin: coin, keyData: key, keyName: keyName);
      case CustomKeyType.saplingSpendKey:
        return CryptoKeyUtils.saplingSpendingKeyToStorage(
            coin: coin, keyData: key, keyName: keyName);
    }
  }

  @override
  List<CborObject?> get serializationItems =>
      [key.toCbor(), coin.identifier.toCbor(), keyType.value.toCbor(), keyName.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.generateImportKey;
}
