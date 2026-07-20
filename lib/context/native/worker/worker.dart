import 'dart:async';
import 'dart:isolate';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/core/worker.dart';
import 'package:on_chain_wallet/context/native/context/isolate.dart';
import 'package:on_chain_wallet/context/native/types/types.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';

abstract class WorkerApiNative extends AppWorkerApi {
  final AppPath path;
  final AppPlatform platform;
  WorkerApiNative({required this.path, required this.platform});
  Future<
      IResult<
          DartInitializedWorker<WRITE, READ, RESPONSE,
              ISolateConnector<WRITE, READ>>>> createWorker<WRITE extends Object,
      READ extends Object, RESPONSE extends Object?, PARAM extends Object?>({
    required FutureOr<IResult<(RESPONSE, IOISOLATECLOSE)>> Function(
            PARAM params, MessageChannel<READ, WRITE> port, AppContext? context)
        entryPoint,
    required PARAM param,
    required AppContextConfigNative config,
  });
}

class DefaultWorkerApiNative extends WorkerApiNative {
  final IAppContextConnectionApi api;
  DefaultWorkerApiNative(
      {required this.api, required super.path, required super.platform});
  static Future<
      IResult<
          DartInitializedWorker<WRITE, READ, RESPONSE,
              ISolateConnector<WRITE, READ>>>> createWorkerStatic<WRITE extends Object,
          READ extends Object, RESPONSE extends Object?, PARAM extends Object?>(
      {required FutureOr<IResult<(RESPONSE, IOISOLATECLOSE)>> Function(
              PARAM params, MessageChannel<READ, WRITE> port, AppContext? context)
          entryPoint,
      required PARAM param,
      required AppContextConfigNative config,
      SendPort? secondPort}) async {
    return await IsolateMainChannel.init<WRITE, READ, RESPONSE, PARAM, AppContext>(
      entryPoint: entryPoint,
      config: config,
      param: param,
      timeout: AppContextConst.spawnIsolateTimeout,
      secondPort: secondPort,
    );
  }

  @override
  Future<
      IResult<
          DartInitializedWorker<WRITE, READ, RESPONSE,
              ISolateConnector<WRITE, READ>>>> createWorker<WRITE extends Object,
      READ extends Object, RESPONSE extends Object?, PARAM extends Object?>({
    required FutureOr<IResult<(RESPONSE, IOISOLATECLOSE)>> Function(
            PARAM params, MessageChannel<READ, WRITE> port, AppContext? context)
        entryPoint,
    required PARAM param,
    required AppContextConfigNative config,
  }) async {
    final connection = await _createConnection();
    return connection.andThenAsync((secondPort) {
      return createWorkerStatic(
          entryPoint: entryPoint, param: param, config: config, secondPort: secondPort);
    });
  }

  Future<IResult<SendPort>> _createConnection() async {
    final result = await api.sendRequest<AppContextMessageCreateConnectionResponseNative>(
        AppContextMessageCreateConnectionRequest());
    return result.map((e) => e.port);
  }
}

typedef IOISOLATECLOSE = Future<void> Function();

class IsolateMainChannel<WRITE extends Object, READ extends Object>
    extends ISolateConnector<WRITE, READ> {
  final SafeStreamController<READ> controller;
  final ReceivePort receive;
  final SendPort sink;
  final _lock = SafeAtomicLock();
  bool _closed = false;
  Completer<DartWorkerIoClosedEvent>? _closeCompleter;
  @override
  Stream<READ> get stream => controller.stream();
  IsolateMainChannel(
      {required this.receive, required this.sink, required this.controller});
  static Future<
      IResult<
          DartInitializedWorker<WRITE, READ, RESPONSE,
              ISolateConnector<WRITE, READ>>>> init<
          WRITE extends Object,
          READ extends Object,
          RESPONSE extends Object?,
          PARAM extends Object?,
          CONTEXT extends AppContext>(
      {required FutureOr<IResult<(RESPONSE, IOISOLATECLOSE)>> Function(
              PARAM params, MessageChannel<READ, WRITE> port, CONTEXT? context)
          entryPoint,
      required PARAM param,
      required Duration timeout,
      required AppContextConfigNative config,
      SendPort? secondPort}) async {
    final controller = SafeStreamController<READ>.broadcast(name: "IsolateMainChannel");
    final initPort = RawReceivePort(null, config.loggingConfig.environment ?? "");
    final connection = Completer<IResult<DartWorkerIoResponse<RESPONSE>>>.sync();
    final onExit = ReceivePort();

    onExit.listen((_) {
      Logging.debug(
          fn: () => AppLogData(
              runtime: "IsolateMainChannel", function: "init", msg: "Isolate closed."));
      try {
        if (!connection.isCompleted) {
          connection.complete(ResultErr.fromException(AppInternalError.internalError(
              "IsolateMainChannel.init",
              reason: "Connection on exit called.",
              details: {"name": config.loggingConfig.environment ?? ""})));
        }
        if (!controller.isClosed) controller.close();
      } finally {
        onExit.close();
      }
    });

    initPort.handler = (IResult<DartWorkerIoResponse<RESPONSE>> initialMessage) {
      if (connection.isCompleted) return;
      connection.complete(initialMessage);
    };
    await Isolate.spawn(
        isolateEntryPoint<READ, WRITE, RESPONSE, PARAM, CONTEXT>,
        DartWorkerIoParams<READ, WRITE, RESPONSE, PARAM, CONTEXT>(
            port: initPort.sendPort,
            contextConfig: config,
            entryPoint: entryPoint,
            param: param,
            secondPort: secondPort),
        debugName: config.loggingConfig.environment ?? "",
        errorsAreFatal: true,
        onExit: onExit.sendPort);
    final result = await connection.future.timeout(
      timeout,
      onTimeout: () {
        onExit.close();
        controller.close();
        return ResultErr.fromException(AppInternalError.internalError(
            "IsolateMainChannel.init",
            reason: "create connection timeout.",
            details: {"name": config.loggingConfig.environment ?? ""}));
      },
    );

    return result.map((response) {
      final connector = IsolateMainChannel<WRITE, READ>(
          receive: ReceivePort.fromRawReceivePort(initPort),
          sink: response.port,
          controller: controller);
      connector.receive.listen(
        connector._listen,
        onDone: connector._onIsolateCloed,
      );
      return DartInitializedWorker(connector: connector, response: response.response);
    });
  }

  @override
  Future<IResult<void>> add(WRITE data) async {
    return _lock.run(() async {
      if (_closed) {
        return ResultErr.fromException(AppInternalError.internalError(
            "IsolateMainChannel.add",
            reason: "Connection already closed."));
      }
      sink.send(data);
      return ResultOk(null);
    });
  }

  void _listen(dynamic msg) {
    switch (msg) {
      case DartWorkerIoClosedEvent close:
        _closeCompleter?.complete(close);
        break;
      default:
        IResult.callSync(
          () => controller.add(msg),
          onError: (exception, trace) => AppLogData(
              runtime: runtimeType,
              function: "_listen",
              err: exception,
              trace: trace.toString()),
        );
        break;
    }
  }

  @override
  Future<IResult<void>> closeConnection() async {
    return await _lock.run(() async {
      if (_closed || _closeCompleter != null) return ResultOk(null);
      final closeCompleter = _closeCompleter ??= Completer<DartWorkerIoClosedEvent>();
      sink.send(DartWorkerIoCloseEvent());
      await closeCompleter.future.timeout(
        AppContextConst.defaultConnectionRequestTimeout,
        onTimeout: () {
          Logging.error(
            fn: () => LogDataDefault(
                runtime: runtimeType,
                function: "closeConnection",
                message: "shutdown isolate connection timeout."),
          );
          return DartWorkerIoClosedEvent();
        },
      );
      receive.close();
      controller.close();
      _closed = true;
      return ResultOk(null);
    });
  }

  void _onIsolateCloed() {
    _lock.run(() {
      if (_closed) return;
      _closed = true;
      controller.close();
    });
  }

  @override
  Future<IResult<void>> dispose() async {
    return _lock.run(() {
      _closed = true;
      controller.close();
      receive.close();
      return ResultOk.okVoid;
    });
  }
}

class IsolateBackgroundChannel<WRITE extends Object, READ extends Object>
    extends MessageChannel<WRITE, READ> {
  final SafeStreamController<READ> receive;
  final SendPort sink;
  @override
  Stream<READ> get stream => receive.stream();
  IsolateBackgroundChannel({required this.receive, required this.sink});
  bool _closed = false;
  final _lock = SafeAtomicLock();
  @override
  Future<IResult<void>> add(WRITE data) async {
    return _lock.run(() {
      if (_closed) return ResultErr.fromException(AppInternalError());
      sink.send(data);
      return ResultOk(null);
    });
  }

  @override
  Future<IResult<void>> dispose() async {
    return await _lock.run(() {
      if (_closed) return ResultOk(null);
      _closed = true;
      return receive.close();
    });
  }
}

class DartWorkerIoParams<WRITE extends Object, READ extends Object,
    RESPONSE extends Object?, PARAM extends Object?, CONTEXT extends Object> {
  final SendPort port;
  final FutureOr<IResult<(RESPONSE, IOISOLATECLOSE)>> Function(
      PARAM, MessageChannel<WRITE, READ>, CONTEXT? context) entryPoint;
  final SendPort? secondPort;
  final PARAM param;
  final AppContextConfigNative contextConfig;

  const DartWorkerIoParams(
      {required this.port,
      required this.entryPoint,
      required this.param,
      required this.contextConfig,
      this.secondPort});
}

class DartWorkerIoResponse<RESPONSE extends Object?> {
  final RESPONSE response;
  final SendPort port;
  final SendPort? secondPort;
  const DartWorkerIoResponse(
      {required this.response, required this.port, this.secondPort});
}

final class DartWorkerIoCloseEvent {
  final bool kill;
  const DartWorkerIoCloseEvent({this.kill = true});
}

final class DartWorkerIoClosedEvent {
  const DartWorkerIoClosedEvent();
}

class DisabledWorkerApiNative extends WorkerApiNative {
  DisabledWorkerApiNative({required super.path, required super.platform});

  @override
  Future<
      IResult<
          DartInitializedWorker<WRITE, READ, RESPONSE,
              IsolateMainChannel<WRITE, READ>>>> createWorker<WRITE extends Object,
          READ extends Object, RESPONSE extends Object?, PARAM extends Object?>(
      {required FutureOr<IResult<(RESPONSE, IOISOLATECLOSE)>> Function(
              PARAM params, MessageChannel<READ, WRITE> port, AppContext? context)
          entryPoint,
      required PARAM param,
      required AppContextConfigNative config}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}

@pragma("vm:entry-point")
Future<void> isolateEntryPoint<WRITE extends Object, READ extends Object,
        RESPONSE extends Object?, PARAM extends Object?, CONTEXT extends AppContext>(
    DartWorkerIoParams<WRITE, READ, RESPONSE, PARAM, AppContext> params) async {
  bool inited = false;
  runZonedGuarded(() async {
    final controller = SafeStreamController<READ>.broadcast(name: "isolateEntryPoint");
    final secondPort = params.secondPort;
    BackgroundAppContext? context;
    if (secondPort != null) {
      final result = await ISolateAppContextNative.init(
          port: secondPort, config: params.contextConfig);
      if (result.isErr) {
        params.port.send(result);
        return;
      }
      context = result.unwrap();
    }
    final ReceivePort receivePort = ReceivePort();
    final worker =
        IsolateBackgroundChannel<WRITE, READ>(receive: controller, sink: params.port);
    final result = await params.entryPoint(params.param, worker, context);

    result.mapErr((e) {
      params.port
          .send(ResultErr<DartWorkerIoResponse<RESPONSE>>.fromException(e.exception));
      receivePort.close();
      return e.exception;
    }).map((result) {
      params.port.send(ResultOk<DartWorkerIoResponse<RESPONSE>>(
          DartWorkerIoResponse(response: result.$1, port: receivePort.sendPort)));
      receivePort.listen(
        (message) async {
          if (message case DartWorkerIoCloseEvent(kill: bool kill)) {
            await result.$2().catchError((e, s) {
              Logging.error(
                fn: () => LogDataDefault(
                    function: "isolateMain",
                    message: "Isolate close failed: $e",
                    trace: s),
              );
              return null;
            });
            worker.sink.send(DartWorkerIoClosedEvent());
            await worker.dispose();
            await context?.shutdown();
            receivePort.close();
            if (kill) Isolate.current.kill();
            return;
          }
          IResult.callSync(
            () => worker.receive.add(message),
            onError: (exception, trace) {
              return AppLogData(
                  function: "isolateEntryPoint",
                  msg: "Unexpected message",
                  err: exception,
                  trace: trace.toString());
            },
          );
        },
      );
      inited = true;
    });
  }, (e, s) {
    if (!inited) {
      params.port.send(ResultErr<DartWorkerIoResponse<RESPONSE>>.fromException(
          AppInternalError.internalError("isolateEntryPoint",
              reason: "runZonedGuarded", details: {"error": e.toString()})));
    }
    Logging.danger(
        fn: () => AppLogData(
            function: "isolateEntryPoint",
            msg: "runZonedGuarded error callback: ",
            err: e,
            trace: s.toString()));
  });
}
