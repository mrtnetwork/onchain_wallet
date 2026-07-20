import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/core/app_crypto.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/utxo.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/syncing/request.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/syncing/sync_account.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';

final class StreamRequestMoneroBlockTracking extends IsolateStreamRequest<
    MoneroSyncOffsetResponse, MoneroBlockTrackingRequestOffset> {
  StreamRequestMoneroBlockTracking(
      {required this.provider,
      this.flushInterval = const Duration(minutes: 1),
      super.cancelable});
  final DefaultAPIProvider provider;
  final Duration flushInterval;

  factory StreamRequestMoneroBlockTracking.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: StreamIsolateMethod.moneroAccountTracker.tag);
    return StreamRequestMoneroBlockTracking(
        provider:
            DefaultAPIProvider.deserialize(object: values.objectAt<CborTagValue>(0)),
        flushInterval: Duration(seconds: values.rawValueAt(1)));
  }

  @override
  StreamIsolateMethod get method => StreamIsolateMethod.moneroAccountTracker;

  void _sendResult(
      {required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required MoneroSyncOffsetResponse data,
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

  StreamSubscription<DefaultMoneroScannedBlock>? subscription;
  @override
  void handleIsolateData(
      {required MoneroBlockTrackingRequestOffset param,
      required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required String streamId,
      required AppContext context,
      List<int>? encryptedPart}) async {
    Logging.debug(
      // when: () => response.status.synced || response.status.isErr,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "handleIsolateData",
          msg: "Monero tracking block. ${param.currentHeight}/${param.endHeight}"),
    );
    final accounts = MoneroSyncRequestAccount.deserialize(bytes: encryptedPart);

    Map<MoneroAccountKeys, MoneroSyncAccount> txes =
        Map.fromEntries(accounts.accounts.map((e) => MapEntry(e.getAccountKeys(), e)));
    subscription?.cancel();
    subscription = null;
    final client = MoneroClient.fromProviders(provider: provider, netApi: context.netApi);
    List<TxKeyImage> keyImages = param.keyImages.clone();
    List<DefaultMoneroScannedBlock> blocks = [];
    List<TxKeyImage> spendKeyImages = [];
    int currentHeight = param.currentHeight;
    final timer = Stopwatch()..start();
    Future<void> sendResult({BlockSyncStatus? status}) async {
      bool complete = currentHeight + blocks.length == param.endHeight;
      if (closed || (status == null && !complete && timer.elapsed < flushInterval)) {
        return;
      }
      assert(currentHeight + blocks.length <= param.endHeight,
          "unexpected block data $currentHeight ${blocks.length} ${param.endHeight}");
      final BlockSyncStatus cStatus = switch (status) {
        BlockSyncStatusError() => status,
        null when complete => BlockSyncStatusSynced(),
        _ => BlockSyncStatusPending()
      };
      final response = MoneroSyncOffsetResponse(
          accounts: cStatus.isErr ? {} : txes.values.where((e) => !e.isEmpty).toList(),
          currentHeight: currentHeight,
          total: blocks.length,
          keyImages: spendKeyImages,
          request: param,
          status: cStatus);
      Logging.debug(
        when: () => response.status.synced || response.status.isErr,
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "buildResponse",
            msg:
                "Monero block complete outputs: accounts: ${response.accounts.length} keyImages: ${spendKeyImages.length}"
                "${blocks.firstOrNull?.blockHeight}/${blocks.lastOrNull?.blockHeight}/${param.offset.endHeight} status: ${response.status}"),
      );
      currentHeight = currentHeight + blocks.length;
      blocks.clear();
      spendKeyImages.clear();
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
      }
    }

    IResult<MoneroUtxo?> unlockUtxo({
      required MoneroLockedOutput lockedOutput,
      required String txId,
      required int blockHeight,
      required BigInt globalIndex,
      // required DerivableIndex masterIndex,
      required MoneroSyncAccount syncAccount,
    }) {
      try {
        final key = accounts.secretKeys
            .getSecretKey(syncAccount.derivationKey.index)
            .cast<MoneroPrivateKeyData>();
        final output = MoneroTransactionHelper.toUnlockOutput(
            out: lockedOutput,
            account: MoneroAccountKeys(
                account: key.toMoneroAccount(),
                network: accounts.network,
                indexes: syncAccount.accounts.map((e) => e.index).toList()));
        if (output == null) return ResultOk(null);
        return ResultOk(MoneroUtxo(
            globalIndex: globalIndex,
            output: output,
            txId: txId,
            blockHeight: blockHeight));
      } catch (e, trace) {
        return ResultErr.from(e, trace: trace);
      }
    }

    final crypto = AppCryptoLibs.instance();
    final monero = await crypto.moneroCrypto(context, txes.keys.toList());
    final sync = SafeAtomicLock();
    monero.mapErr((e) {
      sync.run(() async {
        await sendResult(status: BlockSyncStatusError(monero.unwrapErr().exception));
      });
      return e.exception;
    }).map((unlocker) {
      final scanner = MoneroBlockTracker(
        client: client,
        config: BlockProcessorConfig(
            network: param.network,
            unlocker: unlocker,
            strategy: VerifyBlockStrategy.onReceiveFunds,
            getBlocksTimeout: switch (provider.mode) {
              NetMode.tor => const Duration(minutes: 5),
              NetMode.clearnet => const Duration(minutes: 3),
            }),
      );
      final stream = scanner.scanBlock(param.currentHeight, param.endHeight,
          maxRetries: 5, retryOnErr: (error, retry) {
        return error is APIError;
      });
      subscription = stream.listen((block) {
        sync.run(() async {
          blocks.add(block);
          for (final tx in block.txes) {
            for (final i in tx.unlockedOutputs) {
              final syncAccount = txes[i.account];
              assert(syncAccount != null);
              if (syncAccount == null) continue;
              final utxo = unlockUtxo(
                  lockedOutput: i.output,
                  txId: tx.txHash,
                  blockHeight: block.blockHeight,
                  globalIndex: i.globalIndex,
                  syncAccount: syncAccount);
              final result = await utxo.mapErrAsync((e) async {
                await sendResult(status: BlockSyncStatusError(e.exception));
                return e.exception;
              });
              result.map((utxo) {
                if (utxo != null) {
                  syncAccount.addUtxo(utxo);
                  keyImages.add(utxo.output.keyImage);
                }
              });
            }
          }

          if (keyImages.isNotEmpty) {
            final blockKeyImages = block.keyImages();
            for (final nullifier in blockKeyImages) {
              if (keyImages.contains(nullifier)) {
                spendKeyImages.add(nullifier);
                keyImages.remove(nullifier);
              }
            }
          }

          await sendResult();
        });
      }, onDone: () {
        sync.run(() async {
          await sendResult();
        });
      }, onError: (e, trace) {
        sync.run(() async {
          await sendResult(status: BlockSyncStatusError(IExceptionUtils.findError(e)));
        });
      }, cancelOnError: true);
    });
  }

  @override
  void add(MessageArgsStream args, List<int>? encryptedPart) {
    super.add(args, null);
    switch (args.type) {
      case MessageArgsStreamMethod.message:
        streamController?.add((
          message: MoneroBlockTrackingRequestOffset.deserialize(bytes: args.data),
          encryptedPart: encryptedPart
        ));
        break;
      default:
    }
  }

  @override
  MoneroSyncOffsetResponse parsResult(MessageArgsStreamResponse result) {
    return MoneroSyncOffsetResponse.deserialize(bytes: result.data!);
  }

  @override
  MessageArgsStream toRequest(
      {required MoneroBlockTrackingRequestOffset message, required String streamId}) {
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
      [provider.toCbor(), flushInterval.inSeconds.toCbor()];
}

class MoneroBlockTracker extends DefaultMoneroBlockProcessor {
  final MoneroClient client;
  MoneroBlockTracker({required this.client, required super.config})
      : super(provider: client.provider.inner);

  @override
  Future<List<int>> requestBinary<RESULT, SERVICERESPONSE>(
      MoneroDaemonRequestParam<RESULT, SERVICERESPONSE> request,
      {Duration? timeout}) {
    return client.provider
        .requestBinary<RESULT, SERVICERESPONSE>(request, timeout: timeout);
  }
}
