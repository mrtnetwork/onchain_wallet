import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/generate_master_key.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestImportSubWallet
    extends WalletRequest<CryptoImportSubWalletResponse> {
  final String mnemonic;
  final String? passphrase;
  final SubWalletType type;
  final String name;
  const WalletRequestImportSubWallet(
      {required this.mnemonic,
      required this.passphrase,
      required this.type,
      required this.name});

  factory WalletRequestImportSubWallet.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.importSubWallet.tag);
    return WalletRequestImportSubWallet(
        mnemonic: values.rawValueAt(0),
        passphrase: values.rawValueAt(1),
        type: SubWalletType.fromIdentifier(values.rawValueAt(2)),
        name: values.rawValueAt(3));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.importSubWallet;

  @override
  Future<CryptoImportSubWalletResponse> parsResult(MessageArgsComplete result) async {
    return CryptoImportSubWalletResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoImportSubWalletResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final newWallet = wallet.importNewSubWallet(
        mnemonic: mnemonic,
        type: type,
        passphrase: passphrase,
        name: name,
        created: null);
    return CryptoImportSubWalletResponse(
        masterKey: newWallet.viewKey, subWalletId: newWallet.subwalletId);
  }

  @override
  List<CborObject?> get serializationItems => [
        CborStringValue(mnemonic),
        passphrase?.toCbor(),
        type.tags.id.toCbor(),
        name.toCbor()
      ];
}
