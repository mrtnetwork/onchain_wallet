import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

final class CryptoRequestGenerateMasterKey<ENC extends IViewMasterKey>
    extends CryptoRequest<ENC> {
  final StorageEncryptedWallet walletData;
  // final int version;
  final List<int>? newKeyString;
  final List<int> keyString;
  final List<int> keyChecksum;
  final List<int> memoryKey;
  CryptoRequestGenerateMasterKey._({
    // required this.version,
    required this.walletData,
    required List<int> keyString,
    required List<int> keyChecksum,
    required List<int> memoryKey,
    List<int>? newKeyString,
  })  : newKeyString = newKeyString?.asImmutableBytes,
        keyString = keyString.asImmutableBytes,
        keyChecksum = keyChecksum.asImmutableBytes,
        memoryKey = memoryKey.asImmutableBytes;
  factory CryptoRequestGenerateMasterKey.fromStorage(
      {required StorageEncryptedWallet storageData,
      required String key,
      String? newKey,
      required List<int> checksum,
      required List<int> memoryKey}) {
    return CryptoRequestGenerateMasterKey._(
        walletData: storageData,
        keyString: StringUtils.encode(key),
        newKeyString: newKey == null ? null : StringUtils.encode(newKey),
        keyChecksum: checksum,
        memoryKey: memoryKey);
  }

  factory CryptoRequestGenerateMasterKey.fromStorageWithStringKey(
      {required StorageEncryptedWallet storageData,
      required String key,
      required List<int> checksum,
      required List<int> memoryKey,
      String? newKey}) {
    return CryptoRequestGenerateMasterKey._(
        walletData: storageData,
        newKeyString: newKey == null ? null : StringUtils.encode(newKey),
        keyString: StringUtils.encode(key),
        keyChecksum: checksum,
        memoryKey: memoryKey);
  }

  factory CryptoRequestGenerateMasterKey.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.generateMasterKey.tag);
    return CryptoRequestGenerateMasterKey._(
        walletData: StorageEncryptedWallet.deserialize(object: values.objectAt(0)),
        newKeyString: values.rawValueAt(1),
        keyString: values.rawValueAt(2),
        keyChecksum: values.rawValueAt(3),
        memoryKey: values.rawValueAt(4));
  }

  /// encrypted master key, storage encrypted wallet
  static IViewMasterKey generateMasterKey({
    required List<int> rawKey,
    required List<int> checksum,
    required StorageEncryptedWallet walletData,
    required List<int> memoryKey,
    List<int>? newRawKey,
  }) {
    final cKey = MemoryWalletKey.fromRawKey(rawKey: rawKey, checksum: checksum);
    final decrypt = cKey.decryptWalletStorage(walletData);
    final masterKey = IWalletMasterKeys.deserialize(bytes: decrypt);
    return masterKey.toEncryptedMaterKey(
        key: switch (newRawKey) {
          List<int> newKey =>
            MemoryWalletKey.fromRawKey(rawKey: newKey, checksum: checksum),
          _ => cKey
        },
        memoryKey: memoryKey);
  }

  @override
  ENC parsResult(MessageArgsComplete result) {
    return IViewMasterKey.deserialize(object: result.result).cast();
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.generateMasterKey;

  @override
  Future<ENC> result(AppContext context, {List<int>? encryptedPart}) async {
    final encryptedKey = generateMasterKey(
      rawKey: keyString,
      walletData: walletData,
      checksum: keyChecksum,
      memoryKey: memoryKey,
      newRawKey: newKeyString,
    );
    return encryptedKey.cast();
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        walletData.toCbor(),
        newKeyString?.toCborBytes(),
        CborBytesValue(keyString),
        CborBytesValue(keyChecksum),
        CborBytesValue(memoryKey),
      ];
}
