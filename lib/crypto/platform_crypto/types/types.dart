import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class AppPlatformCredentialAutneticateWebRequest
    extends PlatformCredentialAutneticateWebRequest {
  final List<int> pubKeyRawBytes;
  AppPlatformCredentialAutneticateWebRequest(
      {required super.id,
      required super.reason,
      required super.challange,
      super.title,
      super.buttonTitle,
      required List<int> pubKeyRawBytes})
      : pubKeyRawBytes = pubKeyRawBytes.asImmutableBytes;

  @override
  Future<Result<BiometricResult, IException>> verify(
      InternalPublicKeyWebAuthResponse response) async {
    try {
      final verify = CryptoKeyUtils.validateWebAuthSecp256p1DerSignature(
          authenticatorData: response.authenticatorData,
          clientDataJSON: response.clientDataJSON,
          signature: response.signature,
          pubKeyBytes: pubKeyRawBytes);
      return Ok(verify ? BiometricResult.success : BiometricResult.failed);
    } on ArgumentException {
      return Ok(BiometricResult.failed);
    }
  }
}
