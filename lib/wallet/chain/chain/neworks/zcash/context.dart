part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class IZcashChainContext
    implements
        IChainContext<
            ZcashAddress,
            TokenCore,
            NFTCore,
            WalletZcashNetwork,
            ZcashWalletTransaction,
            IZcashAddress,
            ZcashNetworkClient,
            ZcashNetworkProvider> {
  Future<IResult<ZcashSyncTrackerController>> getChainTracker();
  Future<IResult<ZcashSyncChain>> getSyncChain();
  Future<IResult<void>> saveChainTracker();
  Future<IResult<void>> removeSyncingRequest(int requestId);
  Future<IResult<ZcashProtocolAddressWithUtxos>> getProtocolUtxos(
      IZcashAddress address, ZcashProtocol protocol);
  Future<IResult<List<ZcashProtocolAddressWithUtxos>>> getProtocolsUtxos(
      IZcashAddress address);
  Future<IResult<void>> updateSyncChain(
      {int? resetTrackerHeight, List<IZcashAddress>? addresses});
  Future<IResult<void>> updateAccountTxes(List<ZcashUtxosWithAccountInfo> accountUtxos);
  Future<IResult<List<ZcashUtxosWithAccountInfo>>> getAccountUtxos(IZcashAddress address,
      {bool isAccountAddress = false, ZcashProtocol? protocol});
  Future<IResult<void>> updateTransparentAccountUtxos(IZcashAddress address,
      {bool isAccountAddress = false});
  Future<IResult<void>> updateAllAccountBalances();
  Future<IResult<void>> addSyncRequest(ZcashSyncAccountRequest requests);
  Future<IResult<void>> clearChainMerkleState();
  Future<IResult<void>> startSyncing();
  IZcashAddress? fromReceiverSync(ZcashAccountInfoShield info);
  Future<IResult<ZcashSyncing?>> getSyncing();
  Future<IResult<ZcashSyncTrackerController>> storageGetChainTracker();
  Future<IResult<void>> storageSaveChainTracker(ZcashSyncTrackerController tracker);
  Future<IResult<ZcashSyncChain>> storageGetSyncChain();

  Future<IResult<void>> storageRemoveChainMerkleState();

  List<BigInt> saplingAccountsDiversifierIndexsSync();
  TableStructAColums storageGetTrackerMerkleColumn();

  List<ZcashProtocol> supportedProtocols();

  ZcashNetwork get internalNetwork;
  ZcashSyncChain get accountSyncChain;
}

final class ZcashMainChainContext extends DefaultMainChainContext<
    ZcashAddress,
    TokenCore,
    NFTCore,
    WalletZcashNetwork,
    ZcashWalletTransaction,
    IZcashAddress,
    ZcashNetworkClient,
    ZcashNetworkProvider> implements IZcashChainContext {
  ZcashMainChainContext(
      {required super.id, required super.controller, required super.network});
  final OnceRunnerWithData<ZcashSyncTrackerController> chainTrackerRunner =
      OnceRunnerWithData();
  final OnceRunnerWithData<ZcashSyncChain> syncChainRunner = OnceRunnerWithData();
  final OnceRunnerWithData<ZcashSyncingDefault?> syncingRunner = OnceRunnerWithData();
  final Map<ZcashTransparentAddress, OnceRunnerResult<void>>
      updateTransparentUtxosRunner = {};
  @override
  ZcashSyncChain get accountSyncChain => switch (network.coinParam.network) {
        ZcashNetwork.mainnet => ZcashSyncChain.mainnet,
        ZcashNetwork.testnet => ZcashSyncChain.testnet,
        ZcashNetwork.regtest => ZcashSyncChain.regtest,
      };
  @override
  ZcashNetwork get internalNetwork => network.coinParam.network;
  @override
  Future<IResult<List<IZcashAddress>>> getAccountAddressesInternal() async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync((tracker) async {
      final addresses = await super.getAccountAddressesInternal();
      return addresses.map((addresses) {
        final addr = addresses.where((address) {
          final sheildsReceiver = address.account.shieldAccounts();
          for (final i in sheildsReceiver) {
            if (!tracker.accountExists(i)) {
              address._removeAccount();
              return false;
            }
          }
          return true;
        }).toList();
        return addr;
      });
    });
  }

  @override
  Future<IResult<void>> afterRemoveAccount(IZcashAddress address) async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync((tracker) async {
      final shieldAccounts = address.account.shieldAccounts();
      for (final i in shieldAccounts) {
        final result = await tracker.removeAccount(i);
        if (result.isErr) return result;
      }
      if (!addresses.any((e) => e.account.hasSheildAccount())) {
        final result = await tracker.toDefaultState();
        return result.andThenAsync((_) async {
          final result = await clearChainMerkleState();
          return result.andThenAsync((_) async {
            final syncing = await getSyncing();
            return syncing.mapAsync<void>((syncing) async {
              await syncingRunner.clear();
              syncing?.dispose();
            });
          });
        });
      }
      return await saveChainTracker();
    });
  }

  @override
  Future<IResult<IZcashAddress>> beforeImportAddress(IZcashAddress address) async {
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((addresses) {
      final exists = addresses.any((element) => element.identifier == address.identifier);
      if (exists) {
        return ResultErr.fromException(WalletExceptionConst.addressAlreadyExist);
      }
      final receivers = addresses.expand((e) => e.account.receivers).toList();
      for (final i in address.account.receivers) {
        if (receivers.contains(i)) {
          return ResultErr.fromException(WalletExceptionConst.addressAlreadyExist);
        }
      }
      return ResultOk(address);
    });
  }

  @override
  Future<IResult<IZcashAddress>> afterImportAddress(
      NewAccountParams<IZcashAddress> params, IZcashAddress address) async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync((tracker) async {
      switch (params) {
        case ZcashShieldAddressParams params:
          if (!tracker.initialized) {
            final result = await tracker.resetDefaultTrackerState(
                height: params.currentHeight, currentHeight: params.currentHeight);
            if (result.isErr) return result.cast();
          }
          final sheildsReceiver = address.account.shieldAccounts();

          Set<ZcashAccountInfoShield> accounts = {};
          for (final i in sheildsReceiver) {
            final fvk = params.fvks.firstWhere((e) => e.protocol == i.protocol);
            final importAccount = await tracker.addAccount(fvk, i);
            if (importAccount.isErr) return importAccount.cast();

            if (params.currentHeight == i.activationHeight) continue;
            accounts.add(i);
          }
          if (accounts.isNotEmpty) {
            final minHeight =
                accounts.map((e) => e.activationHeight).reduce(IntUtils.min);
            final result = await tracker.addSyncRequest(
                startHeight: minHeight,
                endHeight: params.currentHeight,
                accounts: accounts);
            if (result.isErr) return result.cast();
          }

          final result = await saveChainTracker();

          return result.andThenAsync((e) async {
            final syncing = await (await getSyncing()).andThenAsync((sync) {
              return sync?.newAccountImported() ?? ResultOk(null);
            });
            return syncing.map((_) => address);
          });
        default:
          return ResultOk(address);
      }
    });
  }

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(IZcashAddress address,
      {bool tokens = true}) async {
    for (final i in addresses) {
      final utxos = await getAccountUtxos(i);
      await utxos.andThenAsync((_) async {
        final result = await updateAllAccountBalances();
        return result.map((_) {
          startSyncing();
        });
      });
    }
    return ResultOk(false);
  }

  @override
  Future<IResult<void>> updateAllAccountBalances() async {
    final addresses = await getAccountAddresses();
    return addresses.andThenAsync((addresses) async {
      final tracker = await getChainTracker();
      return tracker.andThenAsync((tracker) async {
        for (final i in addresses) {
          final utxos = tracker.getAccountInfoUtxos(i.account);
          final transparent = await i._getAccountTransparetUtxos();
          if (transparent.isErr) return transparent;
          final result = await i._updateAccountBalance(<ZcashUtxo>[
            ...utxos,
            ...transparent.unwrap()
          ].where((e) => e.status.isReady).map((e) => e.amount).sum);
          if (result.isErr) return result;
        }
        updateTotalAccountBalance();
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required IZcashAddress address,
      required List<TokenCore<Object, APPToken>> tokens,
      bool isAccountAddress = false}) async {
    return ResultErr.fromException(WalletExceptionConst.networkTokenUnsuported);
  }

  @override
  Future<IResult<ZcashSyncChain>> getSyncChain() {
    return syncChainRunner.get(onFetch: storageGetSyncChain);
  }

  @override
  Future<IResult<ZcashSyncing?>> getSyncing() async {
    return syncingRunner.get(onFetch: () async {
      final syncChain = await getSyncChain();
      return syncChain.andThenAsync((e) async {
        if (e.network != internalNetwork) return ResultOk(null);
        final tracker = await getChainTracker();
        return tracker.map((e) => ZcashSyncingDefault(
              tracker: e,
              clientCallBack: client,
              maxRequestThread: controller.config.context.cryptoLib.maxSyncThread,
              network: network,
              connectivity: controller.config.context.platformUtls.connectivity().ok(),
              createSyncRequest: (mode, cancelable, syncingInverval, tracker) async {
                final client = await this.client();
                return client.andThenAsync(
                  (client) async {
                    final DefaultAPIProvider provider = client.networkProvider.provider;
                    final column = storageGetTrackerMerkleColumn();
                    return await controller.config.cryptoLib.excuteStreamRequest(
                        StreamRequestZcashBlockTracking(
                            provider: provider,
                            merkleColumn: column,
                            flushInterval: const Duration(minutes: 2),
                            cancelable: cancelable),
                        mode: mode);
                  },
                );
              },
              createNullifierRequest: (cancelable) async {
                final client = await this.client();
                return client.andThenAsync(
                  (client) async {
                    final DefaultAPIProvider provider = client.networkProvider.provider;
                    return await controller.config.cryptoLib.excuteStreamRequest(
                        StreamRequestZcashNullifierTracking(
                            provider: provider, cancelable: cancelable));
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
  Future<IResult<ZcashSyncTrackerController>> getChainTracker() async {
    return chainTrackerRunner.get(onFetch: storageGetChainTracker);
  }

  @override
  Future<IResult<void>> clearChainMerkleState() async {
    return await storageRemoveChainMerkleState();
  }

  @override
  Future<IResult<void>> saveChainTracker() async {
    final tracker = await getChainTracker();
    return tracker.andThenAsync(storageSaveChainTracker);
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
        type: ZcashChainNotify.trackerAccountChanged);
  }

  @override
  Future<IResult<void>> updateSyncChain(
      {int? resetTrackerHeight, List<IZcashAddress>? addresses}) async {
    return callSync(
        fn: () async {
          Set<ZcashAccountInfoShield>? shieldAccounts;
          if (addresses != null) {
            if (addresses.isEmpty) {
              return ResultErr.fromException(AppInternalError.internalError(
                  "zcash.updateSyncChain",
                  reason: "No account provided."));
            }
            shieldAccounts = {};
            final isAccountAddress =
                await IResult.anyError(addresses.map((e) => this.isAccountAddress(e)));
            if (isAccountAddress.isErr) return isAccountAddress;
            for (final i in addresses) {
              final shields = i.account.shieldAccounts();
              if (shields.isEmpty) {
                return ResultErr.fromException(AppInternalError.internalError(
                    "zcash.updateSyncChain",
                    reason: "No Shield account selected."));
              }
              shieldAccounts.addAll(shields);
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
                    final cHeight = await client.getLatestBlockHeight();
                    final result = await tracker.resetDefaultTrackerState(
                        height: resetTrackerHeight,
                        accounts: shieldAccounts,
                        currentHeight: cHeight);

                    return result.andThenAsync((reset) async {
                      final result = await saveChainTracker();
                      return result.andThenAsync<ZcashSyncChain>((_) async {
                        syncChainRunner.setOk(e);
                        updateAllAccountBalances();
                        if (!reset) return ResultOk(e);
                        final result = await clearChainMerkleState();
                        return result.map<ZcashSyncChain>((_) => e);
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
        type: ZcashChainNotify.trackerAccountChanged);
  }

  @override
  Future<IResult<void>> updateAccountTxes(List<ZcashUtxosWithAccountInfo> accountUtxos,
      {List<ZcashTransactionWithBlockInfo> cachedTxes = const []}) async {
    if (accountUtxos.isEmpty) return ResultOk.okVoid;
    final lock = SafeAtomicLock();
    Map<ZcashTxId, ZcashTransactionWithBlockInfo?> transactions = {};
    for (final tx in cachedTxes) {
      transactions[tx.txId] = tx;
    }
    final client = await this.client();
    return client.andThenCatchAsync((client) async {
      Future<ZcashTransactionWithBlockInfo?> getTransactionWithBlockInfo(
          ZcashTxId txId) async {
        return await lock.run(() async {
          if (transactions.containsKey(txId)) {
            final tx = transactions[txId];
            if (tx == null) return null;
            return tx;
          }
          final tx = await client.getBlockTransactionWithBlockInfo(txId);
          transactions[txId] = tx;
          return tx;
        });
      }

      Future<int?> txTime(ZcashUtxo utxo) async {
        switch (utxo) {
          case ZcashUtxoTransparent _:
            final tx = await getTransactionWithBlockInfo(utxo.txId());
            return tx?.block.time;
          case ZcashUtxoShield utxo:
            return utxo.utxo.blocktime;
        }
      }

      Future<List<WalletTransactionMemo>> transparentMemos(ZcashTxId txId) async {
        final tx = await getTransactionWithBlockInfo(txId);
        assert(tx != null, "transaction not found.");
        if (tx == null) return [];
        final outputs = tx.transaction.transparentBundle?.vout ?? [];
        final memosContent = outputs.map((e) {
          final content = BitcoinScriptUtils.getOpRetrunContent(e.scriptPubKey);
          if (content == null) return null;
          final toBytes = StringUtils.tryToBytes(content);
          if (toBytes == null) return WalletTransactionMemo.fromString(content);
          return WalletTransactionMemo(toBytes);
        }).toList();
        return memosContent.whereType<WalletTransactionMemo>().toList();
      }

      Future<WalletTransactionMemo?> sheildOutputMemo(ZcashUtxo utxo) async {
        // WalletTransactionMemo? parseUtxoMemo(String?)
        switch (utxo) {
          case ZcashUtxoTransparent():
            return null;
          case ZcashUtxoShield utxo:
            final memoBytes = utxo.utxo.memo;
            if (memoBytes == null) return null;
            final wZeros =
                BytesUtils.trimLeadingZero(BytesUtils.trimTrailingZero(memoBytes));
            if (wZeros.isEmpty) return null;
            final memo = WalletTransactionMemo(wZeros);
            return memo;
        }
      }

      final addresses = await getAccountAddresses();
      return addresses.andThenAsync((addresses) async {
        for (final i in accountUtxos) {
          if (i.utxos.isEmpty) continue;
          final account =
              addresses.firstWhereOrNull((e) => e.account.receivers.contains(i.account));
          assert(account != null, "Utxos address not found.");
          if (account == null) continue;
          final protocolAddresses = account.account.protocolAddresses();
          final protocolAddress = protocolAddresses
              .firstWhereOrNull((e) => e.supportedProtocols.contains(i.account.protocol));
          assert(protocolAddress != null);
          if (protocolAddress == null) continue;
          final controller = await account._getAccountTransactionsController();
          final result = await controller.andThenAsync((controller) async {
            final utxos = i.utxos;
            final txIds = utxos.map((e) => e.txId()).toSet().toList();
            for (final i in txIds) {
              final txTransparentMemos = await transparentMemos(i);
              final utxo = utxos.where((e) => e.txId() == i).toList()
                ..sort((a, b) => a.protocol.sheilded ? -1 : 1);
              final transaction =
                  controller.byTxId(i.txId, types: [WalletTransactionType.receive]);
              List<ZcashWalletTransactionOutput> outputs = [];
              int? time = transaction?.time.millisecondsSinceEpoch;
              if (transaction != null) {
                outputs = transaction.outputs
                    .where((e) =>
                        protocolAddresses.contains(e.to) && e.to != protocolAddress)
                    .toList();
              }
              final newUtxos = await Future.wait(utxo.map((e) async =>
                  ZcashWalletTransactionOutput(
                      amount: WalletTransactionIntegerAmount(
                          amount: e.utxo.amount, network: network),
                      to: protocolAddress,
                      memo: await sheildOutputMemo(e.utxo))));
              outputs = [
                ...outputs,
                ...newUtxos,
              ];

              for (final i in utxo) {
                time ??= await txTime(i.utxo);
              }
              Logging.danger(
                when: () => time == null,
                fn: () => AppLogData(
                    runtime: runtimeType,
                    function: "_addNewWalletTxes",
                    msg: "Failed to fetch block time tx: ${i.txId}"),
              );
              final walletTx = ZcashWalletTransaction(
                  txId: i.txId,
                  time: switch (time) {
                    null => null,
                    int time => DateTimeUtils.detectEpochUnit(time)
                  },
                  outputs: outputs,
                  memos: txTransparentMemos,
                  type: WalletTransactionType.receive,
                  status: WalletTransactionStatus.block,
                  totalOutput: WalletTransactionIntegerAmount(
                      amount: outputs.fold<BigInt>(
                          BigInt.zero, (p, c) => p + c.amount.amount.balance),
                      network: network),
                  network: network);
              final result = switch (transaction) {
                null => await saveTransaction(address: account, transaction: walletTx),
                _ => await account._updateAccountTransactionStatus(walletTx)
              };
              if (result.isErr) return result;
            }
            return ResultOk.okVoid;
          });
          if (result.isErr) return result;
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<void>> updateTransparentAccountUtxos(IZcashAddress address,
      {bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) {
      final transparentAddress = address.account.toTransparentAddress();
      TransparentUtxoOwner? receiver;
      if (transparentAddress != null) {
        receiver = address.account.toTransparentWatchOnlyUtxoOwner();
      }
      if (transparentAddress == null || receiver == null) {
        return ResultOk(null);
      }
      final runner =
          updateTransparentUtxosRunner[transparentAddress] ??= OnceRunnerResult();
      return runner.get(
          readyOnError: false,
          cachedTimeout: Duration(seconds: network.coinParam.averageBlockTime),
          onFetch: () async {
            final utxoOwner = address.account.toTransparentWatchOnlyUtxoOwner();
            final receiver = address.account.getTransparentReceiver();
            if (utxoOwner == null || receiver == null) return ResultOk.okVoid;
            final client = await this.client();
            return client.andThenCatchAsync((client) async {
              final utxos = await address._getAccountTransparetUtxos();
              return utxos.andThenAsync((existUtxos) async {
                final utxos = await client.getTransparentAddressUtxos(utxoOwner,
                    exclude: existUtxos);
                final newUtxos = await address
                    ._updateAccountTransparentUtxos(utxos.map((e) => e.utxo).toList());
                return newUtxos.andThenAsync((newUtxos) {
                  return updateAccountTxes([
                    ZcashUtxosWithAccountInfo(
                        account: receiver,
                        utxos: newUtxos
                            .map((e) => ZcashUtxoWithSpendingInfo.unconfirmed(e))
                            .toList())
                  ],
                      cachedTxes: utxos
                          .map((e) => e.transaction)
                          .whereType<ZcashTransactionWithBlockInfo>()
                          .toList());
                });
              });
            });
          },
          onFetched: () => ResultOk.okVoid);
    });
  }

  @override
  Future<IResult<List<ZcashUtxosWithAccountInfo>>> getAccountUtxos(
    IZcashAddress address, {
    bool isAccountAddress = true,
    ZcashProtocol? protocol,
  }) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: isAccountAddress);
    return accountAddress.andThenAsync((e) async {
      if (protocol?.isTransparent ?? true) {
        await updateTransparentAccountUtxos(address, isAccountAddress: true);
      }

      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final height = await client.getLatestBlockHeight();
        final tracker = await getChainTracker();
        return tracker.andThenAsync((tracker) async {
          final List<ZcashUtxosWithAccountInfo> utxos = [];
          for (final receiver in address.account.receivers) {
            switch (receiver.protocol) {
              case ZcashProtocol.transparent:
                if (protocol?.isTransparent ?? true) {
                  final transparentUtxos = await address._getAccountTransparetUtxos();
                  if (transparentUtxos.isErr) return transparentUtxos.cast();
                  final tUtxos = transparentUtxos.unwrap();
                  if (tUtxos.isEmpty) continue;
                  utxos.add(ZcashUtxosWithAccountInfo(
                      account: receiver,
                      utxos: tUtxos
                          .map(
                              (e) => ZcashUtxoWithSpendingInfo.fromBlockHeight(e, height))
                          .toList()));
                }

                break;
              case ZcashProtocol addressProtocol
                  when (protocol == null || protocol == addressProtocol):
                final sUtxos =
                    tracker.getAccountUtxos(receiver.cast<ZcashAccountInfoShield>());
                if (sUtxos.isEmpty) continue;
                utxos.add(ZcashUtxosWithAccountInfo(
                    account: receiver,
                    utxos: sUtxos
                        .map((e) => ZcashUtxoWithSpendingInfo.fromBlockHeight(e, height))
                        .toList()));
                break;
              default:
                break;
            }
          }
          return ResultOk(utxos);
        });
      });
    });
  }

  @override
  Future<IResult<void>> addSyncRequest(ZcashSyncAccountRequest request) async {
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
                  final currentHeight = await client.getLatestBlockHeight();
                  final endHeight = request.endHeight;
                  final startHeight = request.startHeight;
                  if (endHeight > currentHeight) {
                    return ResultErr.fromException(
                        WalletExceptionConst.badAccountSyncingConfiguration);
                  }
                  Set<ZcashAccountInfoShield<ZUnifiedReceiver>> shieldAccounts = {};
                  for (final address in request.accounts) {
                    final accountAddress = fromReceiverSync(address);
                    if (accountAddress == null) {
                      return ResultErr.fromException(
                          WalletExceptionConst.accountDoesNotFound);
                    }
                    shieldAccounts.add(address);
                  }
                  final insert = await tracker.addSyncRequest(
                      accounts: shieldAccounts,
                      startHeight: startHeight,
                      endHeight: endHeight);
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
        type: ZcashChainNotify.trackerAccountChanged);
  }

  @override
  IZcashAddress? fromReceiverSync(ZcashAccountInfoShield info) {
    return addresses.firstWhereOrNull((e) => e.account.receivers.contains(info));
  }

  @override
  bool addressSupportedByWalletPlatform(ZcashAddress addr) {
    final protocols = supportedProtocols();
    return addr.supportedProtocols.any((e) => protocols.contains(e));
  }

  @override
  List<ZcashProtocol> supportedProtocols() {
    return ZcashProtocol.values;
  }

  @override
  IResult<ZcashNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<ZcashNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = ZcashNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  Future<IResult<void>> startSyncing({bool retryErrors = false}) async {
    final syncing = await getSyncing();
    return syncing.map((syncing) {
      if (retryErrors) syncing?.retryErrors();
    });
  }

  ChainMerkleState createDefaultChainMerkleState() {
    return ChainMerkleState(
        sapling: SaplingShardTree(SaplingShardStore(FakeSaplingHashable())),
        orchard: OrchardShardTree(OrchardShardStore(FakeOrchardHashable())),
        orchardSabtreeIndex: 0,
        saplingSubtreeIndex: 0);
  }

  @override
  Future<IResult<ZcashProtocolAddressWithUtxos>> getProtocolUtxos(
      IZcashAddress address, ZcashProtocol protocol,
      {bool isAccountAddress = false}) async {
    final addr = await this.isAccountAddress(address, validate: !isAccountAddress);
    return addr.andThenAsync((address) async {
      final index = address.account.getProtocolReceiver(protocol);
      final protocolAddress = address.account.toProtocolAddress(protocol);
      if (index == null || protocolAddress == null) {
        return ResultErr.fromException(WalletExceptionConst.accountDoesNotFound);
      }
      switch (index.protocol) {
        case ZcashProtocol.orchard:
        case ZcashProtocol.sapling:
          final tracker = await getChainTracker();
          return tracker.map((tracker) {
            final ZcashAccountInfoShield sheildIndex = index.cast();
            final utxos = tracker.getAccountUtxos(sheildIndex);
            final pendingUtxos = tracker.getAccountPendingUtxos(sheildIndex);
            return ZcashProtocolAddressWithUtxos(
                address: protocolAddress,
                protocol: protocol,
                spendableUtxos: utxos,
                pendingUtxos: pendingUtxos,
                totalActiveBalance: IntegerBalance.token(
                    utxos.map((e) => e.amount).sum, network.token, immutable: true),
                totalPendingBalance: IntegerBalance.token(
                    pendingUtxos.map((e) => e.amount).sum, network.token,
                    immutable: true));
          });
        case ZcashProtocol.transparent:
          final transparentUtxos = await address._getAccountTransparetUtxos();
          return transparentUtxos.map((utxos) {
            return ZcashProtocolAddressWithUtxos(
                address: protocolAddress,
                protocol: protocol,
                spendableUtxos: utxos,
                pendingUtxos: [],
                totalActiveBalance: IntegerBalance.token(
                    utxos.map((e) => e.amount).sum, network.token,
                    immutable: true),
                totalPendingBalance: IntegerBalance.zero(network.token));
          });
      }
    });
  }

  @override
  Future<IResult<List<ZcashProtocolAddressWithUtxos>>> getProtocolsUtxos(
      IZcashAddress address) async {
    final addr = await isAccountAddress(address);
    return addr.andThenAsync((address) async {
      final protocols = address.account.protocols;
      return IResult.anyError(
          protocols.map((e) => getProtocolUtxos(address, e, isAccountAddress: true)));
    });
  }

  @override
  List<BigInt> saplingAccountsDiversifierIndexsSync() {
    return addresses
        .expand((e) => e.account.receivers)
        .whereType<ZcsahAccountInfoSapling>()
        .map((e) => e.diversifierIndex.toU128())
        .toList()
      ..sort();
  }

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
  Future<IResult<ZcashSyncTrackerController>> storageGetChainTracker() async {
    final storageKey = ZcashNetworkStorageId.defaultTracker;
    final data = await storage.queryNetworkStorage(storage: storageKey);
    return data.andThenAsync((final data) {
      final bytes = data?.data;
      if (data == null || bytes == null) {
        return ResultOk(ZcashSyncTrackerController.start(network.coinParam.network));
      }
      final result = IResult.callSync(
        () => ZcashSyncTrackerController.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetChainTracker",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((tracker, err) async {
        if (err != null) {
          final remove =
              await storage.removeNetworkStorageOperation(data.toRemoveOperation());
          return remove
              .map((e) => ZcashSyncTrackerController.start(network.coinParam.network));
        }
        return ResultOk(
            tracker ?? ZcashSyncTrackerController.start(network.coinParam.network));
      });
    });
  }

  @override
  Future<IResult<void>> storageSaveChainTracker(
      ZcashSyncTrackerController tracker) async {
    final storageKey = ZcashNetworkStorageId.defaultTracker;
    return await storage.insertNetworkStorage(storage: storageKey, value: tracker);
  }

  @override
  TableStructAColums storageGetTrackerMerkleColumn() {
    final storageKey = ZcashNetworkStorageId.chainTreeState;
    return storage.createTableCulumn(storage: storageKey);
  }

  @override
  Future<IResult<void>> storageRemoveChainMerkleState() async {
    final storageKey = ZcashNetworkStorageId.chainTreeState;
    return await storage.removeNetworkStorage(storage: storageKey);
  }

  @override
  Future<IResult<ZcashSyncChain>> storageGetSyncChain() async {
    final storageKey = ZcashChainStorageId.syncChain;
    final data = await storage.queryChainStorage(storage: storageKey);
    return data.andThenAsync((final data) {
      final bytes = data?.data;
      if (data == null || bytes == null) {
        return ResultOk(ZcashSyncChain.mainnet);
      }
      final result = IResult.callSync(
        () => ZcashSyncChain.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "storageGetSyncChain",
            msg: "Network:${network.networkName}",
            err: exception,
            trace: trace.toString()),
      );
      return result.andAsync((syncChain, err) async {
        if (err != null) {
          final remove = await storage.chainStorage
              .removeChainStorageOperation(data.toRemoveOperation());
          return remove.map((e) => ZcashSyncChain.mainnet);
        }
        return ResultOk(syncChain ?? ZcashSyncChain.mainnet);
      });
    });
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.walletD});
}
