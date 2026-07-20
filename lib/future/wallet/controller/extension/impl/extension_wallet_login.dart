import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/controller/extension/models/models.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/cached_wallet_password.dart';

class ExtensionWalletLoginController {
  final lock = SafeAtomicLock();
  DateTime? _latest;
  bool _hasKey = false;
  IResult<StorageArea> getStorageSession() {
    final ext = extensionOrNull;
    if (ext == null) {
      return ResultErr.fromException(AppExceptionConst.missingChromeApi);
    }
    return ResultOk(ext.storage.session);
  }

  void onWalletIntraction() {
    final latestimeout = _latest;
    if (!_hasKey || latestimeout == null) return;
    if (latestimeout.isAfterNow) return;
    final latest = DateTime.now();
    _latest = latest.add(const Duration(minutes: 1));
    lock.run(() async {
      await getStorageSession().mapAsync((storage) async {
        storage.setStorage_(
            ExtentionSessionStorageConst.expireKey, latest.secondsSinceEpoch.toString());
      });
    });
  }

  Future<IResult<void>> _clearLoginHistory() async {
    final storage = getStorageSession();
    return storage.mapAsync((storage) async {
      await storage.removeMultiple_([
        ExtentionSessionStorageConst.history,
        ExtentionSessionStorageConst.key,
        ExtentionSessionStorageConst.expireKey
      ]);
    });
  }

  Future<IResult<void>> clearLoginHistory() async {
    return lock.run(() async {
      _hasKey = false;
      _latest = null;
      return await _clearLoginHistory();
    });
  }

  Future<IResult<DateTime>> _saveLoginHistory(String key) async {
    final storage = getStorageSession();
    return storage.mapAsync((storage) async {
      final latest = DateTime.now();
      final walletKey = ExtentionWalletKey(key);
      final encryptionKey = ExtentionKey.generate();
      final encrypt = encryptionKey.encrypt(walletKey);
      await storage.setMultipleStorage_({
        ExtentionSessionStorageConst.key: encryptionKey.toCbor().toCborHex(),
        ExtentionSessionStorageConst.history: encrypt,
        ExtentionSessionStorageConst.expireKey: latest.secondsSinceEpoch.toString(),
      });
      return latest;
    });
  }

  Future<IResult<DateTime>> saveLoginHistory(String key) {
    return lock.run(() async {
      final result = await _saveLoginHistory(key);
      return result.map((timeout) {
        _latest = timeout.add(const Duration(minutes: 1));
        _hasKey = true;
        return timeout;
      });
    });
  }

  Future<IResult<CachedWalletPassword>> _getLoginHistory() async {
    final keys = await getStorageSession().mapCatchAsync((storage) async {
      return await storage.getMultipleStorage_([
        ExtentionSessionStorageConst.key,
        ExtentionSessionStorageConst.history,
        ExtentionSessionStorageConst.expireKey
      ]);
    });
    return keys.andThenAsync((keys) async {
      final expireSeconds = keys[ExtentionSessionStorageConst.expireKey];
      final cKey = keys[ExtentionSessionStorageConst.key];
      final password = keys[ExtentionSessionStorageConst.history];
      if (expireSeconds == null || cKey == null || password == null) {
        return ResultErr.fromException(WalletExceptionConst.authFailed);
      }
      final cachedTime = DateTimeUtils.fromSecondsSinceEpoch(int.parse(expireSeconds));
      if (cachedTime.isAfterNow) {
        return ResultErr.fromException(WalletExceptionConst.authFailed);
      }
      final extKey = ExtentionKey.deserialize(hex: cKey);
      final decrypt = extKey.decrypt(password);
      if (decrypt == null) {
        return ResultErr.fromException(WalletExceptionConst.authFailed);
      }
      return ResultOk(CachedWalletPassword(password: password, cachedTime: cachedTime));
    });
  }

  Future<CachedWalletPassword?> getLoginHistory() async {
    return lock.run(() async {
      final logingHisotry = await _getLoginHistory();
      return logingHisotry.mapErr((e) {
        clearLoginHistory();
        return e.exception;
      }).map<CachedWalletPassword?>((e) {
        _hasKey = true;
        _latest = e.cachedTime;
        return e;
      }).unwrapOr((err) => null);
    });
  }
}
