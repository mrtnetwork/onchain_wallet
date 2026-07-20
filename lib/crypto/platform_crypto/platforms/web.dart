import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_bridge/web/interface/interface.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/types/types.dart';

Future<IResult<WalletPlatformCredentialWeb?>> createPlatformCredential({
  required String appName,
  required String name,
  required String displayName,
  required String accountId,
  required String reason,
  required IOnChainBridgeInterface platform,
  String? title,
  String? buttonTitle,
}) async {
  if (platform is! IWebOnChainBridgeInterface) {
    return ResultErr.fromException(AppInternalError.internalError(
        "createPlatformCredential",
        reason: "Unexpected web platform interface."));
  }
  final credential = await platform.createPlatformCredential(PlatformCredentialRequest(
      name: name,
      appName: appName,
      displayName: displayName,
      accountId: QuickCrypto.sha256Hash(StringUtils.encode(accountId)),
      reason: reason));
  return credential.toResult().andThen((credential) {
    if (credential == null) return ResultOk(null);
    final id = StringUtils.tryEncode(credential.id,
        allowUrlSafe: true,
        encoding: StringEncoding.base64UrlSafe,
        validateB64Padding: false);
    final pkBytes =
        CryptoKeyUtils.tryDecodeWebAuthPublicKeyCredential(credential.publicKey);
    if (id == null || pkBytes == null) {
      return ResultErr.fromException(AppCryptoExceptionConst.invalidCredential);
    }
    return ResultOk(WalletPlatformCredentialWeb(id: id, publicKey: pkBytes));
  });
}

Future<IResult<BiometricResult>> authenticate({
  required WalletPlatformCredential credential,
  required String reason,
  required IOnChainBridgeInterface platform,
  String? title,
  String? buttonTitle,
}) async {
  if (credential.type != WalletPlatformCredentialType.webAuth) {
    return ResultErr.fromException(AppInternalError.internalError("Authenticate"));
  }
  final webCredential = credential as WalletPlatformCredentialWeb;
  final request = AppPlatformCredentialAutneticateWebRequest(
    id: webCredential.id,
    reason: reason,
    challange: QuickCrypto.generateRandom(),
    pubKeyRawBytes: webCredential.publicKey,
    title: title,
    buttonTitle: buttonTitle,
  );
  final result = await platform.authenticate(request);
  return result.toResult();
}
