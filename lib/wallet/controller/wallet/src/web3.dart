part of 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

mixin WalletControllerWeb3Context {
  IWeb3StorageManager get web3Storage;
  String get id;
  AppBasicCryptoApi get cryptolib;
  IWeb3WalletConnectController get web3Controller;
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network);
  Future<IResult<T>> uiActionRequest<T>(WalletUiAction<T> request);

  Future<IResult<Web3ApplicationAuthentication?>> getWeb3Authenticated(String identifier,
      {Web3APPProtocol? protocol}) async {
    final dataBytes = await web3Storage.readWeb3Permission(identifier);
    return dataBytes.map((appAuth) {
      if (protocol != null && appAuth?.protocol != protocol) {
        return null;
      }
      return appAuth;
    });
  }

  Future<IResult<Web3ApplicationAuthentication>> getOrCreateWeb3Authenticated(
      Web3ClientInfo info) async {
    final toPermission = await getWeb3Authenticated(info.identifier);
    return toPermission.andThenAsync((toPermission) async {
      if (toPermission == null) {
        final token = await cryptolib.excute(CryptoRequestGenerateX25519Key());
        return token.andThenAsync((token) async {
          final permission = info.toAuhenticated(
              token: Web3APPAuthenticationKey(
                  privateKey: token.privateKey, publicKey: token.publicKey),
              applicationKey: info.identifier);
          final result = await web3Storage.savePermission(permission);
          return result.map((_) => permission);
        });
      }

      return ResultOk(toPermission);
    });
  }

  Future<IResult<dynamic>> getWalletOwnerResult(Web3Request request) async {
    return await uiActionRequest(request);
  }

  Future<IResult<Web3APPData>> createWeb3Auth(Web3ApplicationAuthentication app,
      {List<NetworkType>? networks}) async {
    networks ??= NetworkType.values;
    List<Web3ChainAuthenticated> chains = [];
    if (app.active) {
      final result = await IResult.anyError(networks
          .map((e) => networkController(e).createWeb3ChainAuthenticated(app))
          .toList());
      if (result.isErr) return result.cast<Web3APPData>();
      chains = result.unwrap();
    }
    return ResultOk(Web3APPData(
        token: app.token,
        networks: networks,
        applicationId: app.applicationId,
        chains: chains));
  }

  Future<IResult<Web3DappInfo?>> _getWalletConnectAuth(
      Web3ClientInfo info, bool create) async {
    if (!create) {
      final auth = await getWeb3Authenticated(info.identifier);
      return auth.andThenAsync((auth) async {
        if (auth == null) return ResultOk(null);
        final dappInfo = await createWeb3Auth(auth);
        return dappInfo.map((dappInfo) => Web3DappInfo(
            authentication: auth, dappData: dappInfo, clientInfo: auth.toClient()));
      });
    }
    final auth = await getOrCreateWeb3Authenticated(info);
    return auth.andThenAsync((auth) async {
      final dappInfo = await createWeb3Auth(auth);
      return dappInfo.map((dappInfo) => Web3DappInfo(
          authentication: auth, dappData: dappInfo, clientInfo: auth.toClient()));
    });
  }

  Future<IResult<void>> updateWeb3InternalChains(
      {required Web3ApplicationAuthentication app,
      required List<Web3InternalChain> chains}) async {
    if (app.active) {
      return await IResult.anyError(chains.map((e) =>
          networkController(e.type).updateWeb3InternalChain(app: app, web3Chain: e)));
    } else {
      return await IResult.anyError(
          NetworkType.values.map((e) => networkController(e).disconnectWeb3Chain(app)));
    }
  }

  Future<IResult<void>> disconnectWeb3Chain(Web3ApplicationAuthentication app,
      {List<NetworkType>? networks}) async {
    networks ??= NetworkType.values;
    return await IResult.anyError(
        networks.map((e) => networkController(e).disconnectWeb3Chain(app)));
  }

  Future<IResult<Web3MessageCore>> _handleGlobalRequest(
      {required Web3GlobalRequestParams requestParams,
      required Web3ApplicationAuthentication authenticated,
      required Web3RequestInformation walletRequest}) async {
    Web3GlobalRequest request = Web3GlobalRequest(
        authenticated: authenticated, info: walletRequest, params: requestParams);
    IResult<List<NetworkType>> result;
    switch (requestParams.method) {
      case Web3GlobalRequestMethods.disconnect:
        final disconnect = requestParams.cast<Web3DisconnectApplication>();
        final r = await disconnectWeb3Chain(authenticated, networks: [disconnect.chain]);
        result = r.map((e) => [disconnect.chain]);
        break;
      case Web3GlobalRequestMethods.connectSilent:
        final disconnect = requestParams.cast<Web3SilentConnectApplication>();
        final chains =
            disconnect.chain == null ? NetworkType.values : [disconnect.chain!];
        result = ResultOk(chains);
        break;
      default:
        final data = await getWalletOwnerResult(request);
        result = data.map((e) => e);
        break;
    }
    return result.andThenAsync((result) async {
      final activity = request.createActivity();
      web3Storage.saveWeb3ApplicationActivity(
          permission: authenticated, activity: activity);
      final auth = await createWeb3Auth(authenticated, networks: result);
      return auth.map((auth) => Web3GlobalResponseMessage(authenticated: auth));
    });
  }

  Future<IResult<Web3MessageCore>> _handleChainRequest(
      {required Web3RequestParams requestParams,
      required Web3ApplicationAuthentication authenticated,
      required Web3RequestInformation walletRequest}) async {
    final request = await requestParams.toRequest(
        request: walletRequest,
        chainController: networkController(requestParams.method.network),
        authenticated: authenticated);
    return request.andThenAsync((request) async {
      final result = await getWalletOwnerResult(request);
      return result.andThenAsync((result) async {
        final activity = request.createActivity();
        web3Storage.saveWeb3ApplicationActivity(
            permission: authenticated, activity: activity);
        Object? walletResponse;
        if (authenticated.protocol.isWalletConnect) {
          walletResponse = request.params.toWalletConnectResponse(result);
        } else {
          walletResponse = request.params.toJsWalletResponse(result);
        }
        if (request.params.method.reloadAuthenticated) {
          final auth = await createWeb3Auth(authenticated);
          return auth.map((auth) => Web3WalletResponseMessage(
              result: walletResponse,
              authenticated: auth,
              network: request.params.method.network));
        }
        return ResultOk(Web3WalletResponseMessage(
            result: walletResponse, network: request.params.method.network));
      });
    });
  }

  Future<IResult<Web3MessageCore>> web3GetResponse(
      {required Web3MessageCore requestParams,
      required Web3ApplicationAuthentication authenticated,
      required Web3RequestInformation walletRequest}) async {
    if (!authenticated.active) {
      return ResultErr.fromException(Web3RequestExceptionConst.bannedHost);
    }
    final IResult<Web3MessageCore> result =
        await IResult.block<Web3MessageCore>(() => switch (requestParams.type) {
              Web3MessageTypes.walletRequest => _handleChainRequest(
                  authenticated: authenticated,
                  requestParams: requestParams.cast<Web3RequestParams>(),
                  walletRequest: walletRequest),
              Web3MessageTypes.walletGlobalRequest => _handleGlobalRequest(
                  requestParams: requestParams.cast<Web3GlobalRequestParams>(),
                  authenticated: authenticated,
                  walletRequest: walletRequest),
              _ => Future.value(ResultErr<Web3MessageCore>.fromException(
                  Web3RequestExceptionConst.invalidRequest))
            });
    return await result.andAsync((result, error) async {
      Logging.error(
          when: () => error != null,
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "web3GetResponse",
              err: error?.exception,
              trace: error?.trace));
      switch (error) {
        case null:
          return ResultOk(result!);
        case Web3RequestClosed closed:
          return ResultErr.fromException(closed);
        case Web3RequestExceptionConst.missingPermission:
        case Web3RequestExceptionConst.bannedHost:
        case Web3RequestExceptionConst.invalidNetwork:
        case Web3RequestExceptionConst.internalError_:
          final result = await createWeb3Auth(authenticated);
          return result.and<Web3MessageCore>((result, e) {
            final err = Web3RequestExceptionConst.fromException(e ?? error.exception);
            return ResultOk(err.toResponseMessage(
                requestId: walletRequest.requestId, authenticated: result));
          });
        default:
          final err = Web3RequestExceptionConst.fromException(error.exception);
          return ResultOk(err.toResponseMessage(requestId: walletRequest.requestId));
      }
    });
  }

  Future<IResult<Web3MessageCore>> _web3WalletConnectRequest(
      Web3RequestWalletConnectApplicationInformation walletRequest) async {
    final authenticated = await getWeb3Authenticated(walletRequest.info.identifier);
    return authenticated.andThenAsync((authenticated) {
      if (authenticated == null) {
        return ResultErr.fromException(Web3RequestExceptionConst.missingPermission);
      }
      return web3GetResponse(
          requestParams: walletRequest.request,
          authenticated: authenticated,
          walletRequest: walletRequest);
    });
  }

  Future<IResult<Web3APPData>> _getDefaultAuth() async {
    final application = Web3ApplicationAuthentication.local();
    return createWeb3Auth(application);
  }

  Future<IResult<List<Web3ApplicationAuthentication>>> getAllWeb3Authenticated() async {
    return await web3Storage.readAllApplications();
  }
}
