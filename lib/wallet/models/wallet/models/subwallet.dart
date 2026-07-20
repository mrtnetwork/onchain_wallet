import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class WalletImportSubWalletData {
  final String mnemonic;
  final String? passphrase;
  final SubWalletType type;
  final String name;
  final int mainWalletId;
  const WalletImportSubWalletData(
      {required this.mnemonic,
      required this.passphrase,
      required this.type,
      required this.name,
      required this.mainWalletId});
}
