import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/create_wallet.dart';

final class CryptoRequestCreateHDWallet
    extends CryptoRequest<CryptoCreateWalletResponse> {
  final String mnemonic;
  final String? passphrase;
  final String password;
  final List<int> checksum;
  CryptoRequestCreateHDWallet(
      {required this.mnemonic,
      required this.passphrase,
      required this.password,
      required this.checksum});

  factory CryptoRequestCreateHDWallet.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.createWallet.tag);
    return CryptoRequestCreateHDWallet(
        mnemonic: values.rawValueAt(0),
        passphrase: values.rawValueAt(1),
        password: values.rawValueAt(2),
        checksum: values.rawValueAt(3));
  }

  /// MasterKey, storage encryptedBytes, checksum
  static CryptoCreateWalletResponse createHdWallet({
    required String mnemonic,
    required String? passphrase,
    required String password,
    required List<int> checksum,
  }) {
    final masterKey =
        WalletMasterKeys.generate(mnemonic: mnemonic, passphrase: passphrase);
    final encrypt = masterKey.toEncryptedMaterKey(
        key: MemoryWalletKey.fromRawKey(
            rawKey: StringUtils.encode(password), checksum: checksum),
        memoryKey: QuickCrypto.generateRandom());
    return CryptoCreateWalletResponse(masterKey: encrypt, checksum: checksum);
  }

  @override
  CryptoCreateWalletResponse parsResult(MessageArgsComplete result) {
    return CryptoCreateWalletResponse.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.createWallet;

  @override
  Future<CryptoCreateWalletResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    return createHdWallet(
        mnemonic: mnemonic,
        passphrase: passphrase,
        password: password,
        checksum: checksum);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        mnemonic.toCbor(),
        passphrase?.toCbor(),
        password.toCbor(),
        CborBytesValue(checksum)
      ];
}
