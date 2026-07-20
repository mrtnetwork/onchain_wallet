import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';

abstract class IPlatformCryptoApi {
  Future<IResult<WalletPlatformCredential?>> createPlatformCredential({
    required String appName,
    required String name,
    required String displayName,
    required String accountId,
    String? title,
    String? buttonTitle,
    required String reason,
  });
  Future<IResult<TouchIdStatus>> touchIdStatus();
  Future<IResult<bool>> supportPlatformCredential();
  Future<IResult<BiometricResult>> authenticate({
    required WalletPlatformCredential credential,
    required String reason,
    String? title,
    String? buttonTitle,
  });
}

class DisabledPlatformCryptoApi implements IPlatformCryptoApi {
  @override
  Future<IResult<BiometricResult>> authenticate(
      {required WalletPlatformCredential credential,
      required String reason,
      String? title,
      String? buttonTitle}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<WalletPlatformCredential?>> createPlatformCredential(
      {required String appName,
      required String name,
      required String displayName,
      required String accountId,
      String? title,
      String? buttonTitle,
      required String reason}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<bool>> supportPlatformCredential() async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<TouchIdStatus>> touchIdStatus() async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}
