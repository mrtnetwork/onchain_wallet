part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class IMoneroChainContext
    implements
        IChainContext<
            MoneroAddress,
            TokenCore,
            NFTCore,
            WalletMoneroNetwork,
            MoneroWalletTransaction,
            IMoneroAddress,
            MoneroNetworkClient,
            MoneroNetworkProvider> {
  Future<IResult<MoneroSyncTrackerController>> getChainTracker();
  Future<IResult<void>> saveChainTracker();
  Future<IResult<MoneroSyncChain>> getSyncChain();
  Future<IResult<void>> startSyncing({bool retryErrors = false});
  Future<IResult<void>> removeSyncingRequest(int requestId);
  Future<IResult<void>> updateAccountTxes(List<MoneroUtxosWithAccountInfo> accountUtxos);
  Future<IResult<List<MoneroUtxosWithAccountInfo>>> getPrimaryAccountUtxos(
      IMoneroAddress address);
  Future<IResult<MoneroUtxosWithAccountInfo>> getAddressUtxos(IMoneroAddress address);
  Future<IResult<List<IMoneroAddress>>> getPrimaryAccountAddresses(
      IMoneroAddress address);
  Future<IResult<void>> addSyncRequest(MoneroSyncAccountRequest request);
  IMoneroAddress? fromAccountIndex(MoneroAccountIndex address);
  Future<IResult<IMoneroAddress?>> accountFromIndex(MoneroAccountIndex index);
  Future<IResult<List<MoneroSubIndex>>> relatedAccountIndexes(DerivableIndex masterIndex);
  Future<IResult<List<MoneroAccountTxTrackerStatus>>> importUtxos(List<String> txIds);
  Future<IResult<void>> updateAllAccountBalances();
  Future<IResult<MoneroWalletClient?>> walletClient();
  Future<IResult<DefaultAPIProvider?>> getWalletProvider();
  Future<IResult<void>> updateWalletProvider(DefaultAPIProvider? provider);
  Future<IResult<MoneroSyncing?>> getSyncing();
  Future<IResult<String>> generateTxProof(
      {required MoneroProofTxParams params, required IMoneroAddress address});
  Future<IResult<BigInt?>> verifyTxProof(
      {required MoneroVerifyProofTxParams params, required IMoneroAddress address});
  Future<IResult<void>> updateSyncChain(
      {int? resetTrackerHeight, List<IMoneroAddress>? addresses});
  @override
  NextDerivationMonero nextDerive({
    required CryptoCoins coin,
    required SeedTypes seedGeneration,
    required int? subId,
    DerivableIndex? startIndex,
  });

  /// storages
  Future<IResult<MoneroSyncTrackerController>> storageGetChainTracker();
  Future<IResult<void>> storageSaveChainTracker(MoneroSyncTrackerController tracker);
  Future<IResult<MoneroSyncChain>> storageGetSyncChain();
  Future<IResult<void>> storageSaveSyncChain(MoneroSyncChain syncChain);
  Future<IResult<DefaultAPIProvider?>> storageGetWalletProvider();
  Future<IResult<void>> storageSaveWalletProvider(DefaultAPIProvider? provider);
}

final class MoneroMainChainContext extends DefaultMainChainContext<
    MoneroAddress,
    TokenCore,
    NFTCore,
    WalletMoneroNetwork,
    MoneroWalletTransaction,
    IMoneroAddress,
    MoneroNetworkClient,
    MoneroNetworkProvider> implements IMoneroChainContext {
  MoneroMainChainContext(
      {required super.id, required super.controller, required super.network});
  final OnceRunnerWithData<MoneroSyncTrackerController> chainTrackerRunner =
      OnceRunnerWithData();
  final OnceRunnerWithData<MoneroSyncChain> syncChainRunner = OnceRunnerWithData();
  final OnceRunnerWithData<MoneroWalletClient?> walletClientRunner = OnceRunnerWithData();
  final OnceRunnerWithData<MoneroSyncingDefault?> syncingRunner = OnceRunnerWithData();

  @override
  IMoneroAddress? fromAccountIndex(MoneroAccountIndex index) {
    return addresses.firstWhereOrNull((e) => e.index == index);
  }

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IMoneroAddress address,
      {bool tokens = true}) async {
    final result = await updateAllAccountBalances();
    return result.mapAsync((_) async {
      startSyncing();
      final syncing = await getSyncing();
      syncing.map((e) {
        e?.retryErrors();
      });
      return false;
    });
  }

  @override
  Future<IResult<List<IMoneroAddress>>> getAccountAddressesInternal() async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync((tracker) async {
      final addresses = await super.getAccountAddressesInternal();
      return addresses.map((addresses) {
        final addr = addresses.where((address) {
          if (!tracker.accountExists(address.index)) {
            address._removeAccount();
            return false;
          }
          return true;
        }).toList();
        return addr;
      });
    });
  }

  @override
  Future<IResult<void>> updateAccountBalances(
      {List<IMoneroAddress>? addresses, bool tokens = true}) async {
    if (addresses == null) {
      final result = await getAccountAddresses();
      if (result.isErr) return result;
      addresses = result.unwrap();
    }
    if (addresses.isEmpty) {
      return ResultOk.okVoid;
    }
    final result = await updateAddressBalanceInternal(addressSync);
    return result;
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IMoneroAddress address,
      required List<TokenCore<Object, APPToken>> tokens,
      bool isAccountAddress = false}) async {
    return ResultErr.fromException(WalletExceptionConst.networkTokenUnsuported);
  }

  @override
  Future<IResult<void>> updateWalletProvider(DefaultAPIProvider? provider) async {
    return callSync(
        fn: () async {
          final result = await storageSaveWalletProvider(provider);
          final client = await walletClient();
          client.map((client) {
            client?.dispose();
          });
          return result.map<void>((_) {
            MoneroWalletClient? newClient;
            if (provider != null) {
              newClient = MoneroWalletClient.fromProvider(
                  provider: provider,
                  network: internalNetwork,
                  netApi: controller.config.netApi);
            }
            walletClientRunner.setOk(newClient);
          });
        },
        lockId: LockId.five,
        type: null);
  }

  @override
  Future<IResult<MoneroWalletClient?>> walletClient() {
    return walletClientRunner.get(onFetch: () async {
      final storage = await storageGetWalletProvider();
      return storage.map((provider) {
        if (provider == null) return null;
        return MoneroWalletClient.fromProvider(
            provider: provider,
            network: internalNetwork,
            netApi: controller.config.netApi);
      });
    });
  }

  @override
  Future<IResult<IMoneroAddress>> afterImportAddress(
      NewAccountParams<IMoneroAddress> params, IMoneroAddress address) async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync((tracker) async {
      switch (params) {
        case MoneroNewAddressParams params:
          final client = await this.client();
          return client.andThenCatchAsync((client) async {
            int currentHeight;
            if (!tracker.initialized) {
              currentHeight = await client.getHeight();
              final result = await tracker.resetDefaultTrackerState(
                  height: currentHeight, currentHeight: currentHeight);
              if (result.isErr) return result.cast();
              if (result.isErr) return result.cast();
            } else {
              currentHeight = tracker.defaultTracker.currentHeight;
            }
            final masterKey = params.masterKey;
            final index = params.index;
            if (masterKey == null || index == null) {
              return ResultErr.fromException(WalletExceptionConst.invalidAccountData(
                  "MoneroNewAddressParams.toAccount"));
            }
            final importAccount = await tracker.addAccount(masterKey, index);
            return importAccount.andThenAsync((_) async {
              int? activationHeight = params.activeHeight;
              if (activationHeight != null) {
                activationHeight = IntUtils.min(activationHeight, currentHeight);
                if (activationHeight < currentHeight) {
                  final result = await tracker.addSyncRequest(
                      startHeight: activationHeight,
                      endHeight: currentHeight,
                      accounts: {index});
                  if (result.isErr) return result.cast();
                }
              }
              final result = await saveChainTracker();
              return result.andThenAsync((e) async {
                final syncing = await (await getSyncing()).andThenAsync((sync) {
                  return sync?.newAccountImported() ?? ResultOk(null);
                });
                return syncing.map((_) {
                  return address;
                });
              });
            });
          });
      }
    });
  }

  @override
  Future<IResult<void>> afterRemoveAccount(IMoneroAddress address) async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync((tracker) async {
      await tracker.removeAccount(address.index);
      if (!haveAddress) {
        final result = await tracker.toDefaultState();
        return result.andThenAsync((_) async {
          final syncing = await getSyncing();
          return syncing.mapAsync<void>((syncing) async {
            await syncingRunner.clear();
            syncing?.dispose();
          });
        });
      }
      return await saveChainTracker();
    });
  }

  @override
  Future<IResult<void>> addSyncRequest(MoneroSyncAccountRequest request) async {
    return callSync(
        fn: () async {
          final syncChain = await getSyncChain();
          return syncChain.andThenAsync((syncChain) async {
            final tracker = await getChainTracker();
            return tracker.andThenCatchAsync((tracker) async {
              final addresses = await getAccountAddresses();
              return addresses.andThenAsync((_) async {
                final client = await this.client();
                return await client.andThenCatchAsync((client) async {
                  final currentHeight = await client.getHeight();
                  final endHeight = request.endHeight;
                  final startHeight = request.startHeight;
                  if (endHeight > currentHeight) {
                    return ResultErr.fromException(
                        WalletExceptionConst.badAccountSyncingConfiguration);
                  }
                  Set<MoneroAccountIndex> indexes = {};
                  for (final index in request.indexes) {
                    final accountAddress = fromAccountIndex(index);
                    if (accountAddress == null) {
                      return ResultErr.fromException(
                          WalletExceptionConst.accountDoesNotFound);
                    }
                    indexes.add(index);
                  }
                  final insert = await tracker.addSyncRequest(
                      accounts: indexes, startHeight: startHeight, endHeight: endHeight);
                  return insert.andThenAsync((id) async {
                    final result = await saveChainTracker();
                    return result.andThenAsync((_) async {
                      final syncing = await getSyncing();
                      return syncing.andThenAsync((syncing) async {
                        final result = await syncing?.newRequestImported();
                        return result ?? ResultOk.okVoid;
                      });
                    });
                  });
                });
              });
            });
          });
        },
        lockId: LockId.five,
        type: MoneroChainNotify.trackerAccountChanged);
  }

  @override
  Future<IResult<MoneroSyncChain>> getSyncChain() {
    return syncChainRunner.get(onFetch: storageGetSyncChain);
  }

  @override
  Future<IResult<MoneroSyncTrackerController>> getChainTracker() async {
    return chainTrackerRunner.get(onFetch: storageGetChainTracker);
  }

  @override
  Future<IResult<void>> saveChainTracker() async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync(storageSaveChainTracker);
  }

  @override
  Future<IResult<void>> startSyncing({bool retryErrors = false}) async {
    final syncing = await getSyncing();
    return syncing.map((syncing) {
      if (retryErrors) syncing?.retryErrors();
    });
  }

  @override
  Future<IResult<void>> removeSyncingRequest(int requestId) async {
    return callSync(
        fn: () async {
          final defaultTracker = await getChainTracker();
          return defaultTracker.andThenAsync((tracker) async {
            final request = await tracker.removeRequest(requestId);
            return request.andThenAsync((request) async {
              if (request == null) return ResultOk.okVoid;
              final result = await saveChainTracker();
              return result.andThenAsync((_) async {
                if (!request.offsets.status.synced) {
                  final result = await getSyncing();
                  return result.map<void>((syncing) {
                    syncing?.syncRemoved(requestId);
                  });
                }
                return ResultOk.okVoid;
              });
            });
          });
        },
        lockId: LockId.five,
        type: MoneroChainNotify.trackerAccountChanged);
  }

  @override
  Future<IResult<IMoneroAddress?>> accountFromIndex(MoneroAccountIndex index) async {
    final addresses = await getAccountAddresses();
    return addresses
        .map((addresses) => addresses.firstWhereOrNull((e) => e.index == index));
  }

  @override
  Future<IResult<void>> updateAllAccountBalances() async {
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((addresses) async {
      final tracker = await getChainTracker();
      return tracker.andThenAsync((tracker) async {
        for (final i in addresses) {
          final utxos = tracker.getAccountUtxos(i.index);
          final result = await i._updateAccountBalance(
              utxos.where((e) => e.status.isReady).map((e) => e.amount).sum);
          if (result.isErr) return result;
        }
        updateTotalAccountBalance();
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<void>> updateSyncChain(
      {int? resetTrackerHeight, List<IMoneroAddress>? addresses}) async {
    return callSync(
        fn: () async {
          if (addresses != null) {
            if (addresses.isEmpty) {
              return ResultErr.fromException(AppInternalError.internalError(
                  "monero.updateSyncChain",
                  reason: "No account provided."));
            }
          }
          final syncChain = await storageGetSyncChain();
          return await syncChain.andThenAsync((e) async {
            final tracker = await getSyncing();
            return tracker.andThenAsync((s) async {
              syncingRunner.clear();
              await s?.dispose();
              if (e.network == internalNetwork && resetTrackerHeight != null) {
                final tracker = await getChainTracker();
                final result = await tracker.andThenAsync((tracker) async {
                  final client = await this.client();
                  return client.andThenCatchAsync((client) async {
                    final cHeight = await client.getHeight();
                    final result = await tracker.resetDefaultTrackerState(
                        height: resetTrackerHeight,
                        accounts: addresses?.map((e) => e.index).toSet(),
                        currentHeight: cHeight);

                    return result.andThenAsync((reset) async {
                      final result = await saveChainTracker();
                      return result.andThenAsync<MoneroSyncChain>((_) async {
                        syncChainRunner.setOk(e);
                        updateAllAccountBalances();
                        return ResultOk(e);
                      });
                    });
                  });
                });
                startSyncing();
                return result;
              }
              syncChainRunner.setOk(e);
              startSyncing();
              return ResultOk(e);
            });
          });
        },
        lockId: LockId.five,
        type: MoneroChainNotify.trackerAccountChanged);
  }

  @override
  Future<IResult<void>> updateAccountTxes(
      List<MoneroUtxosWithAccountInfo> accountUtxos) async {
    if (accountUtxos.isEmpty) return ResultOk.okVoid;
    Map<String, MoneroTxResponse?> txes = {};
    final txIds = accountUtxos.expand((e) => e.utxos.map((e) => e.txId())).toList();
    // final txes = await
    Future<void> getTxes(MoneroNetworkClient client, List<String> txId) async {
      txes = await client.getTxes(txIds: txIds);
    }

    DateTime? getTxTime(String txId) {
      final tx = txes[txId];
      if (tx == null) return null;
      final timestamp = tx.timestamp;
      if (timestamp == null) {
        if (tx.inPool) return DateTime.now();
        return null;
      }
      return DateTimeUtils.detectEpochUnit(timestamp) ?? DateTime.now();
    }

    List<WalletTransactionMemo> txMemos(String txId) {
      final extras = txes[txId]?.toTx().getTxExtraNonces() ?? [];
      return extras.where((e) => e.isUnknownTxExtra() && e.nonce.isNotEmpty).map((e) {
        final toString = e.tryExtractString();
        if (toString != null) return WalletTransactionMemo.fromString(toString);
        return WalletTransactionMemo.binary(e.nonce);
      }).toList();
    }

    final client = await this.client();
    return client.andThenAsync((client) async {
      final addresses = await getAccountAddresses();
      return addresses.andThenAsync((addresses) async {
        for (final i in accountUtxos) {
          if (i.utxos.isEmpty) continue;
          final account = addresses.firstWhereOrNull((e) => e.index == i.account);

          assert(account != null, "Utxos address not found.");
          if (account == null) continue;
          final txController = await account._getAccountTransactionsController();
          if (txController.isErr) return txController;
          final controller = txController.unwrap();
          final utxos = i.utxos;
          final txIds = utxos.map((e) => e.txId()).toSet().toList();
          await getTxes(client, txIds);
          for (final i in txIds) {
            final txUtxos = utxos.where((e) => e.txId() == i).toList();
            final accountTx =
                controller.byTxId(i, types: [WalletTransactionType.receive]);
            if (accountTx != null) continue;
            final txTime = getTxTime(i);
            assert(txTime != null, "transaction $i not found.");
            if (txTime == null) continue;
            final walletTx = MoneroWalletTransaction(
                txId: i,
                time: txTime.toLocal(),
                outputs: [],
                txKeys: null,
                memos: txMemos(i),
                type: WalletTransactionType.receive,
                status: WalletTransactionStatus.block,
                totalOutput: WalletTransactionIntegerAmount(
                    amount: txUtxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount),
                    network: network),
                network: network);
            final result = await saveTransaction(address: account, transaction: walletTx);
            if (result.isErr) return result;
          }
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  NextDerivationMonero nextDerive(
      {required CryptoCoins coin,
      required SeedTypes seedGeneration,
      required int? subId,
      DerivableIndex? startIndex}) {
    return BipDerivationUtils.findMoneroNextBip32Index(
        coin: coin as BipCoins,
        addresses: addresses,
        startIndex: startIndex,
        seedGenerationType: seedGeneration,
        subId: subId);
  }

  @override
  Future<IResult<DefaultAPIProvider?>> getWalletProvider() async {
    final client = await walletClient();
    return client.map((e) => e?.service);
  }

  @override
  Future<IResult<List<MoneroSubIndex>>> relatedAccountIndexes(
      DerivableIndex masterIndex) async {
    final addresses = await getAccountAddresses();
    return addresses.map((addresses) => addresses
        .where((e) => e.index.masterIndex == masterIndex)
        .map((e) => e.index.index)
        .toList());
  }

  @override
  Future<IResult<List<IMoneroAddress>>> getPrimaryAccountAddresses(
      IMoneroAddress address) async {
    final isAccountAddress = await this.isAccountAddress(address);
    return isAccountAddress.andThenAsync((address) async {
      final addresses = await getAccountAddresses();
      return addresses.map((addresses) => addresses
          .where((e) => e.index.masterIndex == address.index.masterIndex)
          .toList());
    });
  }

  @override
  Future<IResult<List<MoneroUtxosWithAccountInfo>>> getPrimaryAccountUtxos(
      IMoneroAddress address) async {
    final isAccountAddress = await this.isAccountAddress(address);
    return isAccountAddress.andThenAsync((address) async {
      final tracker = await getChainTracker();
      return tracker.andThenAsync((chainUtxos) async {
        final utxos =
            chainUtxos.getPrimaryAccountUtxosWithInfo(address.index.masterIndex);
        if (utxos.isEmpty) return ResultOk(utxos);
        final client = await this.client();
        return client.mapCatchAsync((client) async {
          final height = await client.getHeight();
          return utxos.map((e) => e.updateUtxosConfirmation(height)).toList();
        });
      });
    });
  }

  @override
  Future<IResult<MoneroUtxosWithAccountInfo>> getAddressUtxos(
      IMoneroAddress address) async {
    final isAccountAddress = await this.isAccountAddress(address);
    return isAccountAddress.andThenAsync((address) async {
      final tracker = await getChainTracker();
      return tracker.andThenAsync((chainUtxos) async {
        final utxos = chainUtxos.getAccountUtxos(address.index);
        if (utxos.isEmpty) {
          return ResultOk(MoneroUtxosWithAccountInfo(account: address.index, utxos: []));
        }
        final client = await this.client();
        return client.mapCatchAsync((client) async {
          final height = await client.getHeight();
          return MoneroUtxosWithAccountInfo(
              account: address.index,
              utxos: utxos
                  .map((e) => MoneroUtxoWithSpendingInfo.fromBlockHeight(e, height))
                  .toList());
        });
      });
    });
  }

  MoneroNetwork get internalNetwork => network.coinParam.network;

  @override
  Future<IResult<MoneroSyncing?>> getSyncing() async {
    return syncingRunner.get(onFetch: () async {
      final syncChain = await getSyncChain();
      return syncChain.andThenAsync((e) async {
        if (e.network != internalNetwork) return ResultOk(null);
        final tracker = await getChainTracker();
        return tracker.map((e) => MoneroSyncingDefault(
              tracker: e,
              clientCallBack: client,
              maxRequestThread: controller.config.cryptoLib.maxSyncThread,
              secretKeyRequestCallback: () async {
                final addresses = await getAccountAddresses();
                return addresses.andThenAsync((addresses) async {
                  return await controller.doAction(ChainWalletActionReadPrivateKey(
                      chainId: network.value,
                      indexes:
                          addresses.map((e) => e.index.masterIndex).toSet().toList()));
                });
              },
              network: network,
              connectivity: controller.config.context.platformUtls.connectivity().ok(),
              createSyncRequest: (mode, cancelable, syncingInverval) async {
                final client = await this.client();
                return client.andThenAsync(
                  (client) async {
                    final DefaultAPIProvider provider = client.networkProvider.provider;
                    return await controller.config.cryptoLib.excuteStreamRequest(
                        StreamRequestMoneroBlockTracking(
                            provider: provider,
                            flushInterval: const Duration(minutes: 2),
                            cancelable: cancelable),
                        mode: mode);
                  },
                );
              },
              onTrackerUpdated: (details) async {
                if (details.saveTracker) {
                  final result = await saveChainTracker();
                  if (result.isErr) return result;
                }
                final event = details.event;
                if (event != null) {
                  controller
                      .add(ChainEvent.progress(type: event, chainId: network.value));
                }
                final accountData = details.details;
                if (accountData != null) {
                  if (accountData.updated) updateAllAccountBalances();
                  if (accountData.utxos.isNotEmpty) updateAccountTxes(accountData.utxos);
                }
                return ResultOk.okVoid;
              },
            ));
      });
    });
  }

  @override
  Future<IResult<String>> generateTxProof(
      {required MoneroProofTxParams params, required IMoneroAddress address}) async {
    final isAccountAddress = await this.isAccountAddress(address);
    return isAccountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenAsync((client) async {
        if (params.txKeys == null) {
          final controller = await address._getAccountTransactionsController();
          if (controller.isErr) return controller.cast();
          final tx = controller.unwrap().byTxId(params.txId,
              types: [WalletTransactionType.send, WalletTransactionType.web3]);
          final txKeys = tx?.txKeys;
          if (txKeys != null) {
            params = params.copyWith(txKeys: txKeys);
          }
        }
        final tracker = await getChainTracker();
        return tracker.andThenAsync((tracker) async {
          final viewKey = tracker.getPrimaryAccount(address.index);
          if (viewKey == null) {
            return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
          }
          return await controller.doAction(ChainWalletActionMoneroGenerateProof(
              chainId: network.value,
              params: params,
              provider: client.networkProvider.provider,
              account: MoneroAccountIndexWithPrimaryKey(
                  viewKey: viewKey, index: address.index)));
        });
      });
    });
  }

  @override
  Future<IResult<List<MoneroAccountTxTrackerStatus>>> importUtxos(
      List<String> txIds) async {
    if (txIds.isEmpty) return ResultOk([]);
    final client = await this.client();
    return client.andThenAsync((client) async {
      final chainTracker = await getChainTracker();
      return chainTracker.andThenAsync((tracker) async {
        final syncAccounts =
            tracker.defaultTracker.syncAccounts.map((e) => e.toRequest()).toList();
        final utxos = await controller.doAction(ChainWalletActionMoneroImportUtxos(
            chainId: network.value,
            accounts: syncAccounts,
            provider: client.networkProvider.provider,
            txIds: txIds));
        return utxos.andThenAsync((utxos) async {
          final syncAccounts = utxos.toSyncAccounts();
          final result = tracker.importUtxos(syncAccounts);
          return result.andThenAsync((e) async {
            if (utxos.height < tracker.defaultTracker.offsets.currentHeight) {
              final syncing = await getSyncing();
              return syncing.andThenAsync((syncing) async {
                await syncing?.dispose();
                return tracker.trancateCurrentHeight(utxos.height).map((e) => utxos.txes);
              });
            }
            updateAccountTxes(e.utxos);
            updateAllAccountBalances();
            return ResultOk(utxos.txes);
          });
        });
      });
    });
  }

  @override
  Future<IResult<BigInt?>> verifyTxProof(
      {required MoneroVerifyProofTxParams params,
      required IMoneroAddress address}) async {
    final isAccountAddress = await this.isAccountAddress(address);
    return isAccountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenAsync((client) async {
        final tracker = await getChainTracker();
        return tracker.andThenAsync((tracker) async {
          final viewKey = tracker.getPrimaryAccount(address.index);
          if (viewKey == null) {
            return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
          }
          return await controller.doAction(ChainWalletActionMoneroVerifyProof(
              chainId: network.value,
              params: params,
              provider: client.networkProvider.provider));
        });
      });
    });
  }

  @override
  IResult<MoneroNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<MoneroNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = MoneroNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.monero});

  @override
  void onClientStatusChanged(INetworkServiceNotify status) {
    super.onClientStatusChanged(status);
    if (status.status.isConnected) {
      startSyncing(retryErrors: true);
    }
  }

  @override
  Future<IResult<void>> dispose() {
    syncingRunner.data?.dispose();
    syncingRunner.dispose();
    return super.dispose();
  }

  /// storages
  @override
  Future<IResult<MoneroSyncTrackerController>> storageGetChainTracker() async {
    final storageKey = MoneroNetworkStorageId.defaultTracker;
    final data = await storage.queryNetworkStorage(storage: storageKey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) {
        return ResultOk(MoneroSyncTrackerController.start(internalNetwork));
      }
      final result = IResult.callSync(
        () => MoneroSyncTrackerController.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetChainTracker",
            err: exception,
            trace: trace.toString()),
      );
      return result.mapErr((e) {
        if (data != null) {
          storage.removeNetworkStorageOperation(data.toRemoveOperation());
        }
        return e.exception;
      }).and((tracker, _) =>
          ResultOk(tracker ?? MoneroSyncTrackerController.start(internalNetwork)));
    });
  }

  @override
  Future<IResult<void>> storageSaveChainTracker(
      MoneroSyncTrackerController tracker) async {
    final storageKey = MoneroNetworkStorageId.defaultTracker;
    return await storage.insertNetworkStorage(storage: storageKey, value: tracker);
  }

  @override
  Future<IResult<MoneroSyncChain>> storageGetSyncChain() async {
    final storageKey = MoneroChainStorageId.syncChain;
    final data = await storage.queryChainStorage(storage: storageKey);
    return data.andThenAsync((final data) {
      final bytes = data?.data;
      if (data == null || bytes == null) {
        return ResultOk(MoneroSyncChain.mainnet);
      }
      final result = IResult.callSync(
        () => MoneroSyncChain.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetSyncChain",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((syncChain, err) async {
        if (err != null) {
          final remove = await storage.chainStorage
              .removeChainStorageOperation(data.toRemoveOperation());
          return remove.map((e) => MoneroSyncChain.mainnet);
        }
        return ResultOk(syncChain ?? MoneroSyncChain.mainnet);
      });
    });
  }

  @override
  Future<IResult<void>> storageSaveSyncChain(MoneroSyncChain syncChain) async {
    final storageKey = MoneroChainStorageId.syncChain;
    return await storage.insertChainStorage(storage: storageKey, value: syncChain);
  }

  @override
  Future<IResult<void>> storageSaveWalletProvider(DefaultAPIProvider? provider) async {
    final storageKey = MoneroNetworkStorageId.walletRPC;
    if (provider == null) {
      return await storage.removeNetworkStorage(storage: storageKey);
    }
    return await storage.insertNetworkStorage(storage: storageKey, value: provider);
  }

  @override
  Future<IResult<DefaultAPIProvider?>> storageGetWalletProvider() async {
    final storageKey = MoneroNetworkStorageId.walletRPC;
    final data = await storage.queryNetworkStorage(storage: storageKey);
    return data.andThenAsync((final data) {
      final bytes = data?.data;
      if (data == null || bytes == null) {
        return ResultOk(null);
      }
      final result = IResult.callSync(
        () => DefaultAPIProvider.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetWalletProvider",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((provider, err) async {
        if (err != null) {
          final remove = await storage.chainStorage
              .removeChainStorageOperation(data.toRemoveOperation());
          return remove.map((e) => null);
        }
        return ResultOk(provider);
      });
    });
  }
}
