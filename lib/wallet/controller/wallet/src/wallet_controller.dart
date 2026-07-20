part of 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

abstract class BaseWalletControllerContext<ENC extends IViewMasterKey,
    W extends IMainWallet<ENC>> with WalletControllerWeb3Context {
  @override
  IWeb3StorageManager get web3Storage;
  IWalletStorageManager get storage;
  @override
  String get id;
  WalletConfig get config;
  InChainWalletController get inChainWalletController;
  Chain get chain;
  List<Chain> get chains;
  Map<NetworkType, NetworkController> get networks;
  W get wallet;
  WStatus get status;
  bool get isUnlock;
  bool get hasWalletKey;
  @override
  IWeb3WalletConnectController get web3Controller;
  @override
  AppBasicCryptoApi get cryptolib => config.cryptoLib;

  IBridgeClient get bridgeController;
  void setNetwork(NetworkController controller);
  Future<IResult<void>> setChain(Chain chain);
  void removeCredential(WalletCredentialResponseVerify credential);
  IResult<void> validateCredential(WalletCredentialResponseVerify credential,
      {bool remove = true});
  @override
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network);
  void updateWalletStatus();
  CryptoPublicKeyDataWithInfo keyWithWalletName(CryptoPublicKeyDataWithInfo key) {
    final subId = key.index.subId;
    final importedKey = key.index.importedKeyId;
    return key.copyWith(
        importedKeyName: switch (importedKey) {
          null => null,
          _ => wallet.getImportedKey(importedKey)?.name
        },
        walletName: switch (subId) {
          null => wallet.name,
          _ => wallet.getSubWallet(subId)?.name
        });
  }

  CryptoPrivateKeyDataWithInfo privateKeyWithWalletName(
      CryptoPrivateKeyDataWithInfo key) {
    final index = key.index;
    if (index == null) return key;
    final subId = key.index?.subId;
    final importedKey = key.index?.importedKeyId;
    // _walletKey?.hasImportedKey(id)
    return key.copyWith(
        importedKeyName: switch (importedKey) {
          null => null,
          _ => wallet.getImportedKey(importedKey)?.name
        },
        walletName: switch (subId) {
          null => wallet.name,
          _ => wallet.getSubWallet(subId)?.name
        });
  }

  Future<IResult<void>> login({String? password, bool? platformCredential});
  Future<IResult<void>> updateMasterKey(ENC masterKey);
  Future<IResult<void>> updateWallet(W wallet);
  Future<IResult<void>> init();
  Future<void> lock();
  Future<IResult<void>> dispose();
  Future<IResult<T>> onAccessWallet<T extends Object?>(
      Future<IResult<WalletInternalCallResponse<T>>> Function(
              TransfableMemoryWallet memoryWallet, AppBasicCryptoApi crypto)
          fn);
  Future<IResult<bool>> switchNetwork(Chain switchChain);

  Future<IResult<RESPONSE>> createAccess<RESPONSE extends WalletCredentialResponse>(
      WalletActionAccess<RESPONSE> request);
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request);
  Future<IResult<T>> doActionInChainRequest<T>(ChainWalletAction<T> request);
}

class WalletControllerContext
    extends BaseWalletControllerContext<ViewMasterKey, MainWallet>
    with ExternalWalletConnectionsController {
  @override
  final Web3StorageManager web3Storage;
  @override
  final WalletStorageManager storage;
  @override
  final String id;
  @override
  final InChainWalletController inChainWalletController;

  @override
  final WalletConnectionStorageManager connectionsStoage;

  @override
  late final IWeb3WalletConnectController web3Controller;
  @override
  late final IBridgeClient bridgeController;

  WalletControllerContext(
      {required this.storage,
      required this.web3Storage,
      required List<Chain> chains,
      required this.networks,
      required this.inChainWalletController,
      required Chain chain,
      required this.id,
      required MainWallet wallet,
      BridgeClientConfig? brdigeConfig})
      : _chains = chains.immutable,
        connectionsStoage =
            WalletConnectionStorageManager(id, inChainWalletController.config.database),
        _chain = chain,
        _wallet = wallet,
        _status = switch (wallet.requiredPassword) {
          true => WStatus.lock,
          _ => WStatus.readOnly
        } {
    bridgeController = BridgeClientDefault(
        config: brdigeConfig ??
            BridgeClientConfig(context: inChainWalletController.config.context),
        onGetSession: (topic) async => null);
    web3Controller = Web3WalletController(
        sendRequest: _web3WalletConnectRequest,
        authRequest: _getWalletConnectAuth,
        context: config.context,
        defaultAuth: _getDefaultAuth,
        client: bridgeController,
        storage: web3Storage);
  }

  Chain _chain;
  @override
  Chain get chain => _chain;
  List<Chain> _chains;
  @override
  List<Chain> get chains => _chains;

  @override
  WalletConfig get config => inChainWalletController.config;
  MemoryWalletEncryptedData? _memoryKey;
  @override
  bool get hasWalletKey => _memoryKey != null;

  @override
  Map<NetworkType, NetworkController> networks;
  MainWallet _wallet;
  @override
  MainWallet get wallet => _wallet;
  WStatus _status;
  @override
  WStatus get status => _status;
  @override
  bool get isUnlock => status.isUnlock;

  final Map<String, WalletCredentialResponseVerify> credentials = {};

  @override
  void setNetwork(NetworkController controller) {
    networks[controller.type] = controller;
    _chains = networks.values.expand((e) => e.getChains()).toList();
  }

  @override
  void removeCredential(WalletCredentialResponseVerify credential) =>
      credentials.remove(credential.id);

  @override
  IResult<void> validateCredential(WalletCredentialResponseVerify credential,
      {bool remove = true}) {
    if (!credentials.containsKey(credential.id)) {
      return ResultErr.fromException(WalletExceptionConst.authFailed);
    }
    if (remove) removeCredential(credential);
    return ResultOk.okVoid;
  }

  @override
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network) {
    final controller = networks[network];
    if (controller == null) {
      throw WalletExceptionConst.walletIsNotavailable;
    }
    return controller.cast<T>();
  }

  /// update wallet status
  @override
  void updateWalletStatus() {
    if (wallet.requiredPassword) {
      _status = WStatus.lock;
      onLock();
    } else {
      _status = WStatus.readOnly;
    }
    credentials.clear();
  }

  @override
  Future<IResult<void>> setChain(Chain chain) async {
    if (identical(chain, this.chain)) {
      return ResultOk.okVoid;
    }
    final init = await chain.initAsMainNetwork();
    return init.map((_) {
      _chain = chain;
    });
  }

  Future<IResult<List<int>>> getMemoryKey({bool newKey = false}) async {
    if (newKey) {
      final key = QuickCrypto.generateRandom();
      final result = await storage.saveMemoryKey(key);
      return result.map((_) => key);
    }
    final data = await storage.getMemoryKey();
    return data.andThen((e) {
      if (e == null) {
        _memoryKey = null;
        updateWalletStatus();
        return ResultErr.fromException(WalletExceptionConst.authFailed);
      }
      return ResultOk(e);
    });
  }

  @override
  Future<IResult<void>> login({String? password, bool? platformCredential}) async {
    if (platformCredential == true && wallet.platformCredential == null) {
      return ResultErr.fromException(WalletExceptionConst.authFailed);
    }
    if (!hasWalletKey && password == null) {
      return ResultErr.fromException(WalletExceptionConst.authFailed);
    }
    if (password != null) {
      final key = await getMemoryKey(newKey: !hasWalletKey);
      if (key.isErr) return key.cast();
      final request =
          CryptoRequestGenerateMasterKey<ViewMasterKey>.fromStorageWithStringKey(
              storageData: wallet.data,
              key: password,
              checksum: wallet.checkSumBytes,
              memoryKey: key.unwrap());
      final walletKey = await cryptolib.excute(request);
      final result = await walletKey.andThenAsync((walletKey) async {
        return await updateMasterKey(walletKey);
      });
      if (result.isErr) return result.cast();
    } else {
      final pCredential = wallet.platformCredential;
      if (platformCredential != true || pCredential == null) {
        return ResultErr.fromException(WalletExceptionConst.authFailed);
      }
      final auth = await config.context.platformCrypto
          .authenticate(credential: pCredential, reason: APPConst.authenticateReason);
      if (auth.ok() != BiometricResult.success) {
        return ResultErr.fromException(WalletExceptionConst.authFailed);
      }
    }
    if (!_status.isUnlock) {
      _status = WStatus.unlock;
      onUnlock();
    }
    return ResultOk.okVoid;
  }

  @override
  Future<IResult<void>> updateMasterKey(ViewMasterKey masterKey) async {
    final mainWallet = wallet.fromViewKey(masterKey);
    if (mainWallet == wallet && _memoryKey != null) {
      return ResultOk.okVoid;
    }
    final result = await updateWallet(mainWallet);
    return result.map((_) {
      _memoryKey = masterKey.masterKey;
    });
  }

  @override
  Future<IResult<void>> updateWallet(MainWallet wallet) async {
    if (wallet == this.wallet) {
      return ResultOk.okVoid;
    }
    final requiredPassword = this.wallet.requiredPassword;
    final result = await storage.insertMainWallet(wallet);
    return result.map<void>((_) {
      _wallet = wallet;
      if (!requiredPassword && wallet.requiredPassword) {
        updateWalletStatus();
      }
    });
  }

  @override
  Future<IResult<T>> uiActionRequest<T>(WalletUiAction<T> request) {
    return config.uiAction(request);
  }

  @override
  Future<IResult<bool>> switchNetwork(Chain switchChain) async {
    if (_chain == switchChain) {
      return ResultOk(false);
    }
    final currentChain = _chain;
    bool hasChain = networks[switchChain.network.type]?.hasChain(switchChain) ?? false;
    if (!hasChain) {
      return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
    }
    final result = await setChain(switchChain);
    return result.mapAsync((_) {
      updateWallet(wallet.updateNetwork(switchChain.network.value));
      currentChain.disconnectChain();
      return true;
    });
  }

  Future<IResult<T>> _doAction<T>(WalletActionWallet<T> request) async {
    switch (request) {
      case WalletActionWalletGuarded<T> request:
        final credential = request.credential;
        if (credential != null) {
          final isValid = validateCredential(credential,
              remove: switch (credential.requestType) {
                WalletCredentialType.accountKey ||
                WalletCredentialType.importedKey ||
                WalletCredentialType.mnemonic ||
                WalletCredentialType.pairingWallet ||
                WalletCredentialType.verify =>
                  false,
                _ => true
              });
          if (isValid.isErr) return isValid.cast();
        } else if (wallet.protectWallet) {
          return ResultErr.fromException(WalletExceptionConst.authFailed);
        }
        break;
      default:
        break;
    }
    return await request._getResult(this);
  }

  @override
  Future<IResult<T>> doActionInChainRequest<T>(ChainWalletAction<T> request) async {
    final chain = chains.firstWhereOrNull((e) => e.network.value == request.chainId);
    if (chain == null) {
      return ResultErr.fromException(WalletExceptionConst.authFailed);
    }
    if (!hasWalletKey) {
      final result = await uiActionRequest(WalletUiActionChainRequestLogin(chain: chain));
      if (result.isErr && !hasWalletKey) {
        return result.cast();
      }
    }
    if (!hasWalletKey) {
      return ResultErr.fromException(AppExceptionConst.loginRequestRejected);
    }
    return await request._getResult(this);
  }

  @override
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request) async {
    if (!request.event.actionIsAllow(status)) {
      return ResultErr.fromException(WalletExceptionConst.incorrectStatus);
    }
    return _doAction<T>(request);
  }

  @override
  Future<IResult<T>> onAccessWallet<T extends Object?>(
      Future<IResult<WalletInternalCallResponse<T>>> Function(
              TransfableMemoryWallet memoryWallet, AppBasicCryptoApi crypto)
          fn) async {
    final masterKey = _memoryKey;
    final memoryKey = await getMemoryKey();
    return memoryKey.andThenAsync((memoryKey) async {
      if (masterKey == null) {
        return ResultErr.fromException(WalletExceptionConst.walletIsLocked);
      }
      final result = await fn(
          TransfableMemoryWallet(encryptedData: masterKey, memoryKey: memoryKey),
          cryptolib);
      return result.andThenAsync((result) async {
        final key = result.key;
        if (key != null) {
          final result = await updateMasterKey(key.cast());
          if (result.isErr) return result.cast();
        }
        return ResultOk(result.result);
      });
    });
  }

  @override
  Future<IResult<RESPONSE>> createAccess<RESPONSE extends WalletCredentialResponse>(
      WalletActionAccess<RESPONSE> action) async {
    final request = action.request;
    bool isLogin = request.credential.type == WalletCredentialType.login;
    final password = request.password;
    if (!isUnlock || !isLogin) {
      final login = await this
          .login(password: password, platformCredential: request.platformCredential);
      if (login.isErr) return login.cast();
    }
    return await onAccessWallet<RESPONSE>((memoryWallet, crypto) async {
      if (isLogin) {
        return ResultOk(WalletInternalCallResponse<RESPONSE>(
            result: WalletCredentialResponseLogin.instance as RESPONSE));
      }
      WalletCredentialResponseVerify getVerifyCred() {
        return WalletCredentialResponseVerify(UUID.random(), request.credential.type);
      }

      final verify = getVerifyCred();
      IResult<WalletCredentialResponse>? credential;
      switch (request.credential.type) {
        case WalletCredentialType.changePassword:
        case WalletCredentialType.backup:
        case WalletCredentialType.pairingWallet:
          if (password != null) {
            credential = ResultOk(WalletCredentialResponseCredential(
                id: verify, type: request.credential.type));
          }
          break;
        case WalletCredentialType.verify:
          credential = ResultOk(verify);
          break;
        case WalletCredentialType.mnemonic:
          if (password != null) {
            final mnemonic = await crypto.excuteWallet(
                memoryWallet: memoryWallet, message: WalletRequestReadMnemonic());
            credential = mnemonic
                .map((e) => WalletCredentialResponseMnemonic(credential: e, id: verify));
          }
          break;
        case WalletCredentialType.importedKey:
          if (password != null) {
            final keyRequest = request.credential.cast<WalletCredentialImportedKey>();
            final importedKey = await crypto.excuteWallet(
              memoryWallet: memoryWallet,
              message: WalletRequestReadImportedKey(keyRequest.key.id),
            );
            credential = importedKey.map((e) => WalletCredentialResponseImportedKey(
                credential: e, id: verify, keyName: keyRequest.key.name));
          }
          break;
        case WalletCredentialType.accountKey:
          if (password != null) {
            final keyRequest = request.credential.cast<WalletCredentialAccountKey>();
            final account = keyRequest.account;
            final accountKeys = await crypto.excuteWallet(
              memoryWallet: memoryWallet,
              message: WalletRequestReadAccountPrivateKeys(
                  account.createSecretKeyRequest(request: null)),
            );
            credential =
                accountKeys.map((accountKeys) => WalletCredentialResponseAccountKey(
                    credentials: switch (accountKeys) {
                      ReadAccountPrivateKeysResponseDefault() => accountKeys.copyWith(
                          keys: accountKeys.keys.map(privateKeyWithWalletName).toList()),
                      ReadAccountPrivateKeysResponseZcash() => accountKeys.copyWith(
                          keys: accountKeys.keys
                              .map((e) => e.copyWith(
                                  keys: e.keys.map(privateKeyWithWalletName).toList()))
                              .toList()),
                    },
                    id: verify));
          }
          break;
        default:
          break;
      }
      credential ??= ResultErr.fromException(WalletExceptionConst.authFailed);
      return credential.map((e) {
        credentials[verify.id] = verify;
        return WalletInternalCallResponse(result: e.cast<RESPONSE>());
      });
    });
  }

  @override
  Future<IResult<void>> dispose() async {
    await lock();
    await super.dispose();
    _databaseSubscribtion?.cancel();
    _databaseSubscribtion = null;
    _memoryKey = null;
    storage.dispose();
    web3Storage.dispose();
    web3Controller.dispose();
    inChainWalletController.dispose();
    networks.clear();
    _chains = [];
    _status = WStatus.init;
    return ResultOk.okVoid;
  }

  @override
  Future<void> lock() async {
    updateWalletStatus();
  }

  @override
  Future<IResult<void>> init() async {
    return await chain.initAsMainNetwork();
    // return result.andThenAsync((e) async {
    //   return await super.init();
    // });
  }

  void onLock() {
    web3Controller.close();
  }
}

abstract class BaseWalletController {
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request);
  IMainWallet get mainWallet;
  List<Chain> chains();
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network);
  Future<IResult<void>> login({String? password, bool? platformCredential});
  Future<void> init(InitWalletParams params);
  Future<void> dispose();
  Future<void> lock();
  // Future<IResult<void>> initBackground(String id);
}

class WalletController extends BaseWalletController {
  final WalletConfig config;
  WalletController(this.config);

  final _lock = SafeAtomicLock();
  BaseWalletControllerContext? _contextNullable;
  BaseWalletControllerContext get _context {
    final context = _contextNullable;
    if (context == null) {
      throw WalletExceptionConst.walletIsNotavailable;
    }
    return context;
  }

  IWeb3WalletConnectController get walletConnect => _context.web3Controller;
  WStatus get status => _contextNullable?.status ?? WStatus.init;
  bool get hasWalletKey => _contextNullable?.hasWalletKey ?? false;
  @override
  List<Chain> chains() {
    return _contextNullable?.chains ?? [];
  }

  Chain get chain => _context.chain;

  @override
  Future<IResult<void>> dispose() async {
    return await _lock.run(() async {
      final controller = _contextNullable;
      _contextNullable = null;
      controller?.dispose();
      return ResultOk(null);
    });
  }

  @override
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request) {
    return _context.doRequest<T>(request);
  }

  static ({
    Map<NetworkType, List<Chain>> accounts,
    List<Chain> newAccounts,
    List<Chain> allAccounts,
  }) getAllNetworksAccounts(
      List<Chain> chains, InChainWalletController controller, String id) {
    final Map<int, Chain> toMap = {for (final i in chains) i.network.value: i};
    List<Chain> newChains = [];
    for (final i in ChainConst.defaultCoins.keys) {
      if (toMap.containsKey(i)) {
        continue;
      }
      final network = ChainConst.defaultCoins[i]!;
      final chain = Chain.setup(network: network, id: id, controller: controller);
      newChains.add(chain);
      toMap.addAll({chain.network.value: chain});
    }
    final allChains = toMap.values.toList();
    final withNetworkType = Map<NetworkType, List<Chain>>.fromEntries(NetworkType.values
        .map((t) => MapEntry(t, allChains.where((e) => e.network.type == t).toList()))
        .toList());
    return (accounts: withNetworkType, newAccounts: newChains, allAccounts: allChains);
  }

  @override
  Future<IResult<IMainWallet>> init(InitWalletParams params) {
    return _lock.run(() async {
      if (_contextNullable != null) {
        return ResultErr.fromException(WalletExceptionConst.walletAlreadyInitialized);
      }
      final id = params.id;
      final storage = WalletStorageManager(id, config.database);
      final web3Storage = Web3StorageManager(id, config.database);
      final mainWallet = await storage.mainWallet();
      return mainWallet.andThenAsync((mainWallet) async {
        if (mainWallet == null) {
          return ResultErr.fromException(WalletExceptionConst.walletDoesNotExists);
        }
        final InChainWalletController controller = switch (mainWallet) {
          MainWallet() => ChainWalletControllerDefault(
              actionCallBack: <T>(request) async {
                return await _context.doActionInChainRequest<T>(request);
              },
              bridgeControllerCallback: () => _context.bridgeController,
              config: config,
              wallet: mainWallet),
          ExternalWallet(:final connection) => ChainWalletControllerExternal(
              actionCallBack: <T>(request) async {
                return await _context.doActionInChainRequest<T>(request);
              },
              bridgeControllerCallback: () => _context.bridgeController,
              config: config,
              wallet: mainWallet,
              session: WCMSession(connection)),
        };
        final accounts = await storage.readAccounts(controller);
        return accounts.andThenAsync((accounts) async {
          final allAccounts = getAllNetworksAccounts(accounts, controller, id);
          final result = await IResult.anyError([
            ...allAccounts.newAccounts.map((e) => e.setupAccount()),
            if (params.isBackup) ...accounts.map((e) => e.verifyBackup())
          ]);
          return result.andThenAsync(
            (_) async {
              final result = await IResult.anyError(
                  allAccounts.allAccounts.map((e) => e.init()).toList());
              return result.andThenAsync((value) async {
                final networks = allAccounts.accounts.map(
                  (key, value) => MapEntry(
                      key,
                      NetworkController.fromChains(
                          type: key, chains: value, id: id, database: config.database)),
                );
                final chains = allAccounts.allAccounts;
                final chain = allAccounts.allAccounts.firstWhereNullable(
                      (e) => e.network.value == mainWallet.network,
                    ) ??
                    chains.first;
                final BaseWalletControllerContext context = switch (mainWallet) {
                  ExternalWallet wallet => WalletExternalControllerContext(
                      storage: storage,
                      web3Storage: web3Storage,
                      chains: chains,
                      networks: networks,
                      inChainWalletController:
                          controller as ChainWalletControllerExternal,
                      chain: chain,
                      id: id,
                      wallet: wallet),
                  MainWallet wallet => WalletControllerContext(
                      storage: storage,
                      web3Storage: web3Storage,
                      chains: chains,
                      networks: networks,
                      inChainWalletController: controller,
                      chain: chain,
                      id: id,
                      wallet: wallet),
                };
                final init = await context.init();
                return init.map((_) {
                  _contextNullable = context;
                  return mainWallet;
                });
              });
            },
          );
        });
      });
    });
  }

  @override
  Future<void> lock() async {
    await _contextNullable?.lock();
  }

  @override
  Future<IResult<void>> login({String? password, bool? platformCredential}) {
    return _context.login(password: password, platformCredential: platformCredential);
  }

  @override
  IMainWallet get mainWallet => _context.wallet;

  @override
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network) {
    return _context.networkController<T>(network);
  }
}
