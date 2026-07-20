import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

enum WalletActionAccessLevel {
  unlock,
  readOnly,
  none;

  bool actionIsAllow(WStatus status) {
    if (this == unlock) {
      return status.isUnlock;
    }
    if (this == readOnly) {
      return status.isOpen;
    }
    return status.isReady;
  }
}

enum WStatus {
  init(0),
  setup(1),
  lock(2),
  readOnly(3),
  unlock(4);

  final int value;
  const WStatus(this.value);
  static WStatus fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("WStatus"));
  }

  bool get isInit => this == init;
  bool get isSetup => this == setup;
  bool get isOpen => this == unlock || this == readOnly;
  bool get isLock => this == lock;
  bool get isUnlock => this == unlock;

  bool get isReadOnly => this == readOnly;
  bool get isReady => this != setup && this != init;
}

enum WalletActionEventType {
  init(rebuild: true, accessLevel: null),
  setup(rebuild: true, accessLevel: null),
  lock(rebuild: true, accessLevel: WalletActionAccessLevel.none),
  lockingTimeout(allowNotify: false, accessLevel: null),
  cryptoRequest(allowNotify: false, accessLevel: null),
  decryptWalletBackup(allowNotify: false, accessLevel: null),
  createWallet(allowNotify: false, accessLevel: null),
  verifyWalletBackup(allowNotify: false, accessLevel: null),
  switchWallet(rebuild: true, accessLevel: null),

  importSubWallet(rebuild: true, accessLevel: WalletActionAccessLevel.unlock),
  web3Request(accessLevel: WalletActionAccessLevel.none),
  web3Auth(accessLevel: WalletActionAccessLevel.none),
  updateWeb3Auth(accessLevel: WalletActionAccessLevel.unlock),
  walletRequest(accessLevel: WalletActionAccessLevel.unlock),
  changePassword(rebuild: true, accessLevel: WalletActionAccessLevel.unlock),
  deriveAddress(accessLevel: WalletActionAccessLevel.unlock),
  importKey(accessLevel: WalletActionAccessLevel.unlock),

  switchNetwork(rebuild: true, accessLevel: WalletActionAccessLevel.readOnly),
  // exportKey(),
  viewImportedKeys(accessLevel: WalletActionAccessLevel.unlock),
  removeKey(accessLevel: WalletActionAccessLevel.unlock),
  updateAccount(rebuild: true, accessLevel: WalletActionAccessLevel.readOnly),
  importNetwork(rebuild: true, accessLevel: WalletActionAccessLevel.readOnly),
  removeAccount(rebuild: true, accessLevel: WalletActionAccessLevel.readOnly),
  backup(accessLevel: WalletActionAccessLevel.unlock),
  backupWallet(accessLevel: WalletActionAccessLevel.unlock),
  removeWallet(rebuild: true, accessLevel: WalletActionAccessLevel.unlock),
  removeSubWallet(rebuild: true, accessLevel: WalletActionAccessLevel.unlock),
  updateWallet(rebuild: true, accessLevel: WalletActionAccessLevel.unlock),
  // accessKey(),
  login(rebuild: true, accessLevel: WalletActionAccessLevel.none),
  importExternalWallet(accessLevel: WalletActionAccessLevel.unlock),
  exportAccountKey(accessLevel: WalletActionAccessLevel.unlock),
  removeCredential(allowNotify: false, accessLevel: WalletActionAccessLevel.none),

  ///
  ;

  final bool rebuild;
  final bool allowNotify;
  final WalletActionAccessLevel? accessLevel;
  bool get isLogin => this == login;
  bool get isLockingTimeout => this == lockingTimeout;
  const WalletActionEventType(
      {this.rebuild = false, this.allowNotify = true, required this.accessLevel});

  bool actionIsAllow(WStatus status) {
    switch (this) {
      case WalletActionEventType.setup:
        return !status.isInit;
      case WalletActionEventType.web3Request:
      case WalletActionEventType.web3Auth:
      case WalletActionEventType.switchWallet:
      case WalletActionEventType.login:
        return status.isReady;
      case WalletActionEventType.walletRequest:
      case WalletActionEventType.updateWallet:
      case WalletActionEventType.updateWeb3Auth:
      case WalletActionEventType.changePassword:
      case WalletActionEventType.removeKey:
      case WalletActionEventType.importKey:
      case WalletActionEventType.exportAccountKey:
      case WalletActionEventType.backupWallet:
      case WalletActionEventType.removeWallet:
      case WalletActionEventType.importSubWallet:
      case WalletActionEventType.removeSubWallet:
      case WalletActionEventType.deriveAddress:
      case WalletActionEventType.viewImportedKeys:
      case WalletActionEventType.importExternalWallet:
      case WalletActionEventType.backup:
        return status.isUnlock;
      case WalletActionEventType.switchNetwork:
      case WalletActionEventType.updateAccount:
      case WalletActionEventType.importNetwork:
      case WalletActionEventType.removeAccount:
      case WalletActionEventType.lock:
        return status.isOpen;
      case WalletActionEventType.init:
        return status.isSetup;
      case WalletActionEventType.lockingTimeout:
        return false;
      case WalletActionEventType.removeCredential:
      case WalletActionEventType.cryptoRequest:
      case WalletActionEventType.decryptWalletBackup:
      case WalletActionEventType.createWallet:
      case WalletActionEventType.verifyWalletBackup:
        return true;
    }
  }
}

enum WalletActionEventStatus {
  pending(inProgress: true),
  success,
  failed;

  final bool inProgress;
  const WalletActionEventStatus({this.inProgress = false});
  bool get isSuccess => this == success;
}

sealed class WalletEvent with Equality {
  final WStatus walletStatus;
  final WalletActionEventType action;
  final WalletActionEventStatus status;
  final bool inProgress;
  WalletEvent({required this.walletStatus, required this.action, required this.status})
      : inProgress = action.rebuild && status.inProgress;
  @override
  List get variables => [walletStatus, action, status];
}

final class WalletActionEvent extends WalletEvent {
  factory WalletActionEvent.init() {
    return WalletActionEvent(
        walletStatus: WStatus.init,
        action: WalletActionEventType.init,
        status: WalletActionEventStatus.success);
  }
  WalletActionEvent(
      {required super.walletStatus, required super.action, required super.status});

  bool actionIsAllow() {
    return action.actionIsAllow(walletStatus);
  }

  @override
  String toString() {
    return "{action:${action.name}, wallet_status:${walletStatus.name}}";
  }

  @override
  List get variables => [walletStatus, action, status];
}

final class WalletTimeoutEvent extends WalletEvent {
  final int? timeout;
  factory WalletTimeoutEvent(int? timeout) {
    return WalletTimeoutEvent._(
        walletStatus: WStatus.unlock,
        action: WalletActionEventType.lockingTimeout,
        status: WalletActionEventStatus.success,
        timeout: timeout);
  }
  WalletTimeoutEvent._(
      {required super.walletStatus,
      required super.action,
      required super.status,
      required this.timeout});
}

final class WalletInternalCallResponse<T extends Object?> {
  final T result;
  final IViewMasterKey? key;
  const WalletInternalCallResponse({required this.result, this.key});
}
