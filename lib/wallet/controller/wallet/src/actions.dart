part of 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

typedef PROCOESSACTION<RESPONSE extends Object?> = FutureOr<RESPONSE> Function();

sealed class WalletAction<RESPONSE extends Object?> {
  WalletAction();
  WalletActionEventType get event;
  LockId get syncId => LockId.one;
}

sealed class WalletActionWallet<RESPONSE extends Object?> extends WalletAction<RESPONSE> {
  Future<IResult<RESPONSE>> _getResult(BaseWalletControllerContext context);
}

/// Current app wallet crypto related actions
sealed class WalletActionWalletGuarded<RESPONSE extends Object?>
    extends WalletActionWallet<RESPONSE> {
  WalletCredentialResponseVerify? get credential;
}

/// Web3 related actions
sealed class WalletActionWalletWeb3<RESPONSE extends Object?>
    extends WalletActionWallet<RESPONSE> {
  @override
  LockId get syncId => LockId.two;
}

class WalletActionLock extends WalletActionWallet<void> {
  @override
  WalletActionEventType get event => WalletActionEventType.lock;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    context.lock();
    return ResultOk.okVoid;
  }

  @override
  LockId get syncId => LockId.five;
}

class WalletActionSetupSubWallet extends WalletActionWallet<void> {
  final WalletImportSubWalletData subWallet;
  WalletActionSetupSubWallet({required this.subWallet});

  @override
  WalletActionEventType get event => WalletActionEventType.importSubWallet;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    final subWalletData = subWallet;
    if (subWalletData.mainWalletId != context.wallet.id) {
      return ResultErr.fromException(WalletExceptionConst.incorrectWalletData);
    }
    return await context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
          message: WalletRequestImportSubWallet(
              mnemonic: subWalletData.mnemonic,
              passphrase: subWalletData.passphrase,
              name: subWalletData.name,
              type: subWalletData.type),
          memoryWallet: memoryWallet,
        );
        return result.map((result) {
          return WalletInternalCallResponse(result: null, key: result.masterKey);
        });
      },
    );
  }
}

class WalletActionWeb3Request extends WalletActionWalletWeb3<Web3MessageCore> {
  final Web3RequestApplicationInformation request;
  WalletActionWeb3Request({required this.request});

  @override
  WalletActionEventType get event => WalletActionEventType.web3Request;

  @override
  Future<IResult<Web3MessageCore>> _getResult(BaseWalletControllerContext context) async {
    final authenticated = await context.getWeb3Authenticated(request.applicationId);
    return authenticated.andThenAsync((authenticated) async {
      if (authenticated == null) {
        return ResultErr.fromException(Web3RequestExceptionConst.missingPermission);
      }
      return await context.web3GetResponse(
          requestParams: request.message,
          authenticated: authenticated,
          walletRequest: request);
    });
  }
}

class WalletActionWeb3InternalChains
    extends WalletActionWalletWeb3<List<Web3InternalChain>> {
  final Web3ApplicationAuthentication authenticated;
  final List<NetworkType>? networks;
  WalletActionWeb3InternalChains({required this.authenticated, required this.networks});

  @override
  WalletActionEventType get event => WalletActionEventType.web3Auth;
  @override
  LockId get syncId => LockId.three;

  @override
  Future<IResult<List<Web3InternalChain>>> _getResult(
      BaseWalletControllerContext context) async {
    final networks = this.networks ?? NetworkType.values;
    return await IResult.anyError(networks.map((e) =>
        context.networkController(e).getWeb3InternalChainAuthenticated(authenticated)));
  }
}

class WalletActionWeb3ApplicationActivities
    extends WalletActionWalletWeb3<List<Web3AccountAcitvity>> {
  final Web3ApplicationAuthentication authenticated;
  WalletActionWeb3ApplicationActivities({required this.authenticated});

  @override
  WalletActionEventType get event => WalletActionEventType.web3Auth;
  @override
  LockId get syncId => LockId.three;

  @override
  Future<IResult<List<Web3AccountAcitvity>>> _getResult(
      BaseWalletControllerContext context) async {
    return await context.web3Storage.readWeb3ApplicationActivities(authenticated);
  }
}

class WalletActionRemoveWeb3ApplicationActivities extends WalletActionWalletWeb3<void> {
  final Web3ApplicationAuthentication authenticated;
  WalletActionRemoveWeb3ApplicationActivities({required this.authenticated});

  @override
  WalletActionEventType get event => WalletActionEventType.web3Auth;
  @override
  LockId get syncId => LockId.three;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    return await context.web3Storage.removeWeb3ApplicationActivities(authenticated);
  }
}

class WalletActionAllWeb3Applications extends WalletActionWalletWeb3<List<Web3DappInfo>> {
  @override
  WalletActionEventType get event => WalletActionEventType.web3Auth;
  @override
  LockId get syncId => LockId.three;
  @override
  Future<IResult<List<Web3DappInfo>>> _getResult(
      BaseWalletControllerContext context) async {
    final keys = await context.web3Storage.readAllApplications();
    return keys.andThenAsync((auths) async {
      final dapps = await IResult.anyError(auths.map((e) => context.createWeb3Auth(e)));
      return dapps.map((data) => data.indexed.map((dappData) {
            final auth = auths[dappData.$1];
            return Web3DappInfo(
                authentication: auth, clientInfo: auth.toClient(), dappData: dappData.$2);
          }).toList());
    });
  }
}

/// localWeb3Request
class WalletActionInAppWeb3Request<RESPONSE> extends WalletActionWalletWeb3<RESPONSE> {
  final WEB3REQUESTPARAMSRESPONSE<RESPONSE> request;
  WalletActionInAppWeb3Request({required this.request});
  @override
  WalletActionEventType get event => WalletActionEventType.web3Request;

  @override
  Future<IResult<RESPONSE>> _getResult(BaseWalletControllerContext context) async {
    final request = await this.request.toRequest(
        request: Web3RequestLocalInformation(UUID.random()),
        chainController: context.networkController(this.request.method.network),
        authenticated: Web3LocalAuthentication(
            icon: APPConst.logo, applicationId: APPConst.name, name: APPConst.name));
    return request.andThenAsync((request) async {
      final chain = await request.chain.initAsMainNetwork();
      return chain.andThenAsync((e) async {
        final result = await context.getWalletOwnerResult(request);
        return result.map((e) => e);
      });
    });
  }
}

class WalletActionWeb3Dapp extends WalletActionWalletWeb3<Web3DappInfo> {
  final Web3ClientInfo client;
  WalletActionWeb3Dapp({required this.client});
  @override
  WalletActionEventType get event => WalletActionEventType.web3Auth;

  @override
  Future<IResult<Web3DappInfo>> _getResult(BaseWalletControllerContext context) async {
    final authentication = await context.getOrCreateWeb3Authenticated(client);
    return authentication.andThenAsync((authentication) async {
      final dappData = await context.createWeb3Auth(authentication);
      return dappData.map((e) =>
          Web3DappInfo(authentication: authentication, dappData: e, clientInfo: client));
    });
  }
}

class WalletActionWeb3DappAuthenticated
    extends WalletActionWalletWeb3<Web3ApplicationAuthentication> {
  final Web3ClientInfo client;
  WalletActionWeb3DappAuthenticated({required this.client});
  @override
  WalletActionEventType get event => WalletActionEventType.web3Auth;

  @override
  Future<IResult<Web3ApplicationAuthentication>> _getResult(
      BaseWalletControllerContext context) async {
    final toPermission = await context.getWeb3Authenticated(client.identifier);
    return toPermission.andThenAsync((toPermission) async {
      if (toPermission == null) {
        final token = await context.cryptolib.excute(CryptoRequestGenerateX25519Key());
        return token.andThenAsync((token) async {
          final permission = client.toAuhenticated(
              token: Web3APPAuthenticationKey(
                  privateKey: token.privateKey, publicKey: token.publicKey),
              applicationKey: client.identifier);
          final result = await context.web3Storage.savePermission(permission);
          return result.map((_) => permission);
        });
      }

      return ResultOk(toPermission);
    });
  }
}

class WalletActionWalletRequest<T extends AppSerialization>
    extends WalletActionWallet<T> {
  final WalletArgsCompleter<T> request;
  WalletActionWalletRequest({required this.request});
  @override
  WalletActionEventType get event => WalletActionEventType.walletRequest;
  @override
  LockId get syncId => LockId.four;
  @override
  Future<IResult<T>> _getResult(BaseWalletControllerContext context) {
    return context.onAccessWallet<T>(
      (memoryWallet, crypto) async {
        final result =
            await crypto.excuteWallet<T>(message: request, memoryWallet: memoryWallet);
        return result.map((result) => WalletInternalCallResponse(result: result));
      },
    );
  }
}

class WalletActionUpdateWeb3Application extends WalletActionWalletWeb3<Web3DappInfo> {
  final Web3ApplicationAuthentication application;
  final List<Web3InternalChain> chains;
  WalletActionUpdateWeb3Application({required this.application, required this.chains});
  @override
  WalletActionEventType get event => WalletActionEventType.updateWeb3Auth;

  @override
  LockId get syncId => LockId.three;

  @override
  Future<IResult<Web3DappInfo>> _getResult(BaseWalletControllerContext context) async {
    final result = await context.web3Storage.savePermission(application);
    return result.andThenAsync((_) async {
      final result =
          await context.updateWeb3InternalChains(app: application, chains: chains);
      return result.andThenAsync((_) async {
        final dappData = await context.createWeb3Auth(application,
            networks: chains.map((e) => e.type).toList());
        return dappData.map((dappData) => Web3DappInfo(
            authentication: application,
            dappData: dappData,
            clientInfo: application.toClient()));
      });
    });
  }
}

class WalletActionDisconnectWeb3Application extends WalletActionWalletWeb3<Web3APPData?> {
  final Web3ApplicationAuthentication application;
  final bool removeApplication;
  WalletActionDisconnectWeb3Application(
      {required this.application, required this.removeApplication});
  @override
  WalletActionEventType get event => WalletActionEventType.updateWeb3Auth;

  @override
  Future<IResult<Web3APPData?>> _getResult(BaseWalletControllerContext context) async {
    final result = await context.web3Storage.removeWeb3Permission(application);
    return result.andThenAsync((_) async {
      if (removeApplication) {
        final result = await context.disconnectWeb3Chain(application);
        return result.andThenAsync((_) async {
          final result =
              await context.web3Storage.removeWeb3ApplicationActivities(application);
          return result.map((_) => null);
        });
      }
      return context.createWeb3Auth(application);
    });
  }
}

class WalletActionChangeWalletPassword extends WalletActionWalletGuarded<void> {
  @override
  final WalletCredentialResponseVerify credential;
  final String newPassword;
  WalletActionChangeWalletPassword({required this.credential, required this.newPassword});
  @override
  WalletActionEventType get event => WalletActionEventType.changePassword;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    if (!PasswordUtils.canUseAsPassword(newPassword)) {
      return ResultErr.fromException(WalletExceptionConst.passwordTooWeak);
    }
    return await context.onAccessWallet((memoryWallet, crypto) async {
      final result = await crypto.excuteWallet(
          message: WalletRequestChangePassword(
              newPassword: newPassword, checksum: context.wallet.checkSumBytes),
          memoryWallet: memoryWallet);
      return result.map((key) => WalletInternalCallResponse(result: null, key: key));
    });
  }
}

class WalletActionWalletExternalBackup
    extends WalletActionWalletGuarded<ExternalWalletBackupWithSession> {
  @override
  final WalletCredentialResponseVerify credential;
  final SymKey key;
  WalletActionWalletExternalBackup({
    required this.key,
    required this.credential,
  });
  @override
  WalletActionEventType get event => WalletActionEventType.backupWallet;

  @override
  Future<IResult<ExternalWalletBackupWithSession>> _getResult(
      BaseWalletControllerContext context) async {
    MainWallet wallet;
    if (context.wallet case MainWallet w) {
      wallet = w;
    } else {
      return ResultErr.fromException(WalletExceptionConst.unsuportedFeature);
    }
    final result = await context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
            message: WalletRequestBackupExternalWallet(key), memoryWallet: memoryWallet);
        return result.map((result) => WalletInternalCallResponse(result: result));
      },
    );
    return result.andThenAsync((result) async {
      final dapps = await context.getAllWeb3Authenticated();
      return dapps.andThenAsync((dapps) async {
        final networkBackups = await IResult.anyError(NetworkType.values
            .map((e) => context.networkController(e).getNetworksBackup(
                context.chains.where((c) => c.network.type == e).toList()))
            .toList());
        return networkBackups.andThenAsync((networkBackups) async {
          final chainBackups = await IResult.anyError(NetworkType.values.map((e) =>
              context.networkController(e).getChainBackup(web3Applications: dapps)));
          return chainBackups.map((chainBackups) {
            final backup = ExternalWalletBackup(
                wallet: wallet,
                key: result.backup,
                networks: networkBackups.expand((e) => e).toList(),
                chains: chainBackups.expand((e) => e).toList());
            final bytes = backup.toCbor().encode();
            return ExternalWalletBackupWithSession(
                encodedBackup: bytes, session: result.session);
          });
        });
      });
    });
  }
}

class WalletActionImportExternalWallet extends WalletActionWalletGuarded<void> {
  @override
  final WalletCredentialResponseVerify credential;
  final SymKey key;
  final List<int> checksum;
  final int clientId;
  WalletActionImportExternalWallet({
    required this.credential,
    required this.key,
    required this.checksum,
    required this.clientId,
  });
  @override
  WalletActionEventType get event => WalletActionEventType.importExternalWallet;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    return await context.onAccessWallet((memoryWallet, crypto) async {
      final result = await crypto.excuteWallet(
          message: WalletRequestImportExternalWallet(
              key: key, checksum: checksum, clientId: clientId),
          memoryWallet: memoryWallet);
      return result.map(
          (result) => WalletInternalCallResponse(result: null, key: result.encryptedKey));
    });
  }
}

class WalletActionRemoveCredential extends WalletActionWallet<void> {
  final WalletCredentialResponseVerify credential;
  WalletActionRemoveCredential({required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.removeCredential;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    context.removeCredential(credential);
    return ResultOk.okVoid;
  }
}

class WalletActionDeriveNewAccount<NETWORKADDRESS extends IAddress>
    extends WalletActionWallet<ACCOUNTADDRESS<NETWORKADDRESS>> {
  final NewAccountParams<ACCOUNTADDRESS<NETWORKADDRESS>> newAccountParams;
  final APPCHAINACCOUNT<ACCOUNTADDRESS<NETWORKADDRESS>> chain;
  WalletActionDeriveNewAccount({required this.newAccountParams, required this.chain});
  @override
  WalletActionEventType get event => WalletActionEventType.deriveAddress;

  @override
  Future<IResult<ACCOUNTADDRESS<NETWORKADDRESS>>> _getResult(
      BaseWalletControllerContext context) async {
    switch (newAccountParams) {
      case NewDerivableAccountParams derivableRequest:
        final updateParams = await context.onAccessWallet(
          (memoryWallet, crypto) async {
            final result = await crypto.excuteWallet(
                message: WalletRequestDeriveAddress(addressParams: derivableRequest),
                memoryWallet: memoryWallet);
            return result.map((result) => WalletInternalCallResponse(result: result));
          },
        );
        return updateParams.andThenAsync((params) async {
          final account = await chain.importAddress(
              params.publicKey,
              params.accountParams
                  .cast<NewAccountParams<ACCOUNTADDRESS<NETWORKADDRESS>>>());
          return account.map((e) => e.cast<ACCOUNTADDRESS<NETWORKADDRESS>>());
        });

      default:
        final result = await chain.importAddress(null, newAccountParams);
        return result.map((e) => e.cast<ACCOUNTADDRESS<NETWORKADDRESS>>());
    }
  }
}

class WalletActionImportSecretKey extends WalletActionWalletGuarded<void> {
  final ImportedKeyStorage secretKey;
  @override
  final WalletCredentialResponseVerify credential;
  WalletActionImportSecretKey({required this.secretKey, required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.importKey;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    return await context.onAccessWallet((memoryWallet, crypto) async {
      final result = await crypto.excuteWallet(
          message: WalletRequestImportNewKey(secretKey), memoryWallet: memoryWallet);
      return result
          .map((result) => WalletInternalCallResponse(result: null, key: result));
    });
  }
}

class WalletActionViewImportedAccounts
    extends WalletActionWallet<List<ViewImportedSecretKey>> {
  @override
  WalletActionEventType get event => WalletActionEventType.viewImportedKeys;

  @override
  Future<IResult<List<ViewImportedSecretKey>>> _getResult(
      BaseWalletControllerContext context) async {
    return ResultOk(List<ViewImportedSecretKey>.from(context.wallet.importedKeys));
  }
}

class WalletActionRemoveImportedKey extends WalletActionWalletGuarded<void> {
  final ViewImportedSecretKey secretKey;
  @override
  final WalletCredentialResponseVerify credential;
  WalletActionRemoveImportedKey({required this.secretKey, required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.removeKey;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    if (!context.wallet.importedKeys.contains(secretKey)) {
      return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
    }
    final result = await _cleanUpdateRemovedKeyAccounts(context.chains, secretKey.id);
    return result.andThenAsync((e) {
      return context.onAccessWallet(
        (memoryWallet, crypto) async {
          final result = await crypto.excuteWallet(
              message: WalletRequestRemoveKey(secretKey.id), memoryWallet: memoryWallet);
          return result
              .map((encrypt) => WalletInternalCallResponse(result: null, key: encrypt));
        },
      );
    });
  }

  Future<IResult<void>> _cleanUpdateRemovedKeyAccounts(
      List<Chain> chains, int removedKey) async {
    for (final chain in chains) {
      final addresses = await chain.getAccountAddresses();
      if (addresses.isErr) return addresses;
      for (final address in addresses.unwrap()) {
        final keyIndexes =
            address.derivableIndexes(request: AccountDerivationIndexRequestSigners());
        if (keyIndexes.any((e) => e.importedKeyId == removedKey)) {
          final result = await chain.removeAccount(address);
          if (result.isErr) return result;
        }
      }
    }
    return ResultOk.okVoid;
  }
}

class WalletActionSwitchNetwork extends WalletActionWallet<void> {
  final Chain network;
  WalletActionSwitchNetwork({required this.network});
  @override
  WalletActionEventType get event => WalletActionEventType.switchNetwork;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    await context.switchNetwork(network);
    return ResultOk.okVoid;
  }
}

class WalletActionAccountPublicKeys
    extends WalletActionWallet<ReadAccountPublicKeysResponse> {
  final ChainAccount account;
  WalletActionAccountPublicKeys({required this.account});
  @override
  WalletActionEventType get event => WalletActionEventType.exportAccountKey;

  @override
  Future<IResult<ReadAccountPublicKeysResponse>> _getResult(
      BaseWalletControllerContext context) async {
    final pubKeys = await context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
          memoryWallet: memoryWallet,
          message: WalletRequestReadAccountPublicKeys(
              account.createViewKeyRequest(request: null)),
        );
        return result.map((result) => WalletInternalCallResponse(result: result));
      },
    );
    return pubKeys.mapAsync((pubKeys) {
      switch (pubKeys) {
        case ReadAccountPublicKeysResponseDefault():
          return pubKeys.copyWith(
              keys: pubKeys.keys.map(context.keyWithWalletName).toList());
        case ReadAccountPublicKeysResponseZcash():
          return pubKeys.copyWith(
              keys: pubKeys.keys
                  .map((e) =>
                      e.copyWith(keys: e.keys.map(context.keyWithWalletName).toList()))
                  .toList());
      }
    });
  }
}

class WalletActionDerivableIndexPublicKey
    extends WalletActionWallet<CryptoPublicKeyDataWithInfo> {
  final DerivableIndex index;
  WalletActionDerivableIndexPublicKey({required this.index});
  @override
  WalletActionEventType get event => WalletActionEventType.exportAccountKey;

  @override
  Future<IResult<CryptoPublicKeyDataWithInfo>> _getResult(
      BaseWalletControllerContext context) async {
    final pubKeys = await context.onAccessWallet((memoryWallet, crypto) async {
      final result = await crypto.excuteWallet(
          memoryWallet: memoryWallet,
          message: WalletRequestReadPublicKeys(AccessCryptoKeysRequest([index])));
      return result.map((result) => WalletInternalCallResponse(result: result));
    });
    return pubKeys.map((e) => context.keyWithWalletName(e.keys.first));
  }
}

class WalletActionUpdateNetwork extends WalletActionWallet<void> {
  final WalletNetwork network;
  WalletActionUpdateNetwork({required this.network});
  @override
  WalletActionEventType get event => WalletActionEventType.updateAccount;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    final type = network.type;
    final controller = context.networks[type];
    if (controller == null || !network.isWalletNetwork) {
      return ResultErr.fromException(WalletExceptionConst.networkDoesNotExist);
    }
    int networkId = network.value;
    final existChain = controller.getChain(networkId);
    if (existChain == null) {
      return ResultErr.fromException(WalletExceptionConst.invalidNetworkInformation);
    }
    final otherChains = controller.getChains().where((e) => e != existChain).toList();

    Chain newChain = Chain.setup(
        network: network, id: context.id, controller: context.inChainWalletController);
    final init = (await newChain.init()).mapErr((e) {
      newChain.dispose();
      return e.exception;
    });
    return init.andThenAsync((_) async {
      existChain.dispose();
      context.setNetwork(NetworkController.fromChains(
          type: type,
          chains: [...otherChains, newChain],
          id: context.id,
          database: context.config.database));
      if (newChain.network.value == context.chain.network.value) {
        return context.setChain(newChain);
      }
      return ResultOk.okVoid;
    });
  }
}

class WalletActionImportNewNetwork extends WalletActionWallet<void> {
  final WalletNetwork network;
  final List<DefaultAPIProvider> providers;
  WalletActionImportNewNetwork({required this.network, required this.providers});
  @override
  WalletActionEventType get event => WalletActionEventType.importNetwork;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    WalletNetwork network = this.network;
    final type = network.type;
    final controller = context.networks[type];
    if (controller == null || network.isWalletNetwork || !network.supportImportNetwork) {
      return ResultErr.fromException(WalletExceptionConst.invalidNetworkInformation);
    }
    final chains = controller.getChains();
    if (chains.any((e) => e.network.identifier == network.identifier)) {
      return ResultErr.fromException(WalletExceptionConst.networkAlreadyExist);
    }
    int networkId = network.value;
    final ids = context.networks.values.expand((e) => e.getIds()).toList();
    networkId =
        StrUtils.findFirstMissingNumber(ids, start: ChainConst.importedNetworkStartId);
    if (networkId > ChainConst.maxNetworkId) {
      return ResultErr.fromException(WalletExceptionConst.toManyNetworkImported);
    }
    network = network.copyWith(value: networkId);
    if (network.value != networkId) {
      return ResultErr.fromException(WalletExceptionConst.invalidNetworkInformation);
    }
    final newChain = Chain.setup(
        network: network, id: context.id, controller: context.inChainWalletController);
    await context.storage.removeChain(newChain);
    final result = await newChain.setupAccount(providers: providers);
    return result.andThenAsync((_) async {
      final init = await newChain.init();
      return init.map((_) {
        context.setNetwork(NetworkController.fromChains(
            type: type,
            chains: [...chains, newChain],
            id: context.id,
            database: context.config.database));
      });
    });
  }
}

class WalletActionRemoveAccount extends WalletActionWallet<void> {
  final Chain account;
  WalletActionRemoveAccount({required this.account});
  @override
  WalletActionEventType get event => WalletActionEventType.removeAccount;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    if (account.id != context.id) {
      return ResultErr.fromException(AppInternalError.internalError("removeChain"));
    }
    final hasDefaultNetwork = ChainConst.defaultCoins[account.network.value];
    if (!account.network.isWalletNetwork || hasDefaultNetwork != null) {
      return ResultErr.fromException(AppInternalError.internalError("removeChain"));
    }
    final type = account.network.type;
    final controller = context.networks[type];

    if (controller == null) {
      return ResultErr.fromException(AppInternalError.internalError("removeChain"));
    }
    final existsChains = controller.getChains().where((e) => e != account).toList();
    if (context.chain == account) {
      final changeNetwork =
          existsChains.firstOrNull ?? context.chains.firstWhere((e) => e != account);
      final switched = await context.switchNetwork(changeNetwork);
      if (switched.isErr) {
        return switched;
      }
    }
    final remove = await context.storage.removeChain(account);
    return remove.map((_) {
      account.dispose();
      context.setNetwork(NetworkController.fromChains(
          type: type,
          chains: existsChains,
          id: context.id,
          database: context.config.database));
    });
  }
}

class WalletActionWalletBackup extends WalletActionWalletGuarded<String> {
  @override
  final WalletCredentialResponseVerify credential;
  final GenerateWalletBackupOptions options;
  WalletActionWalletBackup({required this.credential, required this.options});
  @override
  WalletActionEventType get event => WalletActionEventType.backupWallet;

  @override
  Future<IResult<String>> _getResult(BaseWalletControllerContext context) async {
    final checksum = QuickCrypto.generateRandom();
    final encrypt = await context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
            memoryWallet: memoryWallet,
            message: WalletRequestBackupWallet(
              newPassword: options.newPassword,
              passhrase: options.passphrase,
              checksum: checksum,
            ));
        return result.map((result) => WalletInternalCallResponse(result: result));
      },
    );
    return encrypt.andThenCatchAsync((encrypt) async {
      MainWallet wallet;
      if (context.wallet case MainWallet w) {
        wallet = w;
      } else {
        return ResultErr.fromException(WalletExceptionConst.unsuportedFeature);
      }
      List<Web3ApplicationAuthentication> dapps = [];
      if (options.backupDapps) {
        final result = await context.getAllWeb3Authenticated();
        if (result.isErr) {
          return result.cast<String>();
        }
        dapps = result.unwrap();
      }
      final networkBackups = await IResult.anyError(NetworkType.values
          .map((e) => context.networkController(e).getNetworksBackup(
              options.chains.where((c) => c.network.type == e).toList()))
          .toList());
      return networkBackups.andThenAsync((networkBackups) async {
        final chainBackups = await IResult.anyError(NetworkType.values.map(
            (e) => context.networkController(e).getChainBackup(web3Applications: dapps)));
        return chainBackups.map((chainBackups) {
          final walletBackup = WalletBackup(
              wallet: wallet,
              key: encrypt.backup,
              networks: networkBackups.expand((e) => e).toList(),
              chains: chainBackups.expand((e) => e).toList());
          return walletBackup.toCbor(checksum).toCborHex();
        });
      });
    });
  }
}

class WalletActionRemoveSubWallet extends WalletActionWalletGuarded<void> {
  final int id;
  @override
  final WalletCredentialResponseVerify credential;
  WalletActionRemoveSubWallet({required this.id, required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.removeSubWallet;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    final accounts = await _cleanUpdateRemovedSubWalletAccounts(context.chains, id);
    return accounts.andThenAsync((_) {
      return context.onAccessWallet(
        (memoryWallet, crypto) async {
          final result = await crypto.excuteWallet(
              message: WalletRequestRemoveSubWallet(id: id), memoryWallet: memoryWallet);
          return result
              .map((result) => WalletInternalCallResponse(result: null, key: result));
        },
      );
    });
  }

  Future<IResult<void>> _cleanUpdateRemovedSubWalletAccounts(
      List<Chain> chains, int subWalletId) async {
    for (final chain in chains) {
      final addresses = await chain.getAccountAddresses();
      if (addresses.isErr) return addresses;
      for (final address in addresses.unwrap()) {
        final keyIndexes =
            address.derivableIndexes(request: AccountDerivationIndexRequestSigners());
        if (keyIndexes.any((e) => e.subId == subWalletId)) {
          final result = await chain.removeAccount(address);
          if (result.isErr) return result;
        }
      }
    }
    return ResultOk.okVoid;
  }
}

class WalletActionSign<T> extends WalletActionWalletGuarded<T> {
  final WalletSigningRequest<T> request;
  @override
  final WalletCredentialResponseVerify? credential;
  final AccountDerivationIndexRequest? derivationRequest;
  WalletActionSign({required this.request, this.credential, this.derivationRequest});
  @override
  WalletActionEventType get event => WalletActionEventType.walletRequest;

  WalletActionSign<T> copyWith(
      {WalletSigningRequest<T>? request,
      WalletCredentialResponseVerify? credential,
      AccountDerivationIndexRequest? derivationRequest}) {
    return WalletActionSign<T>(
        request: request ?? this.request,
        credential: credential ?? this.credential,
        derivationRequest: derivationRequest ?? this.derivationRequest);
  }

  @override
  Future<IResult<T>> _getResult(BaseWalletControllerContext context) async {
    final Set<ChainAccount> addresses = request.addresses.toSet();
    final Set<DerivationIndex> signers = addresses
        .map((e) => e.derivableIndexes(
            request: derivationRequest ?? AccountDerivationIndexRequestSigners()))
        .expand((e) => e)
        .toSet();
    return await context.onAccessWallet(
      (memoryWallet, crypto) async {
        Future<E> signing<E extends SignResponse>(SignRequest<E> request) async {
          if (request.indexes.any((e) => !signers.contains(e))) {
            throw WalletExceptionConst.notAuthorizedSigningAccount;
          }
          final result = await crypto.excuteWallet(
              memoryWallet: memoryWallet, message: WalletRequestSign(request));
          return result.unwrap();
        }

        final sign = await IResult.call(() async => await request.sign(signing));
        return sign.map((sign) => WalletInternalCallResponse(result: sign));
      },
    );
  }
}

class WalletActionUpdateWallet extends WalletActionWalletGuarded<void> {
  final WalletUpdateInfosData walletInfos;
  @override
  final WalletCredentialResponseVerify credential;
  WalletActionUpdateWallet({required this.walletInfos, required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.updateWallet;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    final updatedWallet = context.wallet.updateSettings(update: walletInfos);
    await context.updateWallet(updatedWallet);
    return ResultOk.okVoid;
  }
}

class WalletActionAccess<RESPONSE extends WalletCredentialResponse>
    extends WalletActionWallet<RESPONSE> {
  final WalletCredentialRequest<RESPONSE> request;
  WalletActionAccess({required this.request});
  @override
  WalletActionEventType get event => WalletActionEventType.login;

  @override
  Future<IResult<RESPONSE>> _getResult(BaseWalletControllerContext context) async {
    return context.createAccess<RESPONSE>(this);
  }
}

class WalletActionRemoveWallet extends WalletActionWalletGuarded<void> {
  @override
  final WalletCredentialResponseVerify credential;
  WalletActionRemoveWallet({required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.removeWallet;

  @override
  Future<IResult<void>> _getResult(BaseWalletControllerContext context) async {
    await context.storage.removeWallet();
    await context.dispose();
    return ResultOk.okVoid;
  }
}

class WalletActionKeyBackup extends WalletActionWalletGuarded<String> {
  final String data;
  final WalletBackupTypes backupType;
  @override
  final WalletCredentialResponseVerify credential;
  WalletActionKeyBackup(
      {required this.data, required this.backupType, required this.credential});
  @override
  WalletActionEventType get event => WalletActionEventType.backup;

  @override
  Future<IResult<String>> _getResult(BaseWalletControllerContext context) async {
    if (backupType.isWalletBackup) {
      return ResultErr.fromException(WalletExceptionConst.invalidBackupOptions);
    }
    return context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
            message: WalletRequestBackupKey(
                backup: backupType.toEncryptionBytes(data),
                encoding: backupType.encoding),
            memoryWallet: memoryWallet);
        if (backupType == WalletBackupTypes.keystore) {
          return result.map((e) => WalletInternalCallResponse(result: e.backup));
        }
        return result.map((e) {
          final walletBackup = WalletKeyBackup(key: e.backup, type: backupType);
          return WalletInternalCallResponse(result: walletBackup.toCbor().toCborHex());
        });
      },
    );
  }
}

sealed class WalletActionApp<RESPONSE extends Object?> extends WalletAction<RESPONSE> {
  Future<IResult<RESPONSE>> _getResult(AppWalletControllerContext context);
}

class WalletActionDecryptKeysBackup extends WalletActionApp<List<int>> {
  final String backup;
  final String password;
  final SecretWalletEncoding encoding;
  WalletActionDecryptKeysBackup(
      {required this.backup, required this.password, required this.encoding});
  @override
  WalletActionEventType get event => WalletActionEventType.decryptWalletBackup;

  @override
  Future<IResult<List<int>>> _getResult(AppWalletControllerContext context) async {
    final result = await context.cryptolib.excute(
      CryptoRequestDecodeBackup(password: password, backup: backup, encoding: encoding),
    );
    return result.map((e) => e.data);
  }
}

class WalletActionDecryptExternalWalletBackup
    extends WalletActionApp<DecryptExternalWalletBackupResponse> {
  final String backup;
  final SymKey key;

  WalletActionDecryptExternalWalletBackup({required this.backup, required this.key});
  @override
  WalletActionEventType get event => WalletActionEventType.decryptWalletBackup;

  @override
  Future<IResult<DecryptExternalWalletBackupResponse>> _getResult(
      AppWalletControllerContext context) async {
    return await context.cryptolib.excute(
      CryptoRequestDecryptExternalWalletBackup(key: key, backup: backup),
    );
  }
}

class WalletActionCryptoRequest<T extends CborTagSerializable>
    extends WalletActionApp<T> {
  final CryptoArgsCompleter<T> request;
  final List<int>? encryptedPart;

  WalletActionCryptoRequest({required this.request, this.encryptedPart});
  @override
  WalletActionEventType get event => WalletActionEventType.cryptoRequest;

  @override
  LockId get syncId => LockId.four;

  @override
  Future<IResult<T>> _getResult(AppWalletControllerContext context) async {
    return await context.cryptolib.excute<T>(request, encryptionPart: encryptedPart);
  }
}

class WalletActionDecryptWalletBackup extends WalletActionApp<WalletBackupCore> {
  final String backup;
  final String password;

  WalletActionDecryptWalletBackup({required this.backup, required this.password});
  @override
  WalletActionEventType get event => WalletActionEventType.decryptWalletBackup;

  @override
  Future<IResult<WalletBackupCore>> _getResult(AppWalletControllerContext context) async {
    WalletBackupCore walletBackup;
    try {
      final toBytes = BytesUtils.tryFromHexString(backup);
      if (toBytes != null) {
        walletBackup = WalletBackupCore.deserialize(bytes: toBytes);
      } else {
        walletBackup = WalletKeyBackup(key: backup, type: WalletBackupTypes.keystore);
      }
    } on WalletException catch (e) {
      return ResultErr.fromException(e);
    } catch (e) {
      return ResultErr.fromException(WalletExceptionConst.invalidBackupEncoding);
    }
    final decodeBytes = await context.cryptolib.excute(
      CryptoRequestDecodeBackup(
          password: password,
          backup: walletBackup.key,
          encoding: walletBackup.type.encoding),
    );
    return decodeBytes.map((e) => walletBackup.decrypt(e.data));
  }
}

class WalletActionCreateWallet extends WalletActionApp<MainWallet> {
  final String mnemonic;
  final String? passphrase;
  final String password;
  WalletActionCreateWallet(
      {required this.mnemonic, required this.passphrase, required this.password});
  @override
  WalletActionEventType get event => WalletActionEventType.createWallet;

  @override
  Future<IResult<MainWallet>> _getResult(AppWalletControllerContext context) async {
    if (passphrase?.isEmpty ?? false) {
      return ResultErr.fromException(AppCryptoExceptionConst.invalidMnemonicPassphrase);
    }
    final newWallet = context.hdWallets.createNewMainWallet(
        name: StrUtils.addNumberToMakeUnique(
            context.hdWallets.walletNames, HDWalletsConst.initializeName));
    final encrypt = await context.cryptolib.excute(CryptoRequestCreateHDWallet(
        mnemonic: mnemonic,
        passphrase: passphrase,
        password: password,
        checksum: newWallet.checkSumBytes));
    return encrypt.map((e) => newWallet.fromViewKey(e.masterKey));
  }
}

class WalletActionVerifyWalletBackup extends WalletActionApp<VerifiedMainWalletBackup> {
  final WalletBackup backup;
  final String? passhphrase;
  final String password;
  final LivePercentProgressBar? progress;
  final bool verify;
  WalletActionVerifyWalletBackup(
      {required this.backup,
      required this.passhphrase,
      required this.password,
      this.progress,
      this.verify = true});
  @override
  WalletActionEventType get event => WalletActionEventType.verifyWalletBackup;

  @override
  Future<IResult<VerifiedMainWalletBackup>> _getResult(
      AppWalletControllerContext context) async {
    try {
      if (backup.type != WalletBackupTypes.walletV3) {
        return ResultErr.fromException(WalletExceptionConst.invalidBackupData);
      }
      if (passhphrase?.isEmpty ?? false) {
        return ResultErr.fromException(AppCryptoExceptionConst.invalidMnemonicPassphrase);
      }
      final newWallet = backup.wallet
          .updateId(context.hdWallets.generateNewWalletId())
          .updateKey(context.hdWallets.generateNewWalletChecksum());
      final memoryKey = QuickCrypto.generateRandom();
      final resotreKey = await context.cryptolib.excute(
          CryptoRequestRestoreBackupMasterKey(
              rawKey: StringUtils.encode(password),
              checksum: newWallet.checkSumBytes,
              backup: BytesUtils.fromHexString(backup.key),
              passphrase: passhphrase,
              memoryKey: memoryKey));
      return resotreKey.andThenAsync((resotreKey) async {
        return await _validateBackupAccounts(
            backup: backup,
            wallet: newWallet.fromViewKey(resotreKey.encryptedKey),
            resotreKey: resotreKey,
            memoryKey: memoryKey,
            progress: progress,
            verify: verify,
            crypto: context.cryptolib);
      });
    } catch (_) {
      return ResultErr.fromException(WalletExceptionConst.invalidBackupData);
    }
  }

  Future<IResult<VerifiedMainWalletBackup>> _validateBackupAccounts({
    required WalletBackup backup,
    required CryptoRestoreBackupMasterKeyResponse resotreKey,
    required MainWallet wallet,
    required List<int> memoryKey,
    required AppBasicCryptoApi crypto,
    LivePercentProgressBar? progress,
    bool verify = false,
  }) async {
    final setupKey = resotreKey.masterKey;
    final bool validChekcsum =
        BytesUtils.bytesEqual(backup.checksum, resotreKey.checksum);
    if (!resotreKey.isValid || !validChekcsum) {
      return ResultOk(VerifiedMainWalletBackup(
          masterKeys: resotreKey.masterKey,
          chains: const [],
          dapps: const [],
          networks: const [],
          invalidAddresses: const [],
          verifiedChecksum: false,
          wallet: wallet));
    }

    final List<BackupChain> validateChains = [];
    List<ChainAccount> invalidAddresses = [];
    List<int> validateImportedKeys = [];
    List<int> validateSubwallets = [];
    bool validateMainWallet = false;
    bool isValidKeyIndex({int? subId, int? importedKey}) {
      if (subId == null && importedKey == null) return true;
      if (subId != null && importedKey != null) return false;
      if (subId != null) {
        return (resotreKey.encryptedKey.hasSubwallet(subId) &&
            wallet.hasSubwallet(subId));
      }
      return resotreKey.encryptedKey.hasImportedKey(importedKey!);
    }

    Future<bool> isValidAddress(
        {required WalletNetwork network,
        required ChainAccount address,
        int? subId,
        int? imported,
        bool verify = false}) async {
      if ((subId != null && imported != null)) {
        return false;
      }
      if (!verify) {
        if (subId != null) {
          if (validateSubwallets.contains(subId)) return true;
          if (!isValidKeyIndex(subId: subId)) {
            return false;
          }
        } else if (imported != null) {
          if (validateImportedKeys.contains(imported)) return true;
          if (!isValidKeyIndex(importedKey: imported)) {
            return false;
          }
        } else {
          if (validateMainWallet) {
            return true;
          }
        }
      }
      final param = address.toAccountParams();
      switch (param) {
        case NewDerivableAccountParams addressParams:
          final addr = await crypto.excuteWallet(
              memoryWallet: TransfableMemoryWallet(
                  encryptedData: resotreKey.encryptedKey.masterKey, memoryKey: memoryKey),
              message: WalletRequestDeriveAddress(addressParams: addressParams),
              level: CryptoProcessLevel.normal);
          return addr.fold(
            onErr: (error) {
              return false;
            },
            onOk: (addr) {
              final account =
                  addr.accountParams.toAccount(network, addr.publicKey, null, null);
              final valid = address.identifier == account.identifier;
              if (valid) {
                if (subId != null) {
                  validateSubwallets.add(subId);
                } else if (imported != null) {
                  validateImportedKeys.add(imported);
                } else {
                  validateMainWallet = true;
                }
              }
              return valid;
            },
          );

        default:
          return false;
      }
    }

    Future<ChainAccount?> reGenerateAddress(
        {required WalletNetwork network,
        required ChainAccount address,
        bool verify = false}) async {
      // final network = chain.network;
      final keyIndexes = address.derivableIndexes(request: null);
      for (final i in keyIndexes) {
        if (!isValidKeyIndex(subId: i.subId, importedKey: i.importedKeyId)) {
          return null;
        }
      }
      if (address.multiSigAccount) {
        final multiSigAccount =
            address.toAccountParams().toAccount(network, null, null, null);
        final isValid = address.identifier == multiSigAccount.identifier;
        if (isValid) return multiSigAccount;
      } else {
        ChainAccount? validAddress;
        for (final i in keyIndexes) {
          final isValid = await isValidAddress(
              network: network,
              address: address,
              imported: i.importedKeyId,
              subId: i.subId,
              verify: verify);
          if (!isValid) return null;
          validAddress = address;
        }
        return validAddress;
      }
      return null;
    }

    final totalAccount = backup.networks.fold(0, (p, c) => p + c.addresses.length);
    progress?.init(totalAccount);
    for (final c in backup.networks) {
      if (progress?.isClosed ?? false) {
        return ResultErr.fromException(AppExceptionConst.requestCanceled);
      }
      final List<ChainAccount> addresses = [];
      for (final address in c.addresses) {
        try {
          final validAddress = await reGenerateAddress(
              network: c.network, address: address, verify: verify);
          if (validAddress != null) {
            addresses.add(validAddress);
          } else {
            invalidAddresses.add(address);
          }
        } catch (_) {
          invalidAddresses.add(address);
        } finally {
          progress?.counter();
        }
      }
      validateChains.add(BackupChain(
          network: c.network, addresses: addresses, repositories: c.repositories));
    }
    return ResultOk(VerifiedMainWalletBackup(
        masterKeys: setupKey,
        dapps: backup.dapps,
        networks: validateChains,
        invalidAddresses: invalidAddresses,
        chains: backup.chains,
        wallet: wallet,
        verifiedChecksum: validChekcsum));
  }
}

class WalletActionSetup extends WalletActionApp<void> {
  final IMainWallet hdWallet;
  final String password;
  final WalletUpdateInfosData walletInfos;
  final VerifiedWalletBackup? backup;
  WalletActionSetup(
      {required this.hdWallet,
      required this.password,
      required this.walletInfos,
      this.backup});

  @override
  WalletActionEventType get event => WalletActionEventType.setup;

  @override
  Future<IResult<void>> _getResult(AppWalletControllerContext context) async {
    if (!PasswordUtils.canUseAsPassword(password)) {
      return ResultErr.fromException(WalletExceptionConst.passwordTooWeak);
    }
    final updatedWallet = hdWallet.updateSettings(update: walletInfos, network: 0);
    final result = await context.cryptolib.excute(
        CryptoRequestGenerateMasterKey.fromStorage(
            storageData: updatedWallet.data,
            key: password,
            checksum: updatedWallet.checkSumBytes,
            memoryKey: QuickCrypto.generateRandom()));
    return result.andThenAsync((e) async {
      final setup = context.hdWallets.setupNewWallet(updatedWallet);
      return setup.andThenAsync((_) async {
        final result = await context.storage.dropWalletStorage(updatedWallet);
        final setup = await result.andThenAsync((e) async {
          final result =
              await context.storage.setupNewWallet(updatedWallet, backup: backup);
          return result.andThenAsync((_) async {
            return await context.startWallet(
                params: InitWalletParams(id: updatedWallet.tokey().key, isBackup: true));
          });
        });
        return setup.andAsync((_, err) {
          if (err != null) {
            context.hdWallets.removeWallet(updatedWallet);
            return err;
          }
          return context.saveHdWallet();
        });
      });
    });
  }
}

class WalletActionInit extends WalletActionApp<void> {
  final CachedWalletPassword? initialPassword;
  WalletActionInit({this.initialPassword});

  @override
  WalletActionEventType get event => WalletActionEventType.init;

  @override
  Future<IResult<void>> _getResult(AppWalletControllerContext context) async {
    return await context.init(initialPassword: initialPassword);
  }
}

class WalletActionSwitchAppWallet extends WalletActionApp<bool> {
  final HdWalletKey wallet;
  WalletActionSwitchAppWallet({required this.wallet});
  @override
  WalletActionEventType get event => WalletActionEventType.switchWallet;

  @override
  Future<IResult<bool>> _getResult(AppWalletControllerContext context) async {
    if (wallet.key == context.wallet.key) return ResultOk(false);
    final result = await context.startWallet(params: InitWalletParams(id: wallet.key));
    return result.andThenAsync((e) async {
      final result = await context.saveHdWallet();
      return result.map((_) => true);
    });
  }
}

class WalletActionVerifyExternalWalletBackup
    extends WalletActionApp<VerifiedExternalWalletBackup> {
  final ExternalWalletBackup backup;
  final String password;
  final SymKey key;
  WalletActionVerifyExternalWalletBackup(
      {required this.backup, required this.password, required this.key});
  @override
  WalletActionEventType get event => WalletActionEventType.verifyWalletBackup;

  @override
  Future<IResult<VerifiedExternalWalletBackup>> _getResult(
      AppWalletControllerContext context) async {
    final checksum = context.hdWallets.generateNewWalletChecksum();

    final memoryKey = QuickCrypto.generateRandom();
    final resotreKey = await context.cryptolib.excute(
        CryptoRequestRestoreExternalBackupMasterKey(
            rawKey: StringUtils.encode(password),
            checksum: StringUtils.encode(checksum),
            backup: BytesUtils.fromHexString(backup.key),
            memoryKey: memoryKey,
            key: key));
    return resotreKey.map((resotreKey) {
      ExternalWallet newWallet = backup.wallet
          .toExternalWallet(resotreKey.encryptedKey.connectionInfo)
          .updateId(context.hdWallets.generateNewWalletId())
          .updateKey(checksum);
      return VerifiedExternalWalletBackup(
          wallet: newWallet.fromViewKey(resotreKey.encryptedKey),
          chains: backup.chains,
          checksum: resotreKey.checksum,
          dapps: backup.dapps,
          masterKeys: resotreKey.masterKey,
          networks: backup.networks
              .map((e) => BackupChain(
                  repositories: e.repositories,
                  addresses: e.addresses,
                  network: e.network))
              .toList());
    });
  }
}

// enum ChainWalletActions {
//   readPrivateKey,
//   moneroGenerateProof;
// }

///
///
sealed class ChainWalletAction<RESPONSE extends Object?> {
  final int chainId;
  ChainWalletAction({required this.chainId});
  Future<IResult<RESPONSE>> _getResult(BaseWalletControllerContext context);
  WalletActionAccessLevel get accessLevel;
}

class ChainWalletActionReadPrivateKey extends ChainWalletAction<LongTimeMemorySecretKey> {
  final List<DerivableIndex> indexes;
  ChainWalletActionReadPrivateKey({required super.chainId, required this.indexes});

  @override
  Future<IResult<LongTimeMemorySecretKey>> _getResult(
      BaseWalletControllerContext context) async {
    return await context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
            message: WalletRequestLognTimeSecretKeys(AccessCryptoKeysRequest(indexes)),
            memoryWallet: memoryWallet);
        return result.map((result) {
          return WalletInternalCallResponse(result: result);
        });
      },
    );
  }

  @override
  WalletActionAccessLevel get accessLevel => WalletActionAccessLevel.unlock;
}

class ChainWalletActionMoneroGenerateProof extends ChainWalletAction<String> {
  final MoneroProofTxParams params;
  final DefaultAPIProvider provider;
  final MoneroAccountIndexWithPrimaryKey account;
  ChainWalletActionMoneroGenerateProof(
      {required super.chainId,
      required this.params,
      required this.provider,
      required this.account});

  @override
  Future<IResult<String>> _getResult(BaseWalletControllerContext context) async {
    final result = await context.cryptolib.excute(
        NoneEncryptedRequestMoneroGenerateTxProof(
          txId: params.txId,
          provider: provider,
          message: params.message,
          txKeys: params.txKeys,
          receiverAddress: params.receiverAddress,
        ),
        encryptionPart: account.toCbor().encode());
    return result.map((e) => e.data);
  }

  @override
  WalletActionAccessLevel get accessLevel => WalletActionAccessLevel.readOnly;
}

class ChainWalletActionMoneroVerifyProof extends ChainWalletAction<BigInt?> {
  final MoneroVerifyProofTxParams params;
  final DefaultAPIProvider provider;

  ChainWalletActionMoneroVerifyProof(
      {required super.chainId, required this.params, required this.provider});

  @override
  Future<IResult<BigInt?>> _getResult(BaseWalletControllerContext context) async {
    final result = await context.cryptolib.excute(NoneEncryptedRequestMoneroVerifyTxProof(
      txId: params.txId,
      provider: provider,
      message: params.message,
      address: params.address,
      signature: params.proof,
    ));
    return result.map((e) => e.data.isNegative ? null : e.data);
  }

  @override
  WalletActionAccessLevel get accessLevel => WalletActionAccessLevel.readOnly;
}

class ChainWalletActionMoneroImportUtxos
    extends ChainWalletAction<MoneroAccountTxTrackerResponse> {
  final List<String> txIds;
  final DefaultAPIProvider provider;
  final List<MoneroSyncAccount> accounts;

  ChainWalletActionMoneroImportUtxos(
      {required super.chainId,
      required List<MoneroSyncAccount> accounts,
      required List<String> txIds,
      required this.provider})
      : accounts = accounts.immutable,
        txIds = txIds.immutable;

  @override
  Future<IResult<MoneroAccountTxTrackerResponse>> _getResult(
      BaseWalletControllerContext context) async {
    return await context.onAccessWallet(
      (memoryWallet, crypto) async {
        final result = await crypto.excuteWallet(
            message: WalletRequestMoneroOutputUnlocker(
                txIds: txIds, provider: provider, accounts: accounts),
            memoryWallet: memoryWallet);
        return result.map((e) => WalletInternalCallResponse(result: e));
      },
    );
  }

  @override
  WalletActionAccessLevel get accessLevel => WalletActionAccessLevel.unlock;
}
