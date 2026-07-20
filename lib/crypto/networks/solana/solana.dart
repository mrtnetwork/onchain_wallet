import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain/on_chain.dart';

class SolanaCryptoUtils {
  static SolanaPrivateKey convertSolanaBase58ToPrivateKey(String? b58Key) {
    try {
      return SolanaPrivateKey.fromBase58(b58Key!);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidEncodedKeyData;
    }
  }
}
