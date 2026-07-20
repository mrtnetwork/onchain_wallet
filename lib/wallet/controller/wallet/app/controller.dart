part of 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class AppWalletControllerContext {
  final WalletConfig config;

  HDWalletsKeys hdWallets = HDWalletsKeys();
  AppWalletControllerContext(this.config)
      : storage = AppWalletStorageManager(config.database);
  final AppWalletStorageManager storage;
  final lock = SafeAtomicLock();
  late WalletController controller = WalletController(config);
  AppBasicCryptoApi get cryptolib => config.cryptoLib;
  IMainWallet get wallet => controller.mainWallet;
  Chain get currentChain => controller.chain;
  StreamValue<WalletEvent> get status => emitter;
  final StreamValue<WalletEvent> emitter =
      StreamValue(WalletActionEvent.init(), name: "AppWalletControllerContext");
  List<HdWalletKey> get wallets => hdWallets.wallets.toList();
  IWeb3WalletConnectController get walletConnect => controller.walletConnect;
  WStatus get homePageStatus => status.value.walletStatus;

  WalletActionEvent buildEvent(
      {required WalletActionEventType action, required WalletActionEventStatus status}) {
    final wStatus = controller.status.isInit ? WStatus.setup : controller.status;
    return WalletActionEvent(walletStatus: wStatus, action: action, status: status);
  }

  void onEventSuccess(WalletActionEvent event) {
    switch (event.action) {
      case WalletActionEventType.updateWallet:
        if (hdWallets.updateWallet(wallet.tokey())) {
          saveHdWallet();
        }
        break;
      default:
        break;
    }
  }

  void emitStatus(WalletActionEvent event) {
    if (event.status.isSuccess) {
      onEventSuccess(event);
    }
    if (!event.action.allowNotify) return;
    emitter.value = event;
    Logging.debug(
      fn: () =>
          AppLogData(runtime: runtimeType, function: "event", msg: event.toString()),
    );
  }

  Future<IResult<IMainWallet?>> startWallet({InitWalletParams? params}) async {
    final currentController = controller;
    if (hdWallets.hasWallet) {
      final initalizeWallet = hdWallets.getInitializeWallet(key: params?.id);
      if (initalizeWallet == null) {
        return ResultErr.fromException(WalletExceptionConst.incompleteWalletSetup);
      }
      if (params != null && initalizeWallet.key != params.id) {
        return ResultErr.fromException(WalletExceptionConst.incompleteWalletSetup);
      }
      final controller = WalletController(config);
      final result =
          await controller.init(params ?? InitWalletParams(id: initalizeWallet.key));
      if (result.isErr) return result.cast();
      this.controller = controller;
      return result.andThenAsync((w) async {
        final dispose = await currentController.dispose();
        return dispose.map((e) => w);
      });
    }
    final dispose = await currentController.dispose();
    return dispose.map((_) => null);
  }

  Future<IResult<void>> init({CachedWalletPassword? initialPassword}) async {
    if (!homePageStatus.isSetup) {
      return ResultErr.fromException(WalletExceptionConst.walletAlreadyInitialized);
    }
    final hdWallets = await storage.readWallet();
    return hdWallets.andThenAsync((hdWallets) async {
      this.hdWallets = hdWallets;
      final start = await startWallet();
      return start.mapAsync((wallet) async {
        if (wallet != null &&
            initialPassword != null &&
            initialPassword.cachedTime
                .add(Duration(seconds: wallet.locktime.value))
                .isAfterNow) {
          await controller.login(password: initialPassword.password);
        }
      });
    });
  }

  Future<void> removeWallet() async {
    final controller = this.controller;
    hdWallets.removeWallet(controller.mainWallet);
    await startWallet();
    await saveHdWallet();
  }

  Future<IResult<void>> saveHdWallet() async {
    return await storage.saveHdWalletKeys(hdWallets);
  }
}

abstract class AppWalletController extends BaseAppWalletController {
  late final AppWalletControllerContext _context = AppWalletControllerContext(config);
  @override
  IMainWallet get wallet => _context.wallet;

  Chain get currentChain => _context.controller.chain;
  @override
  StreamValue<WalletEvent> get status => _context.status;
  @override
  WalletEvent get latestEvent => _context.status.value;
  @override
  WStatus get homePageStatus => _context.status.value.walletStatus;
  @override
  List<HdWalletKey> get wallets => _context.wallets;
  @override
  IWeb3WalletConnectController get walletConnect => _context.walletConnect;

  @override
  bool get isOpen => homePageStatus.isOpen;
  @override
  bool get isLock => homePageStatus.isLock;
  @override
  bool get isUnlock => homePageStatus.isUnlock;
  @override
  bool get isReadOnly => homePageStatus.isReadOnly;
  @override
  bool get isReady => homePageStatus.isReady;
  @override
  bool get isSetup => homePageStatus.isSetup;
  WalletNetwork get network => currentChain.network;
  int get tick => _timeout.tick;
  bool get hasWalletKey => _context.controller.hasWalletKey;

  @override
  List<T> getChains<T extends APPCHAIN>() {
    return _context.controller.chains().whereType<T>().toList();
  }

  @override
  T? chainController<T extends APPNETWORKCONTROLLER>(NetworkType type) {
    if (isOpen) {
      return _context.controller.networkController<T>(type);
    }
    return null;
  }

  late final WalletTimeoutController _timeout = WalletTimeoutController(
    onTimeout: lock,
    isUnlock: () => isUnlock,
    locktime: () => _context.wallet.locktime,
    onTick: (tick) {
      _context.emitter.notify(value: WalletTimeoutEvent(tick));
    },
  );
  void onWalletIntraction() {
    _timeout.reset();
  }

  @override
  Future<IResult<T>> doAction<T>(
    WalletAction<T> action, {
    Duration? delay = APPConst.animationDuraion,
  }) async {
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType, function: "doAction", msg: action.event.name));
    return await _context.lock.run(() async {
      bool isUnlock = this.isUnlock;
      final request = action.event;
      final event =
          _context.buildEvent(action: request, status: WalletActionEventStatus.pending);
      _context.emitStatus(event);
      IResult<T>? result;
      try {
        onWalletIntraction();
        if (!event.actionIsAllow()) {
          return ResultErr.fromException(WalletExceptionConst.incorrectStatus);
        }
        if (event.inProgress) {
          await Future.delayed(APPConst.animationDuraion);
        }
        result = await _doRequest<T>(action);
        return result;
      } finally {
        final status = (result?.isErr ?? true)
            ? WalletActionEventStatus.failed
            : WalletActionEventStatus.success;

        final event = _context.buildEvent(action: request, status: status);
        _context.emitStatus(event);
        if (!isUnlock && this.isUnlock) {
          _timeout.login();
        } else if (!this.isUnlock) {
          _timeout.logout();
        }
        onWalletIntraction();
      }
    }, lockId: action.syncId);
  }

  Future<IResult<T>> _doRequest<T extends Object?>(WalletAction<T> request) async {
    switch (request) {
      case WalletActionApp<T> request:
        return await IResult.block<T>(
          () async => await request._getResult(_context),
          onError: (exception, trace) => AppLogData(
              runtime: runtimeType,
              msg: "Action request error.",
              function: "_doRequest",
              err: exception,
              trace: trace.toString()),
        );
      case WalletActionRemoveWallet request:
        final result =
            await _context.controller.doRequest<T>(request as WalletActionWallet<T>);
        if (result.isOk) {
          if (request case WalletActionRemoveWallet()) {
            await _context.removeWallet();
          }
        }
        return result;
      case WalletActionWallet<T> request:
        return await _context.controller.doRequest<T>(request);
    }
  }

  @override
  Future<void> lock() async {
    await doAction(WalletActionLock(), delay: null);
  }
}
