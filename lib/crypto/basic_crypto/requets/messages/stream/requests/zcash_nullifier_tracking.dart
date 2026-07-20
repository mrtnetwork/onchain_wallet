import 'dart:async';
import 'dart:isolate';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/zcash_context.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/request.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/sync_account.dart';
import 'package:zcash_dart/zcash.dart';

final class StreamRequestZcashNullifierTracking extends IsolateStreamRequest<
    ZcashSyncNullifierResponse, ZcashBlockTrackingRequestNullifier> {
  StreamRequestZcashNullifierTracking(
      {required this.provider,
      this.flushInterval = const Duration(minutes: 1),
      super.cancelable});
  final DefaultAPIProvider provider;
  final Duration flushInterval;

  factory StreamRequestZcashNullifierTracking.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: StreamIsolateMethod.zcashNullifierTracker.tag);
    return StreamRequestZcashNullifierTracking(
        provider:
            DefaultAPIProvider.deserialize(object: values.objectAt<CborTagValue>(0)),
        flushInterval: Duration(seconds: values.rawValueAt(1)));
  }

  @override
  StreamIsolateMethod get method => StreamIsolateMethod.zcashNullifierTracker;

  void _sendResult(
      {required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required ZcashSyncNullifierResponse data,
      required String streamId}) {
    if (closed) return;
    sink.add((
      message: MessageArgsStreamResponse(
        data: data.toCbor().encode(),
        streamId: streamId,
      ),
      encrypted: false
    ));
  }

  StreamSubscription<ScannedNullifiers>? subscription;
  DefaultMerkleController? merkle;

  @override
  void handleIsolateData(
      {required ZcashBlockTrackingRequestNullifier param,
      required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required String streamId,
      required AppContext context,
      List<int>? encryptedPart}) async {
    Logging.debug(
      fn: () => AppLogData(
          runtime: runtimeType,
          msg:
              "start zcash syncing. ${Isolate.current.debugName} ${Isolate.current.debugName} ${param.currentHeight}:${param.endHeight}",
          function: "handleIsolateData"),
    );

    // final accounts = ZcashSyncRequestAccount.deserialize(bytes: encryptedPart);

    subscription?.cancel();
    subscription = null;

    int currentHeight = param.currentHeight;
    final timer = Stopwatch()..start();
    int total = 0;
    final client = ZcashClient.fromProviders(provider: provider, netApi: context.netApi);
    Future<void> sendResult({
      BlockSyncStatus? status,
      Iterable<Nullifier> outputs = const [],
    }) async {
      if (closed) return;
      bool complete = currentHeight + total == param.endHeight;
      if (outputs.isEmpty) {
        if (status == null && !complete && timer.elapsed < flushInterval) {
          return;
        }
      }

      final BlockSyncStatus cStatus = switch (status) {
        BlockSyncStatusError() => status,
        null when complete => BlockSyncStatusSynced(),
        _ => BlockSyncStatusPending()
      };
      final response = ZcashSyncNullifierResponse(
          nullifiers: cStatus.isErr ? {} : outputs,
          currentHeight: currentHeight,
          total: total,
          request: param,
          status: cStatus);
      currentHeight = currentHeight + total;
      total = 0;
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

    final crypto = await OnChainCryptoContext.inst(context);

    crypto.mapErr((e) {
      sendResult(status: BlockSyncStatusError(e.exception));
      return e.exception;
    });
    crypto.mapAsync((crypto) async {
      final scanner = DefaultZcashBlockScanner(
          config: ZcashBlockProcessorConfig(network: param.network, context: crypto.$1),
          provider: client.provider);

      final sync = SafeAtomicLock();
      final stream = await IResult.call(() async {
        return await scanner.scanNullifiersAsync(param.currentHeight, param.endHeight);
      });
      stream.watch(
        onErr: (e) {
          sync.run(() async {
            await sendResult(status: BlockSyncStatusError(e.exception));
          });
        },
        onOk: (stream) {
          subscription = stream.listen((event) {
            sync.run(() async {
              total++;
              List<Nullifier> nullifiers = [];
              if (param.utxoNullifiers.isNotEmpty) {
                final blockNullifiers = event.nullifiers;
                for (final nullifier in blockNullifiers) {
                  if (param.utxoNullifiers.contains(nullifier)) {
                    nullifiers.add(nullifier);
                  }
                }
              }

              await sendResult(outputs: nullifiers);
            });
          }, onDone: () {
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

      return crypto;
    });
    // if (init.isErr) {
    //   ;
    // }
  }

  @override
  void add(MessageArgsStream args, List<int>? encryptedPart) {
    super.add(args, null);
    switch (args.type) {
      case MessageArgsStreamMethod.message:
        streamController?.add((
          message: ZcashBlockTrackingRequestNullifier.deserialize(bytes: args.data),
          encryptedPart: encryptedPart
        ));
        break;
      default:
    }
  }

  @override
  ZcashSyncNullifierResponse parsResult(MessageArgsStreamResponse result) {
    return ZcashSyncNullifierResponse.deserialize(bytes: result.data!);
  }

  @override
  MessageArgsStream toRequest(
      {required ZcashBlockTrackingRequestNullifier message, required String streamId}) {
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
