import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_private_key.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

enum WalletCredentialType {
  login,
  verify,
  accountKey(allowPlatformCredential: false),
  importedKey(allowPlatformCredential: false),
  mnemonic(allowPlatformCredential: false),
  backup(allowPlatformCredential: false),
  changePassword(allowPlatformCredential: false),
  pairingWallet(allowPlatformCredential: false);

  final bool allowPlatformCredential;
  const WalletCredentialType({this.allowPlatformCredential = true});
  bool get isLogin => this == login;
}

sealed class WalletCredentialResponse {
  final WalletCredentialType type;
  WalletCredentialResponseVerify? get verificationId;
  const WalletCredentialResponse({required this.type});
  T cast<T extends WalletCredentialResponse>() {
    if (this is! T) {
      throw AppInternalError.internalError("WalletCredentialResponse");
    }
    return this as T;
  }
}

final class WalletCredentialResponseLogin extends WalletCredentialResponse {
  const WalletCredentialResponseLogin._() : super(type: WalletCredentialType.login);
  static const WalletCredentialResponseLogin instance = WalletCredentialResponseLogin._();

  @override
  WalletCredentialResponseVerify? get verificationId => null;
}

final class WalletCredentialResponseMnemonic extends WalletCredentialResponse {
  final AccessMnemonicResponse credential;
  final WalletCredentialResponseVerify id;
  const WalletCredentialResponseMnemonic({required this.credential, required this.id})
      : super(type: WalletCredentialType.mnemonic);

  @override
  WalletCredentialResponseVerify? get verificationId => id;
}

final class WalletCredentialResponseVerify extends WalletCredentialResponse {
  final String id;
  final WalletCredentialType requestType;
  const WalletCredentialResponseVerify(this.id, this.requestType)
      : super(type: WalletCredentialType.verify);
  @override
  WalletCredentialResponseVerify? get verificationId => this;
}

final class WalletCredentialResponseCredential extends WalletCredentialResponse {
  final WalletCredentialResponseVerify id;
  const WalletCredentialResponseCredential({required this.id, required super.type});
  @override
  WalletCredentialResponseVerify? get verificationId => id;
}

final class WalletCredentialResponseAccountKey extends WalletCredentialResponse {
  final ReadAccountPrivateKeysResponse credentials;
  final WalletCredentialResponseVerify id;
  @override
  WalletCredentialResponseVerify? get verificationId => id;
  WalletCredentialResponseAccountKey({required this.credentials, required this.id})
      : super(type: WalletCredentialType.accountKey);
}

final class WalletCredentialResponseImportedKey extends WalletCredentialResponse {
  final CryptoPrivateKeyDataWithInfo credential;
  final String? keyName;
  final WalletCredentialResponseVerify id;
  @override
  WalletCredentialResponseVerify? get verificationId => id;
  WalletCredentialResponseImportedKey(
      {required this.credential, required this.id, required this.keyName})
      : super(type: WalletCredentialType.importedKey);
}

abstract final class WalletCredential<RESPONSE extends Object?> {
  final WalletCredentialType type;
  const WalletCredential({required this.type});

  T cast<T extends WalletCredential>() {
    if (this is! T) {
      throw AppInternalError.internalError("WalletCredential");
    }
    return this as T;
  }
}

final class WalletCredentialRequest<RESPONSE extends WalletCredentialResponse> {
  final WalletCredential<RESPONSE> credential;
  final String? password;
  final bool? platformCredential;
  const WalletCredentialRequest(
      {required this.credential, this.password, this.platformCredential});
  static const login = WalletCredentialRequest(credential: WalletCredentialLogin._());
}

final class WalletCredentialLogin
    extends WalletCredential<WalletCredentialResponseLogin> {
  const WalletCredentialLogin._() : super(type: WalletCredentialType.login);
  static const WalletCredentialLogin instance = WalletCredentialLogin._();
}

final class WalletCredentialAccountKey
    extends WalletCredential<WalletCredentialResponseAccountKey> {
  final ChainAccount account;
  const WalletCredentialAccountKey({required this.account})
      : super(type: WalletCredentialType.accountKey);
}

final class WalletCredentialImportedKey
    extends WalletCredential<WalletCredentialResponseImportedKey> {
  final ViewImportedSecretKey key;
  const WalletCredentialImportedKey({required this.key})
      : super(type: WalletCredentialType.importedKey);
}

final class WalletCredentialMnemonic
    extends WalletCredential<WalletCredentialResponseMnemonic> {
  const WalletCredentialMnemonic() : super(type: WalletCredentialType.mnemonic);
}

final class WalletCredentialPasswordRequire
    extends WalletCredential<WalletCredentialResponseCredential> {
  const WalletCredentialPasswordRequire({required super.type});
}

final class WalletCredentialVerify
    extends WalletCredential<WalletCredentialResponseVerify> {
  const WalletCredentialVerify() : super(type: WalletCredentialType.verify);
}
