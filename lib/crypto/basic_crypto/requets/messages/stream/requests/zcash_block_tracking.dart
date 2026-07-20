import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/zcash_context.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/sync_account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/zcash.dart'
    show ZcashBlockTrackingRequestOffset;
import 'package:zcash_dart/zcash.dart';

final class StreamRequestZcashBlockTracking extends IsolateStreamRequest<
    ZcashSyncOffsetResponse, ZcashBlockTrackingRequestOffset> {
  StreamRequestZcashBlockTracking(
      {required this.provider,
      required this.merkleColumn,
      this.flushInterval = const Duration(minutes: 1),
      super.cancelable});
  final DefaultAPIProvider provider;
  final TableStructAColums merkleColumn;
  final Duration flushInterval;

  factory StreamRequestZcashBlockTracking.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: StreamIsolateMethod.zcashAccountTracker.tag);
    return StreamRequestZcashBlockTracking(
      provider: DefaultAPIProvider.deserialize(object: values.objectAt<CborTagValue>(0)),
      merkleColumn: TableStructAColums.deserialize(obj: values.objectAt(1)),
      flushInterval: Duration(seconds: values.rawValueAt(2)),
    );
  }
  @override
  StreamIsolateMethod get method => StreamIsolateMethod.zcashAccountTracker;

  Future<IResult<ChainMerkleState>> getChainState(
      {required AppContext context, required OnChainCryptoContext crypto}) async {
    final merkleBytes = await context.database.readColumn(merkleColumn);
    return merkleBytes.mapCatch(
      (data) {
        final bytes = data?.data;
        if (bytes == null) {
          return ChainMerkleState(
              sapling: SaplingShardTree(SaplingShardStore(crypto.saplingHashable())),
              orchard: OrchardShardTree(OrchardShardStore(crypto.orchardHashable())),
              orchardSabtreeIndex: 0,
              saplingSubtreeIndex: 0);
        }
        return ChainMerkleState.deserialize(
          bytes: bytes,
          orchardHashable: crypto.orchardHashable(),
          saplingHashable: crypto.saplingHashable(),
        );
      },
      logging: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "getChainState",
          err: exception,
          trace: trace.toString()),
    );
  }

  Future<IResult<void>> updateMerkeState(
      {required AppContext context,
      required ZcashClient client,
      required List<ScannedBlock> blocks,
      required NativeMerkleController controller,
      required OnChainCryptoContext crypto}) async {
    final IResult<SerializableMerkleInsertReport?> merkleState =
        await IResult.call(() async {
      return await controller.updateState(blocks, continually: true);
    });
    return merkleState.andThenAsync((report) async {
      if (report == null || closed) return ResultOk.okVoid;
      final timeout = Duration(minutes: 5);
      return await context.connectionApi.lockingTask(
        identifier: merkleColumn.identifier,
        releaseTimeout: timeout,
        timeout: timeout,
        onLocking: () async {
          final chainState = await getChainState(context: context, crypto: crypto);
          return chainState.andThenAsync((state) async {
            final builder = NativeMerkleController.fromChainMerkleState(
                context: crypto,
                state: state,
                provider: client.provider,
                liberary: controller.lib);
            final update = await IResult.call(() async {
              await builder.insertSubtree(report);
              return await builder.toSerializableChainShardTree();
            });
            builder.closeContext();
            return update.andThenAsync((newState) async {
              if (closed) return ResultOk.okVoid;
              return await context.database
                  .writeColumn(column: merkleColumn, data: newState.toCbor().encode());
            });
          });
        },
      );
    });

    // throw UnimplementedError();
    // final service =
    //     MultiChainServiceClient.fromProvider(provider: provider, netApi: context.netApi);
    // try {
    //   final cryptoContext = OnChainCryptoContext.instance;
    //   final zkCrypto = await cryptoContext.getZcashNativeCyrpto(context);

    //   final builder = NativeMerkleController.fromChainMerkleState(
    //       context: cryptoContext,
    //       state: state,
    //       provider: ZcashWalletdProvider(service),
    //       liberary: zkCrypto.unwrap().zklib);

    //   await builder.insertSubtree(report);
    //   final newState = await builder.toSerializableChainShardTree();
    //   return SerializableChainMerkleState(newState);
    // } finally {
    //   service.dispose();
    // }
  }

  void _sendResult(
      {required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required ZcashSyncOffsetResponse data,
      required String streamId}) {
    if (closed) return;
    sink.add((
      message: MessageArgsStreamResponse(
        data: data.toCbor().encode(),
        streamId: streamId,
      ),
      encrypted: data.hasTx
    ));
  }

  StreamSubscription<ScannedBlock>? subscription;
  @override
  void handleIsolateData(
      {required ZcashBlockTrackingRequestOffset param,
      required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required String streamId,
      required AppContext context,
      List<int>? encryptedPart}) async {
    final accounts = ZcashSyncRequestAccount.deserialize(bytes: encryptedPart);

    subscription?.cancel();
    subscription = null;
    final crypto = await OnChainCryptoContext.inst(context);
    // final zkLib = await crypto.getZcashNativeCyrpto(context);
    final result = await crypto.andThenAsync((c) async {
      final (crypto, zklib) = c;
      final client =
          ZcashClient.fromProviders(provider: provider, netApi: context.netApi);
      final chainState = await getChainState(context: context, crypto: crypto);
      // final merkleBytes = await context.database.readColumn(merkleColumn);
      return await chainState.andThenAsync((chainState) async {
        final NativeMerkleController merkleController =
            NativeMerkleController.fromChainMerkleState(
                context: crypto,
                provider: client.provider,
                state: chainState,
                liberary: zklib.zklib);
        final Map<DiversifiableFullViewingKey, List<AccountWithIvkAndNullifiers>> ivks =
            {};
        final accountWithIvks = accounts.accountWithIvkAndNullifiers(crypto);
        for (final i in accountWithIvks) {
          final items = ivks[i.derivationKey] ??= [];
          items.add(i);
        }
        List<Nullifier<Object>> utxoNullifiers = param.utxoNullifiers.clone();
        List<ScannedBlock> blocks = [];
        Map<DiversifiableFullViewingKey, ZcashSyncAccount> txes = {};
        List<Nullifier<Object>> spendNullifiers = [];
        final saplingKeys = ivks.keys.where((e) => e.protocol.isSapling).map((e) {
          final fvk = e.cast<SaplingDiversifiableFullViewingKey>().fvk;
          final accountWithIvk = ivks[e] ?? [];
          return ZcashBlockProcessorScanKey<SaplingFullViewingKey,
                  SaplingIncomingViewingKey>(
              fvk: fvk,
              viewKeys: accountWithIvk
                  .map((e) => IVKWithActivationHeight(
                      ivk: e.ivk.cast<SaplingIncomingViewingKey>(),
                      activationHeight: switch (param.requestId) {
                        null => 0,
                        _ => e.account.activationHeight
                      }))
                  .toList());
        }).toList();
        final orchardKeys = ivks.keys.where((e) => e.protocol.isOrchard).map((e) {
          final fvk = e.cast<OrchardFullViewingKey>();
          final accountWithIvk = ivks[e] ?? [];
          return ZcashBlockProcessorScanKey<OrchardFullViewingKey,
                  OrchardIncomingViewingKey>(
              fvk: fvk,
              viewKeys: accountWithIvk
                  .map((e) => IVKWithActivationHeight(
                      ivk: e.ivk.cast<OrchardIncomingViewingKey>(),
                      activationHeight: switch (param.requestId) {
                        null => 0,
                        _ => e.account.activationHeight
                      }))
                  .toList());
        }).toList();
        Logging.debug(
          fn: () => AppLogData(
              runtime: runtimeType,
              msg:
                  "start zcash syncing. ${param.requestId} ${param.currentHeight}:${param.endHeight} "
                  "Total orchard: ${orchardKeys.expand((e) => e.viewKeys).length}, "
                  "Total sapling: ${saplingKeys.expand((e) => e.viewKeys).length}",
              function: "handleIsolateData"),
        );
        final scanner = DefaultZcashBlockScanner(
            config: ZcashBlockProcessorConfig(
              exportMemos: true,
              network: accounts.network,
              context: crypto,
              saplingViewKeys: saplingKeys,
              orchardViewKeys: orchardKeys,
            ),
            provider: client.provider);
        int currentHeight = param.currentHeight;
        final timer = Stopwatch()..start();
        Future<void> sendResult({BlockSyncStatus? status}) async {
          bool complete = currentHeight + blocks.length == param.endHeight;
          if (closed || (status == null && !complete && timer.elapsed < flushInterval)) {
            return;
          }
          IResult<void> state = switch (status) {
            BlockSyncStatusError() => ResultOk.okVoid,
            _ => await updateMerkeState(
                context: context,
                client: client,
                blocks: blocks,
                controller: merkleController,
                crypto: crypto)
          };
          // final IResult<SerializableMerkleInsertReport?> merkleState =
          //     await IResult.call(() async {
          //   if (status case BlockSyncStatusError()) return null;
          //   return await merkle.updateState(blocks, continually: true);
          // });
          assert(currentHeight + blocks.length <= param.endHeight,
              "unexpected block data $currentHeight ${blocks.length} ${param.endHeight}");
          final BlockSyncStatus cStatus = state.fold(
            onErr: (error) => BlockSyncStatusError(error.exception),
            onOk: (v) => switch (status) {
              BlockSyncStatusError() => status,
              null when complete => BlockSyncStatusSynced(),
              _ => BlockSyncStatusPending()
            },
          );
          final response = ZcashSyncOffsetResponse(
              accounts:
                  cStatus.isErr ? {} : txes.values.where((e) => !e.isEmpty).toList(),
              currentHeight: currentHeight,
              nullifiers: spendNullifiers,
              total: blocks.length,
              request: param,
              status: cStatus);
          Logging.debug(
            when: () => response.status.synced || response.status.isErr,
            fn: () => AppLogData(
                runtime: runtimeType,
                function: "buildResponse",
                msg:
                    "Zcash block complete outputs: accounts: ${response.accounts.length} nullifiers: ${spendNullifiers.length} $currentHeight/${currentHeight + blocks.length} status: ${response.status}"),
          );
          currentHeight = currentHeight + blocks.length;
          blocks.clear();
          spendNullifiers.clear();
          for (final i in txes.entries) {
            txes[i.key] = i.value.toRequest();
          }
          _sendResult(streamId: streamId, data: response, sink: sink);
          timer
            ..reset()
            ..start();
          if (cStatus.synced || cStatus.isErr) {
            timer.stop();
            client.dispose();
            close();
            merkleController.closeContext();
          }
        }

        final sync = SafeAtomicLock();
        final stream = await IResult.call(() async {
          return await scanner.scanBlockAsync(
            start: param.currentHeight,
            end: param.endHeight,
            throttleDelay: Duration.zero,
            onProcessed: (event) async {
              return sync.run(() async {
                blocks.add(event);
                for (final i in event.txes) {
                  final outputs = i.scannedOutputs();
                  if (outputs.isEmpty) continue;
                  for (final output in outputs) {
                    final fvk = ivks.entries
                        .firstWhere((e) => e.value.any((e) => e.ivk == output.ivk));
                    final fullOutput = output.toScannecOutputWithNullifier(
                        fvk: fvk.key,
                        blockHeight: event.blockId,
                        blocktime: event.timestamp,
                        txId: i.txId,
                        context: crypto);
                    final account = fvk.value.firstWhereOrNull((e) =>
                        e.ivk == fullOutput.viewKey &&
                        e.account.diversifierIndex == fullOutput.index &&
                        e.account.scope == fullOutput.changes);
                    if (account == null) continue;
                    utxoNullifiers.add(fullOutput.output.nullifier);
                    final ZcashSyncAccount iAccounts =
                        txes[fvk.key] ??= accounts.onlyAccount(fvk.key);
                    switch (account.account) {
                      case ZcsahAccountInfoSapling():
                        iAccounts.addUtxo(
                            account.account,
                            ZcashUtxoSapling(
                                utxo: fullOutput.output.cast(),
                                status: ZcashUtxoSpendableStatus.notReady));
                        break;
                      case ZcsahAccountInfoOrchard():
                        iAccounts.addUtxo(
                            account.account,
                            ZcashUtxoOrchard(
                                utxo: fullOutput.output.cast(),
                                status: ZcashUtxoSpendableStatus.notReady));
                        break;
                    }
                  }
                }
                if (utxoNullifiers.isNotEmpty) {
                  final blockNullifiers = event.nullifiers();
                  for (final nullifier in blockNullifiers) {
                    if (utxoNullifiers.contains(nullifier)) {
                      spendNullifiers.add(nullifier);
                      utxoNullifiers.remove(nullifier);
                    }
                  }
                }
                await sendResult();
                return event;
              });
            },
          );
        });
        stream.watch(
          onErr: (e) {
            sync.run(() async {
              await sendResult(status: BlockSyncStatusError(e.exception));
            });
          },
          onOk: (stream) {
            subscription = stream.listen((event) {}, onDone: () {
              sync.run(() async {
                await sendResult();
              });
            }, onError: (e, trace) {
              sync.run(() async {
                await sendResult(
                    status: BlockSyncStatusError(IExceptionUtils.findError(e)));
              });
            }, cancelOnError: true);
          },
        );
        return ResultOk.okVoid;
      });
    });
    result.mapErr((err) {
      final response = ZcashSyncOffsetResponse(
          accounts: {},
          currentHeight: param.currentHeight,
          nullifiers: [],
          total: 0,
          request: param,
          status: BlockSyncStatusError(err.exception));
      _sendResult(sink: sink, data: response, streamId: streamId);
      close();
      return err.exception;
    });
  }

  @override
  void add(MessageArgsStream args, List<int>? encryptedPart) {
    super.add(args, null);
    switch (args.type) {
      case MessageArgsStreamMethod.message:
        streamController?.add((
          message: ZcashBlockTrackingRequestOffset.deserialize(bytes: args.data),
          encryptedPart: encryptedPart
        ));
        break;
      default:
    }
  }

  @override
  ZcashSyncOffsetResponse parsResult(MessageArgsStreamResponse result) {
    return ZcashSyncOffsetResponse.deserialize(bytes: result.data!);
  }

  @override
  MessageArgsStream toRequest(
      {required ZcashBlockTrackingRequestOffset message, required String streamId}) {
    return MessageArgsStream.message(data: message.toCbor().encode(), streamId: streamId);
  }

  @override
  void close() {
    super.close();
    subscription?.cancel();
    subscription = null;
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [provider.toCbor(), merkleColumn.toCbor(), flushInterval.inSeconds.toCbor()];
}
