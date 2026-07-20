part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class DefaultMainChainContext<
        NETWORKADDRESS extends IAddress,
        TOKEN extends TokenCore,
        NFT extends NFTCore,
        NETWORK extends WalletNetwork,
        TRANSACTION extends ChainTransaction,
        ADDRESS extends ChainAccount<NETWORKADDRESS, TOKEN, NFT, TRANSACTION, NETWORK>,
        CLIENT extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
        NETWORKPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>>
    extends DefaultMainChainClientContext<NETWORKADDRESS, TOKEN, NFT, NETWORK,
        TRANSACTION, ADDRESS, CLIENT, NETWORKPROVIDER>
    with
        AppSerialization
    implements
        IChainContext<NETWORKADDRESS, TOKEN, NFT, NETWORK, TRANSACTION, ADDRESS, CLIENT,
            NETWORKPROVIDER> {
  final OnceRunnerWithData<List<ADDRESS>> addressRunner = OnceRunnerWithData();
  final OnceRunnerWithData<List<NetworkContact<NETWORKADDRESS>>> contactsRunner =
      OnceRunnerWithData();
  final OnceRunnerWithData<NetworkClientConfig> serviceConfigRunner =
      OnceRunnerWithData();
  final OnceRunnerWithData<void> totalAccountBalanceRunner = OnceRunnerWithData();
  @override
  final String id;
  @override
  final InChainWalletController controller;
  @override
  final NetworkStorageManager storage;
  @override
  final InternalStreamValue<IntegerBalance> totalBalance;
  @override
  final NETWORK network;
  List<NETWORKPROVIDER> failedProviders = [];

  DefaultMainChainContext({
    required this.id,
    required this.controller,
    required this.network,
  })  : storage = NetworkStorageManager(
            id: id, network: network, database: controller.config.database),
        totalBalance = InternalStreamValue.immutable(
            IntegerBalance.zero(network.token, immutable: true),
            name: "DefaultMainChainContext.totalBalance",
            allowDispose: false);

  @override
  int index = 0;

  @override
  ADDRESS get addressSync => addresses.elementAt(index);
  @override
  ADDRESS? get addressSyncOrNull => addresses.elementAtOrNull(index);
  @override
  bool get haveAddress => addresses.isNotEmpty;

  @override
  late final services = ChainConst.services(network);

  final sync = SafeAtomicLock();

  @override
  List<ADDRESS> get addresses {
    return addressRunner.getDataOr(() => []);
  }

  @override
  List<NetworkContact<NETWORKADDRESS>> get contacts {
    return contactsRunner.getDataOr(() => <NetworkContact<NETWORKADDRESS>>[]);
  }

  /// LockId.one  default  actions
  /// LockId.five network actions
  Future<IResult<T>> callSync<T extends Object?>({
    required Future<IResult<T>> Function() fn,
    required LockId lockId,
    required ChainNotify? type,
    bool notifyProgress = false,
  }) async {
    return await sync.run(() async {
      if (notifyProgress && type != null) {
        controller.add(ChainEvent.progress(type: type, chainId: network.value));
      }
      try {
        return await IResult.block(() async => await fn());
      } finally {
        if (type != null) {
          Logging.debug(
            fn: () => AppLogData(
                runtime: "$runtimeType.${network.networkName}",
                function: " event",
                msg: "notify $type"),
          );
          controller.add(ChainEvent.complete(type: type, chainId: network.value));
        }
      }
    }, lockId: lockId);
  }

  @override
  Future<IResult<ADDRESS>> beforeImportAddress(ADDRESS address) async {
    final addresses = await getAccountAddresses();
    return addresses.andThen((addresses) {
      final any = addresses.any((element) => element.identifier == address.identifier);
      if (any) {
        return ResultErr.fromException(WalletExceptionConst.addressAlreadyExist);
      }
      return ResultOk(address);
    });
  }

  @override
  Future<IResult<ADDRESS>> afterImportAddress(
      NewAccountParams<ADDRESS> params, ADDRESS address) async {
    return ResultOk(address);
  }

  @override
  Future<IResult<List<NetworkContact<NETWORKADDRESS>>>> getAccountContacts() {
    return contactsRunner.get(onFetch: storageGetContacts);
  }

  @override
  Future<IResult<List<ADDRESS>>> getAccountAddressesInternal() async {
    final result = await storageGetAddresses();
    return result.andThenAsync((addresses) async {
      final result = await IResult.anyError(addresses.map((e) async {
        return e._getAccountData();
      }).toList());
      return result.andThenAsync((_) async {
        final index = await storageGetAddressIndex();
        return index.andThenAsync((index) async {
          final addr = addresses.elementAtOrNull(index);
          updateAddressIndexSync(addresses, addr);
          return result.map((_) => addresses);
        });
      });
    });
  }

  @override
  Future<IResult<List<ADDRESS>>> getAccountAddresses() async {
    return addressRunner.get(onFetch: getAccountAddressesInternal);
  }

  @override
  Future<IResult<ADDRESS>> importAddress(
      CryptoPublicKeyData? publicKey, NewAccountParams<ADDRESS> params) async {
    return callSync(
        fn: () async {
          if (!network.coins.contains(params.coin)) {
            return ResultErr.fromException(AppCryptoExceptionConst.invalidCoin);
          }
          return await IResult.callSync(() {
            return params.toAccount(network, publicKey, id, controller.config.database);
          }).andThenAsync((address) async {
            final before = await beforeImportAddress(address);
            return before.andThenAsync((newAddress) async {
              final result = await newAddress._setupAddress();
              return result.mapErr(
                (error) {
                  newAddress._dispose();
                  return error.exception;
                },
              ).andThenAsync((_) async {
                final after = await afterImportAddress(params, address);
                return after.andAsync((address, error) async {
                  if (address != null) {
                    addressRunner.setOk([...addresses, address].immutable);
                    updateAddressBalance(newAddress);
                    return ResultOk(address);
                  }
                  newAddress._removeAccount();
                  return error!;
                });
              });
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.address,
        notifyProgress: !haveAddress);
  }

  @override
  ADDRESS? getAddressSync({String? address, NETWORKADDRESS? networkAddress}) {
    if (networkAddress != null) {
      return addresses
          .firstWhereOrNull((element) => element.networkAddress == networkAddress);
    }
    return addresses.firstWhereOrNull((element) => element.viewAddress == address);
  }

  @override
  ReceiptAddress<NETWORKADDRESS> getOrCreateReceiptFromNetworkAddressSync(
      {NETWORKADDRESS? address, ADDRESS? account}) {
    assert(addressRunner.isReady, "addresses not initialized.");
    if (address == null && account == null) {
      throw AppInternalError.internalError("missing address or account.");
    }
    account ??= addresses.firstWhereOrNull(
        (e) => e.networkAddress == address || e.baseAddress == address?.address);
    if (account != null) {
      return ReceiptAddress<NETWORKADDRESS>(
          account: account,
          networkAddress: account.networkAddress,
          type: address?.viewType ?? account.type,
          view: address?.address ?? account.address);
    }
    final contact = contacts.firstWhereOrNull((e) => e.addressObject == address);

    if (contact != null) {
      return ReceiptAddress<NETWORKADDRESS>(
          contact: contact,
          view: contact.address,
          type: contact.addressObject.viewType,
          networkAddress: contact.addressObject);
    }
    return ReceiptAddress<NETWORKADDRESS>(
        view: address!.address, type: address.viewType, networkAddress: address);
  }

  @override
  Future<IResult<List<TOKEN>>> tokens() async {
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((e) async {
      final tokens = await Future.wait(e.map((e) => e.getAccountTokens()));
      final data =
          tokens.expand((e) => e.foldOne((tokens, erro) => tokens ?? <TOKEN>[])).toList();
      return ResultOk(data);
    });
  }

  @override
  Future<IResult<bool>> removeContact(NetworkContact<NETWORKADDRESS> contact) async {
    return callSync(
        fn: () async {
          final contacts = await getAccountContacts();
          return contacts.andThenAsync((e) async {
            if (!e.contains(contact)) return ResultOk(false);
            final remove = await storageRemoveContact(contact);
            return remove.map((_) {
              contactsRunner.setOk(e.where((e) => e != contact).toImutableList);
              return true;
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.contacts);
  }

  @override
  Future<IResult<T>> isAccountAddress<T extends ADDRESS>(T address,
      {bool validate = true}) async {
    if (!validate) {
      assert(addressRunner.isReady && this.addresses.contains(address));
      return ResultOk(address);
    }
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((addresss) {
      if (addresss.contains(address)) {
        return ResultOk(address);
      }
      return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
    });
  }

  @override
  Future<IResult<void>> switchAccount(ADDRESS address) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final updateIndex = await updateAddressIndex(address);
            return updateIndex.map<void>((_) {
              updateAddressBalance(address);
              trackPendingTxes();
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.address,
        notifyProgress: true);
  }

  @override
  Future<IResult<void>> beforeRemoveAccount(ADDRESS address) async {
    return ResultOk(null);
  }

  @override
  Future<IResult<void>> removeAccount(ADDRESS address) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final before = await beforeRemoveAccount(address);
            return before.andThenAsync((_) async {
              final remove = await address._removeAccount();
              return remove.andThenAsync((_) async {
                final currentAddress = addressSync;
                final currentAccounts = List<ADDRESS>.from(addresses);
                currentAccounts.remove(address);
                addressRunner.setOk(currentAccounts.immutable);
                final update = await updateAddressIndex(currentAddress);
                return update.andThenAsync((e) async {
                  final after = await afterRemoveAccount(address);
                  updateTotalAccountBalance();
                  return after;
                });
              });
            });
          });
        },
        lockId: LockId.one,
        notifyProgress: true,
        type: DefaultChainNotify.address);
  }

  @override
  Future<IResult<void>> afterRemoveAccount(ADDRESS address) async {
    return ResultOk(null);
  }

  @override
  Future<IResult<void>> setupAccountName({String? name, required ADDRESS address}) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final result = await address._updateAccountName(name);
            return result.map<void>((_) {});
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.address);
  }

  @override
  Future<IResult<TOKEN>> addNewToken(
      {required TOKEN token, required ADDRESS address}) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final result = await address._addToken(token);
            return result.map((token) {
              updateTokenBalance(
                  address: address, tokens: [token], isAccountAddress: true);
              return token;
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.token);
  }

  @override
  Future<IResult<void>> removeToken(
      {required TOKEN token, required ADDRESS address}) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final result = await address._removeToken(token);
            return result.map<void>((_) {});
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.token);
  }

  @override
  Future<IResult<void>> updateToken(
      {required TOKEN token,
      required ADDRESS address,
      required Token updatedToken}) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final result = await address._updateToken(updatedToken, token);
            return result.map<void>((_) {});
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.token);
  }

  @override
  Future<IResult<void>> saveTransaction(
      {required ADDRESS address, required TRANSACTION transaction}) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final result = await address._addAccountTransaction(transaction);
            return result.map<void>((_) {
              if (transaction.status.inMempool) trackPendingTxes(address: address);
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.transaction);
  }

  @override
  Future<IResult<void>> removeTransaction(
      {required ADDRESS address, required TRANSACTION transaction}) async {
    return callSync(
        fn: () async {
          final acountAddress = await isAccountAddress(address);
          return acountAddress.andThenAsync((address) async {
            final result = await address._removeAccountTransaction(transaction);
            return result.map<void>((_) {});
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.transaction);
  }

  @override
  Future<IResult<void>> updateAddressBalance(ADDRESS address,
      {bool tokens = true, bool updateTotalBalance = true, bool validate = true}) async {
    final acountAddress = await isAccountAddress(address, validate: validate);
    return acountAddress.andThenAsync((address) async {
      final result = await updateAddressBalanceInternal(address, tokens: tokens);
      return result.andThenAsync((e) {
        if (updateTotalBalance && e) return updateTotalAccountBalance();
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<void>> updateAccountBalances(
      {List<ADDRESS>? addresses, bool tokens = true}) async {
    final bool isAccountAddresses = addresses == null;
    if (addresses == null) {
      final result = await getAccountAddresses();
      if (result.isErr) return result;
      addresses = result.unwrap();
    }
    if (addresses.isEmpty) {
      return ResultOk.okVoid;
    }
    final result = await Future.wait(addresses.map((e) => updateAddressBalance(e,
        tokens: tokens, updateTotalBalance: false, validate: !isAccountAddresses)));
    updateTotalAccountBalance();
    return result.firstWhere(
      (e) => e.isErr,
      orElse: () => ResultOk.okVoid,
    );
  }

  void updateAddressIndexSync(List<ADDRESS> addresses, ADDRESS? address) {
    int index =
        switch (address) { ADDRESS address => addresses.indexOf(address), null => 0 };
    if (index.isNegative) {
      index = 0;
    }
    this.index = index;
  }

  @override
  Future<IResult<void>> updateAddressIndex(ADDRESS? address) async {
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((addresses) {
      updateAddressIndexSync(addresses, address);
      return storageSaveAddressIndex(index);
    });
  }

  @override
  Future<IResult<void>> updateCurrentAddressBalance({bool tokens = true}) async {
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((e) {
      if (e.isEmpty) return ResultOk.okVoid;
      return updateAddressBalance(addressSync, tokens: tokens, validate: false);
    });
  }

  @override
  Future<IResult<NetworkContact<NETWORKADDRESS>>> getContactFromIdentifier(
      String identifier) async {
    final contacts = await getAccountContacts();
    return contacts.andThen((e) {
      final contact = e.firstWhereOrNull((e) => e.identifier == identifier);
      if (contact == null) {
        return ResultErr.fromException(WalletExceptionConst.contactDoesNotExists);
      }
      return ResultOk(contact);
    });
  }

  @override
  Future<IResult<ADDRESS>> getAddressFromIdentifier(String identifier) async {
    final aaddresses = await getAccountAddresses();
    return aaddresses.andThen((e) {
      final address = e.firstWhereOrNull((e) => e.identifier == identifier);
      if (address == null) {
        return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
      }
      return ResultOk(address);
    });
  }

  @override
  Future<IResult<void>> getTotalAccountBalance() async {
    return totalAccountBalanceRunner.get(onFetch: () async {
      final balance = await storageGetTotalBalance();
      return balance.map((balance) {
        totalBalance.value._internalUpdateBalance(balance);
        totalBalance.notify();
      });
    });
  }

  @override
  Future<IResult<void>> updateTotalAccountBalance() async {
    BigInt totalBalance(List<ChainAccount> addresses) {
      final Map<String, BigInt> total = {
        for (final i in addresses) i.baseAddress: i.addressData.currencyBalance
      };
      return total.values
          .fold(BigInt.zero, (previousValue, element) => previousValue + element);
    }

    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((addresses) {
      final balance = totalBalance(addresses);
      bool updated = this.totalBalance.value._internalUpdateBalance(balance);
      if (updated) {
        return storageSaveTotalBalance(balance);
      }
      return ResultOk.okVoid;
    });
  }

  @override
  Future<IResult<void>> setup({List<DefaultAPIProvider> providers = const []}) async {
    List<DefaultAPIProvider> defaultProviders = [
      ...providers,
      ...ProvidersConst.getDefaultProvider<DefaultAPIProvider>(
          network: network, platform: platform)
    ];
    defaultProviders = defaultProviders
        .where((e) => e.supportByPlatform(platform) && e.supportByNetwork(network.type))
        .toList();
    defaultProviders = defaultProviders.map((e) {
      return e.withIdentifier();
    }).toList();

    final futures =
        defaultProviders.map((e) async => await storageSaveProvider(e)).toList();
    final result = await IResult.anyError<void>(futures);
    return result.andThenAsync((_) {
      return storageSaveAccount();
    });
  }

  @override
  Future<IResult<void>> importContact(NetworkContact<NETWORKADDRESS> contact) async {
    return callSync(
        fn: () async {
          final contacts = await getAccountContacts();
          return contacts.andThenAsync((contacts) async {
            if (contacts.contains(contact) ||
                contacts.any((e) => e.name == contact.name)) {
              return ResultErr.fromException(WalletExceptionConst.contactExists);
            }
            if (contact.name.length < 3 ||
                contact.addressObject.blockchainNetwork != network.type.network) {
              return ResultErr.fromException(WalletExceptionConst.invalidContactDetails);
            }
            final result = await storageSaveContact(contact);
            return result.map<void>(
              (value) {
                contactsRunner.setOk([contact, ...contacts].immutable);
              },
            );
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.contacts);
  }

  @override
  NetDerivation nextDerive(
      {required CryptoCoins coin,
      required SeedTypes seedGeneration,
      required int? subId}) {
    return BipDerivationUtils.generateAccountNextKeyIndex(
        coin: coin,
        addresses: addresses,
        seedGenerationType: seedGeneration,
        coinIndex: network.coinParam.bip32CoinType,
        subId: subId);
  }

  @override
  Future<IResult<WalletNetworkBackup>> toBackup() async {
    return callSync(
        fn: () async {
          final addresses = await getAccountAddresses();
          return addresses.andThenAsync((addresses) async {
            final repositories = await storage.readAllRepositories();
            return repositories.map((repositories) => WalletNetworkBackup(
                network: network, addresses: addresses, repositories: repositories));
          });
        },
        lockId: LockId.one,
        type: null);
  }

  @override
  AppPlatform get platform => controller.config.platform;
  @override
  AppPlatform get walletPlatform => platform;

  @override
  Future<IResult<void>> setServiceProvider(NetworkClientConfig config) async {
    return callSync(
        fn: () async {
          final result = await saveServiceConfig(config);
          return result.andThenAsync((_) async {
            final acitveService = await getActiveService();
            return acitveService.map<void>((provider) {
              onChangeProvider(provider);
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.client);
  }

  @override
  bool addressSupportedByWalletPlatform(NETWORKADDRESS addr) => true;

  @override
  Future<IResult<NETWORKPROVIDER?>> getActiveService({bool web3 = false}) async {
    final service = await getServiceConfig();
    return service.andThenAsync((config) async {
      if (!config.enableProvider) return ResultOk(null);

      final providers = await storageGetProviders();
      return providers.andThenAsync((providers) async {
        if (web3) {
          providers = providers.where((e) => e.allowInWeb3).toList();
        }
        final activeProvoders =
            config.providers.where((e) => providers.contains(e)).toList();
        IResult<NETWORKPROVIDER?> service = activeProvoders.isEmpty
            ? ResultOk(null)
            : buildProviderNetworkIdentifier(providers: activeProvoders);
        if (service.ok() != null) return service;
        config = config.copyWith(providers: []);
        if (config.allowAutoConnect) {
          service = buildProviderNetworkIdentifier(
              providers: providers, exclude: failedProviders);
          service.watch(
            onOk: (provider) {
              if (provider != null) {
                config = config.copyWith(providers: provider.providers);
              }
            },
          );
        }
        final result = await saveServiceConfig(config);
        return result.andThen((_) {
          if (!config.allowAutoConnect) return ResultOk(null);
          return service;
        });
      });
    });
  }

  NetworkClientConfig? getServiceConfigSync() => serviceConfigRunner.data;

  @override
  Future<IResult<NetworkClientConfig>> getServiceConfig() async {
    return serviceConfigRunner.get(onFetch: storageGetServiceConfig);
  }

  @override
  Future<IResult<void>> saveServiceConfig(NetworkClientConfig config) async {
    final cConfig = await getServiceConfig();
    final c = cConfig.ok();
    bool sameConfig = c == config;
    bool sameRuntimeAuto = c?.runtimeAuto == config.runtimeAuto;
    if (sameConfig && sameRuntimeAuto) {
      return ResultOk.okVoid;
    }
    final IResult<void> result = switch (sameConfig) {
      true => ResultOk(null),
      false => await storageSaveServiceConfig(config),
    };
    return result.map((_) {
      serviceConfigRunner.setOk(config);
    });
  }

  @override
  Future<IResult<void>> updateNetworkProvider(DefaultAPIProvider provider) async {
    return callSync(
        fn: () async {
          if (provider.isDefaultProvider || !provider.supportByPlatform(platform)) {
            return ResultErr.fromException(
                WalletExceptionConst.invalidNetworkProviderConfiguration);
          }
          final providers = await storageGetProviders();
          return providers.andThenAsync((providers) async {
            if (providers.contains(provider)) {
              return ResultErr.fromException(WalletExceptionConst.providerAlreadyExists);
            }
            final result = await storageSaveProvider(provider);
            return result.andThenAsync((e) async {
              final service = await getServiceConfig();
              return service.map((config) async {
                if (config.providers.any((e) => e.identifier == provider.identifier)) {
                  config = config.copyWith(providers: [
                    ...config.providers.where((e) => e.identifier != provider.identifier),
                    provider
                  ], runtimeAuto: false);
                  setServiceProvider(config);
                }
                return config;
              });
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.updateProvider);
  }

  @override
  Future<IResult<void>> removeNetworkProvider(DefaultAPIProvider provider) async {
    return callSync(
        fn: () async {
          final result = await storageRemoveProvider(provider);
          return result.andThenAsync((_) async {
            final config = await getServiceConfig();
            return config.andThenAsync((config) async {
              if (config.providers.contains(provider)) {
                final service = await getActiveService();
                return service.map((e) {
                  onChangeProvider(e);
                }).mapErr((err) {
                  onChangeProvider(null);
                  return err.exception;
                });
              }
              return ResultOk.okVoid;
            });
          });
        },
        lockId: LockId.one,
        type: DefaultChainNotify.updateProvider);
  }

  @override
  Stream<ChainEvent> get stream => controller.chainStream(network.value);

  @override
  void onClientStatusChanged(INetworkServiceNotify status) {
    controller.add(ChainEvent.complete(
      type: DefaultChainNotify.client,
      chainId: network.value,
    ));
    final provider = currentProvider;
    if (status.status == NetworkServiceStatus.error && provider != null) {
      failedProviders.add(provider);
      final config = getServiceConfigSync();
      if (config != null && config.allowAutoConnect) {
        setServiceProvider(config.copyWith(providers: []));
      }
    } else if (status.status.isConnected) {
      trackPendingTxes();
    }
  }

  @override
  Future<IResult<void>> initAsMainWallet({bool client = true}) async {
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "initAsMainWallet",
            msg: "${network.value}:${network.networkName}."));
    final accounts = await getAccountAddresses();
    return accounts.andThenAsync((_) async {
      final contacts = await getAccountContacts();
      return contacts.map<void>((_) {
        if (client) {
          this.client().then((e) {
            e.map((_) {
              getTotalAccountBalance();
              updateAccountBalances();
            });
          });
        }
      });
    });
  }

  @override
  Future<IResult<void>> trackPendingTxes({ADDRESS? address}) async {
    final addresses = await getAccountAddresses();
    if (address != null) {
      final isAccountAddress = await this.isAccountAddress(address);
      if (isAccountAddress.isErr) return isAccountAddress;
    }
    return addresses.andThenAsync((_) async {
      final addr = address ?? addressSyncOrNull;
      if (addr == null) return ResultOk(null);
      final txController = await addr._getAccountTransactionsController();
      return txController.andThenAsync((controller) async {
        final pendingTxes = controller.pendingTxes;
        if (pendingTxes.isEmpty) return ResultOk(null);
        final client = await this.client();
        return client.andThenAsync((client) async {
          final txSub = pendingTxes.map((e) async {
            final listener = await client.trackMempoolTransaction(e);
            listener?.listen(
              (tx) {
                callSync(
                    fn: () async {
                      final address = await addr._updateAccountTransactionStatus(tx);
                      address.map((_) {
                        updateAddressBalance(addr);
                      });
                      return address;
                    },
                    lockId: LockId.one,
                    type: DefaultChainNotify.transaction);
              },
            );
          });
          await txSub.wait;

          return ResultOk.okVoid;
        });
      });
    });
  }

  @override
  Future<IResult<void>> dispose() async {
    storage.dispose();
    onChangeProvider(null);
    for (final i in addresses) {
      i._dispose();
    }
    addressRunner.dispose();
    contactsRunner.dispose();
    serviceConfigRunner.dispose();
    totalAccountBalanceRunner.dispose();
    totalBalance._disposeInternal();
    return ResultOk.okVoid;
  }

  @override
  Future<IResult<void>> disconnectChain() async {
    return ResultOk.okVoid;
  }

  /// storages
  @override
  Future<IResult<List<ADDRESS>>> storageGetAddresses() async {
    final storagekey = DefaultNetworkStorageId.address;
    final data = await storage.queriesNetworkStorage(
        storage: storagekey, ordering: IDatabaseQueryOrdering.asc);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => ChainAccount.deserialize(
                  network: network,
                  id: id,
                  bytes: data,
                  database: controller.config.database),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "storageGetAddresses",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  storage.removeNetworkStorageOperation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<ADDRESS>().toList());
  }

  @override
  Future<IResult<void>> verifyBackup() async {
    if (!platform.isWeb) return ResultOk.okVoid;
    final providers = await storageGetProviders();
    return providers.andThenAsync((providers) async {
      List<DefaultAPIProvider> notSupportedProvider = [];
      List<DefaultAPIProvider> updatedProvider = [];
      for (final i in providers) {
        if (!i.supportByPlatform(platform)) {
          notSupportedProvider.add(i);
          continue;
        }
        if (i.mode.isTor) {
          updatedProvider.add(i.updateMode(NetMode.clearnet));
        }
      }
      final result = await IResult.anyError(
          notSupportedProvider.map((e) async => await storageRemoveProvider(e)));
      return result.andThenAsync((_) async {
        return await IResult.anyError(
            updatedProvider.map((e) async => await storageSaveProvider(e)));
      });
    });
  }

  @override
  Future<IResult<void>> storageSaveAddressIndex(int index) async {
    final storagekey = DefaultNetworkStorageId.addressIndex;
    final result = await storage.insertNetworkStorageRaw(
        storage: storagekey, value: index.toU32BeBytes());
    return result.map((_) {});
  }

  @override
  Future<IResult<void>> storageRemoveContact(
      NetworkContact<NETWORKADDRESS> contact) async {
    final storageKey = DefaultNetworkStorageId.contacts;
    final result =
        await storage.removeNetworkStorage(storage: storageKey, keyA: contact.identifier);
    return result.map((_) {});
  }

  @override
  Future<IResult<void>> storageSaveContact(NetworkContact<NETWORKADDRESS> contact) async {
    final storageKey = DefaultNetworkStorageId.contacts;
    final result = await storage.insertNetworkStorage(
        storage: storageKey, value: contact, keyA: contact.identifier);
    return result.map((_) {});
  }

  @override
  Future<IResult<void>> storageSaveProvider(DefaultAPIProvider provider) async {
    final storageKey = DefaultNetworkStorageId.providers;
    final result = await storage.insertNetworkStorage(
        storage: storageKey, value: provider, keyA: provider.identifier);
    return result.map((_) {});
  }

  @override
  Future<IResult<List<DefaultAPIProvider>>> storageGetProviders() async {
    final storagekey = DefaultNetworkStorageId.providers;
    final data = await storage.queriesNetworkStorage(storage: storagekey);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => DefaultAPIProvider.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "storageGetProviders",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  storage.removeNetworkStorageOperation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<DefaultAPIProvider>().toList());
  }

  @override
  Future<IResult<List<NetworkContact<NETWORKADDRESS>>>> storageGetContacts() async {
    final storagekey = DefaultNetworkStorageId.contacts;
    final data = await storage.queriesNetworkStorage(storage: storagekey);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => NetworkContact<NETWORKADDRESS>.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "storageGetContacts",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  storage.removeNetworkStorageOperation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<NetworkContact<NETWORKADDRESS>>().toList());
  }

  @override
  Future<IResult<int>> storageGetAddressIndex() async {
    final storagekey = DefaultNetworkStorageId.addressIndex;
    final data = await storage.queryNetworkStorage(storage: storagekey);
    return data.map((data) {
      final bytes = data?.data;
      if (bytes == null) return 0;
      return IntUtils.fromBytes(bytes);
    });
  }

  @override
  Future<IResult<void>> storageSaveTotalBalance(BigInt amount) async {
    final storagekey = DefaultNetworkStorageId.accountTotalBalances;
    final result = await storage.insertNetworkStorageRaw(
        storage: storagekey, value: LayoutConst.lebI256().serialize(amount));
    return result.map((_) {});
  }

  @override
  Future<IResult<BigInt>> storageGetTotalBalance() async {
    final storagekey = DefaultNetworkStorageId.accountTotalBalances;
    final data = await storage.queryNetworkStorage(storage: storagekey);
    return data.map((data) {
      final bytes = data?.data;
      if (bytes == null) return BigInt.zero;
      return LayoutConst.lebI256().deserialize(bytes).value;
    });
  }

  @override
  Future<IResult<void>> storageSaveServiceConfig(NetworkClientConfig config) async {
    final storagekey = DefaultNetworkStorageId.serviceIdentifier;
    final result = await storage.insertNetworkStorage(storage: storagekey, value: config);
    return result.map((_) {});
  }

  @override
  Future<IResult<NetworkClientConfig>> storageGetServiceConfig() async {
    final storagekey = DefaultNetworkStorageId.serviceIdentifier;
    final data = await storage.queryNetworkStorage(storage: storagekey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(NetworkClientConfig());
      final result = IResult.callSync(
        () => NetworkClientConfig.deserialize(cborBytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetServiceConfig",
            err: exception,
            trace: trace.toString()),
      );
      return result.and((identifier, _) => ResultOk(identifier ?? NetworkClientConfig()));
    });
  }

  @override
  Future<IResult<void>> storageSaveAccount() {
    return storage.insertNetworkStorage(
        value: this, storage: DefaultNetworkStorageId.account);
  }

  @override
  Future<IResult<void>> storageRemoveProvider(DefaultAPIProvider provider) async {
    final storageKey = DefaultNetworkStorageId.providers;
    final result = await storage.removeNetworkStorage(
        storage: storageKey, keyA: provider.identifier);
    return result.map((_) {});
  }

  /// serialization
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.iAccount;
  @override
  List<CborObject?> get serializationItems =>
      [network.value.toCbor(), network.toCbor(), id.toCbor()];
}
