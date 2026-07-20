import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';

class MainNetSdkConnector extends INetSdk {
  @override
  final List<NetMode> modes;
  @override
  final NetApiTarget target;

  @override
  final AppEnvironment environment;
  final _lock = SafeAtomicLock();
  bool _closed = false;
  final MessageChannel<ISolateMessageRequest<AppContextMessageNetSdkRequest>,
      ISolateMessageResponse<AppContextMessageNetSdkResponse>> connector;
  final SafeStreamController<NetResponse> controller =
      SafeStreamController<NetResponse>.broadcast(name: "MainNetSdkConnector.controller");
  final Map<int, Completer<Result<AppContextMessageNetSdkResponse, NetResultStatus>>>
      _messages = {};
  int _id = 0;

  MainNetSdkConnector(
      {required this.connector,
      required this.modes,
      required this.target,
      required this.environment}) {
    connector.stream.listen(_onMessage, onDone: _onCloseConnector);
  }

  void _onCloseConnector() {
    _lock.run(() {
      _closed = true;
      final message = _messages.values.toList();
      _messages.clear();
      for (final i in message) {
        if (i.isCompleted) continue;
        i.complete(Err(NetResultStatus.connectionClosed));
      }
    });
  }

  Future<Result<(int, SafeStreamController<NetResponse>), NetResultStatus>>
      _handleClosed() async {
    return _lock.run(() async {
      if (_closed) {
        return Err(NetResultStatus.initializationFailed);
      }
      return Ok((_id++, controller));
    });
  }

  void _onMessage(ISolateMessageResponse<AppContextMessageNetSdkResponse> response) {
    final msg = _messages.remove(response.id);
    response.message.mapErr((e) {
      msg?.complete(Err(NetResultStatus.internalError));
      Logging.danger(
          when: () => msg == null,
          fn: () => AppLogData(
              runtime: runtimeType,
              err: e.exception,
              trace: e.trace,
              msg: "Unexpected response.",
              function: "_onMessage"));
      return e.exception;
    }).map((response) {
      switch (response) {
        case AppContextMessageNetSdkResponseStream stream:
          controller.add(NetResponse(
              transportId: stream.transportId, requestId: 0, kind: stream.messages));
          break;
        case AppContextMessageNetSdkResponse response:
          msg?.complete(Ok(response));
          break;
      }
    });
  }

  @override
  Future<Result<Transport, NetResultStatus>> createTransport(
      NetConfigRequest config) async {
    final status = await _handleClosed();
    if (status.isErr) return Err(status.unwrapErr());
    final (id, controller) = status.unwrap();
    connector.add(ISolateMessageRequest(
        id: id, message: AppContextMessageNetSdkRequestTransport(request: config)));
    final completer =
        Completer<Result<AppContextMessageNetSdkResponse, NetResultStatus>>();
    _messages[id] = completer;
    final result = await completer.future.timeout(
      config.timeout + const Duration(seconds: 3),
      onTimeout: () {
        _messages.remove(id);
        return Ok(AppContextMessageNetSdkResponseTransport(
            transportId: Err(NetResultStatus.requestTimeout)));
      },
    );
    return result.andThen((result) {
      switch (result) {
        case AppContextMessageNetSdkResponseTransport result:
          return result.transportId.map((id) => Transport(
              config: config,
              stream: controller
                  .stream()
                  .where((e) => e.transportId == id)
                  .map((e) => e.kind.cast<NetResponseStream>()),
              transportId: id,
              lib: this));
        default:
          return Err(NetResultStatus.unknownResponse);
      }
    });
  }

  @override
  Future<Result<RESPONSE, NetResultStatus>> sendRequest<RESPONSE extends NetResponseKind>(
      int transportId, NetRequestKind<RESPONSE> request, Duration timeout) async {
    final status = await _handleClosed();
    return status.andThenAsync((status) async {
      final (id, controller) = status;
      final transport = AppContextMessageNetSdkRequestRequest(
        request: NetRequest(
            transportId: transportId, id: id, kind: request, timoutSecs: timeout),
      );
      connector.add(ISolateMessageRequest(id: id, message: transport));
      final completer =
          Completer<Result<AppContextMessageNetSdkResponse, NetResultStatus>>();
      _messages[id] = completer;
      final result = await completer.future.timeout(
        timeout + const Duration(seconds: 3),
        onTimeout: () {
          _messages.remove(id);
          return Ok(AppContextMessageNetSdkResponseRequest(
              result: Err(NetResultStatus.requestTimeout)));
        },
      );
      return result.andThen((result) {
        switch (result) {
          case AppContextMessageNetSdkResponseRequest response:
            return response.result.andThen((e) => request.toResponse(e.kind));
          default:
            return Err(NetResultStatus.unknownResponse);
        }
      });
    });
  }

  @override
  Future<Result<void, NetResultStatus>> closeInstance() async {
    return Ok(null);
  }
}
