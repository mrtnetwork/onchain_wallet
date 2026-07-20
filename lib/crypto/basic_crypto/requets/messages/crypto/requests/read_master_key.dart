import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class CryptoRequestReadMasterKey extends CryptoRequest<WalletMasterKeys> {
  final int version;
  final List<int> nonce;
  final List<int> walletData;
  final List<int> key;
  CryptoRequestReadMasterKey._(
      {required this.version,
      required this.nonce,
      required this.walletData,
      required this.key});

  factory CryptoRequestReadMasterKey({
    required int version,
    required List<int> walletData,
    required List<int> key,
    required List<int> nonce,
  }) {
    return CryptoRequestReadMasterKey._(
        version: version,
        walletData: walletData.asImmutableBytes,
        key: key.asImmutableBytes,
        nonce: nonce.asImmutableBytes);
  }
  factory CryptoRequestReadMasterKey.fromStorage(
      {required List<int> encryptedMasterKey, required List<int> key}) {
    try {
      final CborListValue values = AppSerialization.decode(cborBytes: encryptedMasterKey);
      return CryptoRequestReadMasterKey(
          version: values.rawValueAt(0),
          nonce: values.rawValueAt(1),
          walletData: values.rawValueAt(2),
          key: key);
    } catch (e) {
      throw WalletExceptionConst.incorrectWalletData;
    }
  }

  factory CryptoRequestReadMasterKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.readMasterKey.tag);
    return CryptoRequestReadMasterKey(
        version: values.rawValueAt(0),
        nonce: values.rawValueAt(1),
        walletData: values.rawValueAt(2),
        key: values.rawValueAt(3));
  }

  static WalletMasterKeys getWalletMasterKeys(
      {required List<int> key, required List<int> nonce, required List<int> walletData}) {
    final decrypt =
        CryptoKeyUtils.decryptChacha(key: key, nonce: nonce, data: walletData);
    if (decrypt == null) {
      throw WalletExceptionConst.authFailed;
    }
    return WalletMasterKeys.deserialize(bytes: decrypt);
  }

  @override
  WalletMasterKeys parsResult(MessageArgsComplete result) {
    return WalletMasterKeys.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.readMasterKey;

  @override
  Future<WalletMasterKeys> result(AppContext context, {List<int>? encryptedPart}) async {
    return getWalletMasterKeys(key: key, nonce: nonce, walletData: walletData);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        version.toCbor(),
        CborBytesValue(nonce),
        CborBytesValue(walletData),
        CborBytesValue(key)
      ];
}
