import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';

class DisabledAppBasicCryptoApi with AppBasicCryptoApi {
  const DisabledAppBasicCryptoApi();
  @override
  int get maxSyncThread => 1;
}
