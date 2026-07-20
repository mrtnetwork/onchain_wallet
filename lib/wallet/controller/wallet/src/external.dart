part of 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

/// TODO
/// incomplete
class WalletExternalControllerContext
    extends BaseWalletControllerContext<ViewExternalMasterKey, ExternalWallet> {
  @override
  final Web3StorageManager web3Storage;
  @override
  final WalletStorageManager storage;
  @override
  final String id;
  @override
  final ChainWalletControllerExternal inChainWalletController;
  final WalletConnectionStorageManager connectionStorage;
  WCMSession get session => inChainWalletController.session;
  @override
  late final IWeb3WalletConnectController web3Controller;
  @override
  late final IBridgeClient bridgeController;

  WalletExternalControllerContext({
    required this.storage,
    required this.web3Storage,
    required List<Chain> chains,
    required this.networks,
    required this.inChainWalletController,
    required Chain chain,
    required this.id,
    required ExternalWallet wallet,
    BridgeClientConfig? brdigeConfig,
  })  : _chains = chains.immutable,
        _chain = chain,
        _wallet = wallet,
        connectionStorage =
            WalletConnectionStorageManager(id, inChainWalletController.config.database),
        _status = switch (wallet.requiredPassword) {
          true => WStatus.lock,
          _ => WStatus.readOnly
        } {
    bridgeController = BridgeClientDefault(
      onGetSession: (topic) async {
        if (session.topic == topic) return session;
        return null;
      },
      config: brdigeConfig ??
          BridgeClientConfig(context: inChainWalletController.config.context),
    );
    web3Controller = Web3WalletController(
        sendRequest: _web3WalletConnectRequest,
        authRequest: _getWalletConnectAuth,
        defaultAuth: _getDefaultAuth,
        context: config.context,
        client: bridgeController,
        storage: web3Storage);
  }

  Chain _chain;
  @override
  Chain get chain => _chain;
  List<Chain> _chains;
  @override
  List<Chain> get chains => _chains;
  MemoryWalletEncryptedData? _memoryKey;

  @override
  WalletConfig get config => inChainWalletController.config;
  @override
  bool get hasWalletKey => _memoryKey != null;

  @override
  Map<NetworkType, NetworkController> networks;
  ExternalWallet _wallet;
  @override
  ExternalWallet get wallet => _wallet;
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
    assert(chains.contains(chain));
    if (identical(chain, this.chain)) {
      return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
    }
    _chain = chain;
    return await chain.initAsMainNetwork();
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
          CryptoRequestGenerateMasterKey<ViewExternalMasterKey>.fromStorageWithStringKey(
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
  Future<IResult<void>> updateMasterKey(ViewExternalMasterKey masterKey) async {
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
  Future<IResult<void>> updateWallet(ExternalWallet wallet) async {
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
    bool hasChain = networks[switchChain.network.type]?.hasChain(switchChain) ?? false;
    if (!hasChain) {
      return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
    }
    final currentChain = _chain;
    final result = await setChain(switchChain);
    return result.mapAsync((_) {
      currentChain.disconnectChain();
      updateWallet(wallet.updateNetwork(switchChain.network.value));
      return true;
    });
  }

  Future<IResult<T>> _doAction<T>(WalletActionWallet<T> request) async {
    switch (request) {
      case WalletActionWalletGuarded<T> request:
        final credential = request.credential;
        if (credential != null) {
          validateCredential(credential,
              remove: switch (credential.requestType) {
                WalletCredentialType.accountKey ||
                WalletCredentialType.importedKey ||
                WalletCredentialType.mnemonic ||
                WalletCredentialType.pairingWallet ||
                WalletCredentialType.verify =>
                  false,
                _ => true
              });
        } else if (wallet.protectWallet) {
          throw WalletExceptionConst.authFailed;
        }
        break;
      default:
        break;
    }
    return await request._getResult(this);
  }

  @override
  Future<IResult<T>> doActionInChainRequest<T>(ChainWalletAction<T> request) async {
    throw UnimplementedError();
    // return await _doAction<T>(request);
  }

  @override
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request) async {
    if (!request.event.actionIsAllow(status)) {
      throw WalletExceptionConst.incorrectStatus;
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
      Future<WalletCredentialResponseVerify> getVerifyCred() async {
        return WalletCredentialResponseVerify(UUID.random(), request.credential.type);
      }

      final verify = await getVerifyCred();
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
              memoryWallet: memoryWallet,
              message: WalletRequestReadMnemonic(),
            );
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
      credentials[verify.id] = verify;
      return credential
          .map((e) => WalletInternalCallResponse(result: e.cast<RESPONSE>()));
    });
  }

  @override
  Future<IResult<void>> dispose() async {
    await lock();
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

  // void _onStorageEvent(WCMEventStorage event) {
  // }

  // void _onClientEvents(BridgeEventOnChain internalEvent) {
  //   // switch (internalEvent) {
  //   //   case WCMInternalEventEvent event:
  //   //     Logging.debug(
  //   //         runtime: runtimeType,
  //   //         functionName: "_onClientEvents.event",
  //   //         msg: "new event ${event.request.runtimeType}");
  //   //     switch (event.request) {
  //   //       case WCMEventStorage event:
  //   //         _onStorageEvent(event);
  //   //         controller.sendRequestResponse(
  //   //             request: internalEvent.pairRequest, response: PairResultSuccess([]));
  //   //         break;
  //   //       case WCMEventWalletUpdated():
  //   //         controller.sendRequestResponse(
  //   //             request: internalEvent.pairRequest, response: PairResultSuccess([]));
  //   //         break;
  //   //       case WCMEventWalletUnlocked():
  //   //         controller.sendRequestResponse(
  //   //             request: internalEvent.pairRequest, response: PairResultSuccess([]));
  //   //         break;
  //   //       default:
  //   //         break;
  //   //     }
  //   //     break;
  //   // }
  // }

  @override
  Future<void> lock() async {
    updateWalletStatus();
  }

  @override
  Future<IResult<void>> init() async {
    final result = await chain.initAsMainNetwork();
    return result.andThenAsync((e) async {
      final messages = await connectionStorage.getPendingMessages();
      return messages.andThenAsync((messages) {
        // session.idGenerator.updateState(messages.map((e) => e.correlationId).toList());
        // session = WCMSession(wallet.connection,
        //     idGenerator: BridgeRequestIdGenerator(wallet.connection.clientId,
        //         existsIds: messages.map((e) => e.correlationId).toList()));
        // controller.init(sessions: [session], messages: messages);
        // bridgeController.onChainEvent.listen(_onClientEvents);
        return ResultOk.okVoid;
      });
    });
  }

  void onUnlock() {}
  void onLock() {
    web3Controller.close();
  }
}
