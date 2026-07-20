import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/worker/export.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';

typedef CbParseIsolateResponse<READ extends Object?> = IResult<READ> Function(
    JSDartWorkerMessage message);

class WorkerChannelMain<WRITE extends Object, READ extends Object>
    extends ISolateConnector<WRITE, READ> {
  final StreamMessageTransform<READ, MessageEvent<JSWorkerMessage?>> connector;
  final SinkMessageTransform<WRITE, WebIsolateEncodedMessage> sink;
  @override
  Stream<READ> get stream => connector.stream;
  Completer<void>? _closeCompleter;
  final Worker worker;
  bool _closed = false;
  final _lock = SafeAtomicLock();
  WorkerChannelMain({required this.worker, required this.connector, required this.sink});
  static Future<
          IResult<
              DartInitializedWorker<WRITE, READ, RESPONSE,
                  WorkerChannelMain<WRITE, READ>>>>
      init<WRITE extends Object, READ extends Object, RESPONSE extends Object?>({
    WasmModuleInfo? wasmModule,
    String? jsModule,
    required WebIsolateEncodedMessage param,
    required Duration timeout,
    required JSIsolateMessagDecoder<READ> decoder,
    required JSIsolateMessageEncoder<WRITE> encoder,
    required CbParseIsolateResponse<RESPONSE> transferParams,
    required String workerExcuterPath,
  }) async {
    if ((wasmModule == null && jsModule == null) ||
        (wasmModule != null && jsModule != null)) {
      return ResultErr.fromException(AppInternalError.internalError(
          "WorkerChannelMain.init",
          reason: "Missing parameters."));
    }
    final controller = SafeStreamController<READ>.broadcast(name: "WorkerChannelMain");
    final workerUrl = WokerUrl(wasm: wasmModule, module: jsModule, logging: true);
    final Worker worker = Worker(workerUrl.toUrl(workerExcuterPath), WorkerOptions());
    final connection = Completer<IResult<JSWorkerMessage>>.sync();

    worker.onerror = (ErrorEvent event) {
      Logging.danger(
        fn: () => LogDataDefault(
            runtime: "WorkerChannelMain.init",
            function: "onerror",
            message: "Worker onerror: ${event.message}."),
      );
      if (!connection.isCompleted) {
        connection.complete(ResultErr.fromException(AppInternalError.internalError(
            "WorkerChannelMain.init",
            reason: "Worker onerror: ${event.message}")));
      }
      controller.close();
      worker.terminate();
    }.toJS;

    worker.onmessage = (MessageEvent<ResultOrErrorJs<JSWorkerMessage, APPJSArrayBuffer>?>
        initialMessage) {
      if (connection.isCompleted) return;
      final IResult<JSWorkerMessage> dartMsg = initialMessage.data
          .toDart(
              onResult: (ok) => ok,
              onErr: (err) =>
                  IExceptionUtils.deserialize(bytes: err.toUint8Array().toBytes()),
              onInvalid: () => AppInternalError.internalError("WorkerChannelMain.init",
                  reason: "Invalid response."))
          .toResult();
      connection.complete(dartMsg);
    }.toJS;
    final encode = param.encode();
    worker.postMessageWithTransferables(encode.message, encode.transfableParams);
    final result = await connection.future.timeout(
      timeout,
      onTimeout: () {
        worker.terminate();
        controller.close();
        return ResultErr.fromException(AppInternalError.internalError(
            "WorkerChannelMain.init",
            reason: "Connection timeout."));
      },
    );
    final channel = result.andThen((response) {
      return response.toDart().andThen((response) {
        final params = transferParams(response);
        return params.map((params) {
          final connector = WorkerChannelMain<WRITE, READ>(
            worker: worker,
            sink: SinkMessageTransform(
                sink: JSMessageChannelSink(port: worker), encoder: encoder),
            connector:
                StreamMessageTransform.from(decoder: decoder, controller: controller),
          );
          connector.worker.onmessage = connector._listen.toJS;
          connector.worker.onerror = connector._onWorkerError.toJS;
          return DartInitializedWorker<WRITE, READ, RESPONSE,
              WorkerChannelMain<WRITE, READ>>(connector: connector, response: params);
        });
      });
    });

    return channel.mapErr((e) {
      if (!controller.isClosed) {
        controller.close();
        worker.terminate();
      }
      return e.exception;
    });
  }

  @override
  Future<IResult<void>> add(WRITE data) async {
    return _lock.run(() async {
      if (_closed) {
        return ResultErr.fromException(AppInternalError.internalError(
            "WorkerChannelMain.add",
            reason: "Connection closed."));
      }
      return sink.send(data);
    });
  }

  void _listen(MessageEvent<JSWorkerMessage?> msg) {
    final data = msg.data;
    if (data != null && data.isClosed()) {
      _closeCompleter?.complete();
      _closeCompleter = null;
      return;
    }
    connector.listen(msg);
  }

  @override
  Future<IResult<void>> closeConnection({Duration? timeout}) async {
    return _lock.run(() async {
      if (_closed || _closeCompleter != null) return ResultOk.okVoid;
      final closeCompleter = _closeCompleter ??= Completer<void>();
      worker.postMessage(JSWorkerMessage.close(close: true.toJS));
      await closeCompleter.future.timeout(
        AppContextConst.defaultConnectionRequestTimeout,
        onTimeout: () {
          Logging.error(
            fn: () => LogDataDefault(
                runtime: closeConnection,
                function: "shutdown",
                message: "shutdown isolate result timeout."),
          );
          return null;
        },
      );

      worker.terminate();
      connector.close();
      sink.close();
      _closed = true;
      Logging.debug(
        fn: () => LogDataDefault(
            runtime: runtimeType,
            function: "closeConnection",
            message: "Worker Connection closed."),
      );
      return ResultOk(null);
    });
  }

  void _onWorkerError(ErrorEvent e) {
    Logging.danger(
      fn: () => LogDataDefault(
          runtime: runtimeType,
          function: "_onWorkerError",
          message: "Worker onerror: ${e.message}."),
    );
    _lock.run(() {
      _closed = true;
      connector.close();
      worker.terminate();
    });
  }

  @override
  Future<IResult<void>> dispose({Duration? timeout}) {
    return _lock.run(() {
      _closed = true;
      connector.close();
      worker.terminate();
      return ResultOk.okVoid;
    });
  }
}

class WorkerConnectionData<WRITE extends Object, READ extends Object,
    RESPONSE extends Object?> {
  final WorkerChannelMain<WRITE, READ> connector;
  final RESPONSE response;
  final String id;
  const WorkerConnectionData(
      {required this.connector, required this.response, required this.id});
}
