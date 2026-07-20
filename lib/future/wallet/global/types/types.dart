import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class PublicKeyDerivationWithMode {
  final CryptoPublicKeyDataWithInfo derivation;
  final PubKeyModes mode;
  const PublicKeyDerivationWithMode({required this.derivation, required this.mode});

  String selectedKey() {
    assert(mode != PubKeyModes.uncompressed || derivation.viewKey.uncomprossed != null);
    return switch (mode) {
      PubKeyModes.compressed => derivation.viewKey.comprossed,
      PubKeyModes.uncompressed =>
        derivation.viewKey.uncomprossed ?? derivation.viewKey.comprossed
    };
  }
}
