import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';

import 'cross_platform.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.io) 'native.dart' as c;

class DefaultPlatformCryptoApi implements IPlatformCryptoApi {
  final IOnChainBridgeInterface platform;
  const DefaultPlatformCryptoApi(this.platform);
  @override
  Future<IResult<WalletPlatformCredential?>> createPlatformCredential({
    required String appName,
    required String name,
    required String displayName,
    required String accountId,
    String? title,
    String? buttonTitle,
    required String reason,
  }) {
    return c.createPlatformCredential(
        appName: name,
        accountId: accountId,
        displayName: displayName,
        name: name,
        reason: reason,
        buttonTitle: buttonTitle,
        title: title,
        platform: platform);
  }

  @override
  Future<IResult<TouchIdStatus>> touchIdStatus() async {
    final result = await platform.touchIdStatus();
    return result.toResult();
  }

  @override
  Future<IResult<bool>> supportPlatformCredential() async {
    final status = await touchIdStatus();
    return status.map((status) => status == TouchIdStatus.available);
  }

  @override
  Future<IResult<BiometricResult>> authenticate({
    required WalletPlatformCredential credential,
    required String reason,
    String? title,
    String? buttonTitle,
  }) {
    return c.authenticate(
        credential: credential,
        reason: reason,
        title: title,
        buttonTitle: buttonTitle,
        platform: platform);
  }
}
