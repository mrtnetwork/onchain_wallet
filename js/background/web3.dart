part of './background.dart';

mixin JSExtensionBackgroudHandler {
  DefaultAppContextExtensionBackgroundScript get context;
  final Map<String, ChaCha20Poly1305> _sharedKeys = {};
  Future<IResult<BackgroundHdWallet>> getActiveWallet() async {
    final storage = AppWalletStorageManager(context.database);
    final wallet = await storage.readWallet();
    return wallet.mapErr((e) {
      return Web3RequestExceptionConst.internalErr("getActiveWallet",
          reason: e.exception.toString());
    }).andThenAsync((e) async {
      final wallet = e.getInitializeWallet();
      if (wallet == null) {
        return ResultErr.fromException(Web3RequestExceptionConst.walletNotInitialized);
      }
      final config = WalletConfigBackground(context);
      final controller = WalletBackgroundController(config);
      final result = await controller.init(InitWalletParams(id: wallet.key));
      return result
          .map((e) =>
              BackgroundHdWallet(wallet: wallet, controller: controller, id: wallet.key))
          .mapErr((e) {
        controller.dispose();
        return e.exception;
      });
    });
  }

  ChaCha20Poly1305 _getOrCreateSharedKey(
      {required String clientId, required Web3ApplicationAuthentication application}) {
    _sharedKeys[clientId] ??= () {
      final List<int> peerKey = BytesUtils.fromHexString(clientId);
      final sharedKey = JsCryptoUtils.generateShareKey(
          privateKey: application.token.privateKey, peerKey: peerKey);
      return ChaCha20Poly1305(sharedKey);
    }();
    return _sharedKeys[clientId]!;
  }

  Web3APPAuthenticationKey generateKey() {
    final key = JsCryptoUtils.generateKey();
    return Web3APPAuthenticationKey(publicKey: key.publicKey, privateKey: key.privateKey);
  }

  Future<IResult<Web3ApplicationAuthentication>> getPermission(
      {required Web3ClientInfo info, required BackgroundHdWallet wallet}) async {
    final permission =
        await wallet.controller.web3Storage.readWeb3Permission(info.identifier);
    return permission.andThenAsync((permission) async {
      if (permission != null) return ResultOk(permission);
      final token = generateKey();
      final newPermission =
          info.toAuhenticated(token: token, applicationKey: info.identifier);
      final result = await wallet.controller.web3Storage.savePermission(newPermission);
      return result.map((_) => newPermission);
    });
  }

  Future<Web3EncryptedMessage> toEncryptedMessage(
      {required Web3ApplicationAuthentication application,
      required String clientId,
      required List<int> message}) async {
    final chacha = _getOrCreateSharedKey(clientId: clientId, application: application);
    final nonce = QuickCrypto.generateRandom(12);
    final encryptedKey = chacha.encrypt(nonce, message);
    return Web3EncryptedMessage(message: encryptedKey, nonce: nonce);
  }

  Future<Web3GlobalRequestParams> decryptMessage(
      {required Web3ApplicationAuthentication application,
      required String clientId,
      required List<int> message}) async {
    final chacha = _getOrCreateSharedKey(clientId: clientId, application: application);
    final Web3EncryptedMessage msg = Web3EncryptedMessage.deserialize(bytes: message);
    final decrypted = chacha.decrypt(msg.nonce, msg.message);
    return Web3GlobalRequestParams.deserialize(bytes: decrypted);
  }

  IResult<Web3ClientInfo> buildClient(ChromeTab tab) {
    APPImage? image = APPImage.network(tab.favIconUrl);
    image ??= APPImage.faviIcon(tab.url!);

    final Web3ClientInfo? client = tab.id == null
        ? null
        : Web3ClientInfo.info(url: tab.url, faviIcon: image, name: tab.title);
    if (client == null) {
      return ResultErr.fromException(Web3RequestExceptionConst.invalidHost);
    }
    return ResultOk(client);
  }

  Future<IResult<JSWalletEventDart>> tabInformation(
      {required ChromeTab tab,
      required JSWalletEventDart event,
      required Web3ApplicationAuthentication application,
      required BackgroundHdWallet wallet}) async {
    final auth = await wallet.createWeb3Auth(application);
    return auth.mapAsync((auth) async {
      final message = Web3ChainMessage(authenticated: auth);
      final encryptMessage = await toEncryptedMessage(
          message: message.toCbor().encode(),
          clientId: event.clientId,
          application: application);
      return JSWalletEventDart(
          clientId: event.clientId,
          data: encryptMessage.toCbor().encode(),
          requestId: event.requestId,
          type: WalletEventTypes.activation,
          target: WalletEventTarget.background,
          additional:
              "${tab.id!}:${BytesUtils.toHexString(application.token.publicKey)}");
    });
  }

  Future<IResult<Web3APPData>> _onBackgroudMessage(
      {required JSWalletEventDart event,
      required ChromeTab tab,
      required Web3ApplicationAuthentication application,
      required Web3ClientInfo client,
      required BackgroundHdWallet wallet}) async {
    final message = (await decryptMessage(
        application: application, clientId: event.clientId, message: event.data));
    switch (message.method) {
      case Web3GlobalRequestMethods.disconnect:
        final disconnect = message.cast<Web3DisconnectApplication>();
        final result =
            await wallet.disconnectWeb3Chain(application, networks: [disconnect.chain]);
        return result.andThenAsync((e) {
          return wallet.createWeb3Auth(application, networks: [disconnect.chain]);
        });
      case Web3GlobalRequestMethods.connectSilent:
        final network = message.cast<Web3SilentConnectApplication>().chain;
        return wallet.createWeb3Auth(application,
            networks: network == null ? null : [network]);
      default:
        return ResultErr.fromException(Web3RequestExceptionConst.invalidRequest);
    }
  }

  Future<IResult<JSWalletEventDart>> onBackgroudMessage(
      {required JSWalletEventDart event,
      required ChromeTab tab,
      required Web3ApplicationAuthentication application,
      required Web3ClientInfo client,
      required BackgroundHdWallet wallet}) async {
    final result = await _onBackgroudMessage(
        event: event, tab: tab, application: application, client: client, wallet: wallet);
    return result.mapAsync((auth) async {
      final response = Web3GlobalResponseMessage(authenticated: auth);
      final encryptMessage = await toEncryptedMessage(
          clientId: event.clientId,
          message: response.toCbor().encode(),
          application: application);
      return JSWalletEventDart(
          clientId: event.clientId,
          data: encryptMessage.toCbor().encode(),
          requestId: event.requestId,
          type: WalletEventTypes.message,
          target: WalletEventTarget.background);
    });
  }

  Future<IResult<JSWalletEventDart>> _onContentScriptMessage(
      ChromeTab tab, JSWalletEventDart event) async {
    final wallet = await getActiveWallet();
    return wallet.andThenAsync((wallet) async {
      final client = buildClient(tab);
      return client.andThenAsync((client) async {
        final application = await getPermission(info: client, wallet: wallet);
        return application.andThenAsync((application) {
          switch (event.type) {
            case WalletEventTypes.background:
              return onBackgroudMessage(
                  event: event,
                  tab: tab,
                  application: application,
                  client: client,
                  wallet: wallet);
            case WalletEventTypes.tabId:
              return tabInformation(
                  tab: tab, event: event, application: application, wallet: wallet);
            default:
              return ResultErr.fromException(Web3RequestExceptionConst.internalErr(
                  "_onContentScriptMessage",
                  reason: "Unexpected event type.",
                  details: {"type": event.type.name}));
          }
        });
      });
    });
  }

  static JSWalletEventDart createTabError(
      {required ChromeTab tab,
      required JSWalletEventDart event,
      required IException error}) {
    return JSWalletEventDart(
        clientId: event.clientId,
        data: switch (error) {
          Web3RequestException error => error.toResponseMessage().toCbor().encode(),
          _ => Web3RequestExceptionConst.internalErr("createTabError",
                  reason: error.toString())
              .toResponseMessage()
              .toCbor()
              .encode()
        },
        requestId: event.requestId,
        type: WalletEventTypes.exception,
        target: WalletEventTarget.background);
  }

  Future<JSWalletEventDart> onContentScriptMessage(
      ChromeTab tab, JSWalletEventDart event) async {
    final result = await _onContentScriptMessage(tab, event);
    return result.fold(
        onOk: (e) => e,
        onErr: (error) {
          return createTabError(tab: tab, event: event, error: error.exception);
        });
  }

  // Future<IResult<WEB3CHAIN>> getWeb3InternalChainAuthenticated(
  //     Web3ApplicationAuthentication app) async {
  //   final web3Networks = this.web3Networks;
  //   if (web3Networks.isEmpty) {
  //     return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
  //   }
  //   final data = await _storage.queryChainStorageData(
  //       storage: DefaultChainStorageId.web3, key: app.applicationId);
  //   return data.map((data) {
  //     if (data == null) {
  //       return Web3InternalDefaultChain(
  //               networks: web3Networks
  //                   .map((e) => Web3InternalDefaultNetwork(
  //                       accounts: [], networkId: e.network.value))
  //                   .toList(),
  //               defaultChain: web3Networks.first.networkId,
  //               type: type)
  //           .cast<WEB3CHAIN>();
  //     }
  //     Web3InternalDefaultChain web3Chain =
  //         Web3InternalDefaultChain.deserialize(bytes: data);
  //     web3Chain = Web3InternalDefaultChain(
  //         networks: web3Networks.map((e) {
  //           final network =
  //               web3Chain.networks.firstWhereNullable((i) => i.networkId == e.networkId);
  //           return Web3InternalDefaultNetwork(
  //               accounts: network?.accounts ?? [],
  //               networkId: e.networkId,
  //               defaultAccount: network?.defaultAccount);
  //         }).toList(),
  //         defaultChain:
  //             _chains[web3Chain.defaultChain]?.networkId ?? web3Networks.first.networkId,
  //         type: type);
  //     return web3Chain.cast<WEB3CHAIN>();
  //   });
  // }
}
