import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';

Future<IResult<WalletPlatformCredentialIo?>> createPlatformCredential({
  required String appName,
  required String name,
  required String displayName,
  required String accountId,
  required String reason,
  required IOnChainBridgeInterface platform,
  String? title,
  String? buttonTitle,
}) async {
  final credential = await platform.createPlatformCredential(PlatformCredentialRequest(
      name: name,
      appName: appName,
      displayName: displayName,
      accountId: accountId.codeUnits,
      reason: reason));
  return credential.toResult().map((result) {
    if (result == null) return null;
    return WalletPlatformCredentialIo();
  });
}

Future<IResult<BiometricResult>> authenticate({
  required WalletPlatformCredential credential,
  required String reason,
  required IOnChainBridgeInterface platform,
  String? title,
  String? buttonTitle,
}) async {
  if (credential.type != WalletPlatformCredentialType.localAuth) {
    return ResultErr.fromException(AppInternalError.internalError("Authenticate"));
  }
  final result = await platform.authenticate(PlatformCredentialAutneticateIoRequest(
      reason: reason, title: title, buttonTitle: buttonTitle));
  return result.toResult();
}
