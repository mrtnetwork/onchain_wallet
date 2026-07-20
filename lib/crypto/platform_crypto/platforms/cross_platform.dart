import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/credential.dart';

Future<IResult<WalletPlatformCredential?>> createPlatformCredential({
  required String appName,
  required String name,
  required String displayName,
  required String accountId,
  required String reason,
  required IOnChainBridgeInterface platform,
  String? title,
  String? buttonTitle,
}) =>
    throw UnsupportedError(
        'Cannot create a instance without dart:js_interop or dart:io.');

Future<IResult<BiometricResult>> authenticate({
  required WalletPlatformCredential credential,
  required String reason,
  required IOnChainBridgeInterface platform,
  String? title,
  String? buttonTitle,
}) =>
    throw UnsupportedError(
        'Cannot create a instance without dart:js_interop or dart:io.');
