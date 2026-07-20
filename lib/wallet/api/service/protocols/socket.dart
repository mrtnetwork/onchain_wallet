import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/socket.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/wallet/api/constant/constant.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/client/client.dart';
import 'package:on_chain_wallet/wallet/api/service/types/request_completer.dart';
import 'package:on_chain_wallet/wallet/api/service/types/socket_status.dart';
import 'package:on_chain_wallet/wallet/api/service/types/types.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/api/utils/waiter.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

abstract class BaseSocketServiceClient extends IServiceClientWebsocket with TimerEvent {
  final StreamEncoding outputEncoding;
  @override
  ServiceProtocol get protocol => provider.protocol;
  final DefaultAPIProvider provider;
  final ApiRequestTimingGuard? requestCooldown;
  @override
  final Duration timeoutDuration;
  final StreamEncoding encoding;
  final Duration addMessageTimeout;
  final Duration connectTimeout;
  @override
  final INetApi netApi;
  BaseSocketServiceClient(
      {required this.provider,
      required this.netApi,
      Duration? requestCooldown,
      this.addMessageTimeout = NetworkConst.socketAddMessageTimeout,
      this.connectTimeout = NetworkConst.socketConnectTimeout,
      this.encoding = StreamEncoding.map,
      this.outputEncoding = StreamEncoding.map,
      this.timeoutDuration = NetworkConst.socketIdleTimout})
      : requestCooldown =
            requestCooldown == null ? null : ApiRequestTimingGuard(requestCooldown),
        url = switch (provider.protocol) {
          ServiceProtocol.websocket =>
            provider.auth?.toUri(Uri.parse(provider.url)).toString() ?? provider.url,
          _ => provider.url
        },
        headers = switch (provider.protocol) {
          ServiceProtocol.websocket => provider.auth?.toHeaders({}) ?? {},
          _ => const {}
        };
  SocketStatus _status = SocketStatus.disconnect;
  bool get isConnected => _status == SocketStatus.connect;
  SocketTransport? _transport;
  final _lock = SafeAtomicLock();
  StreamSubscription<List<int>>? _subscription;
  final String url;
  final Map<String, String> headers;
  final Map<int, SocketRequestCompleter> _requests = {};

  final Map<
      dynamic,
      ({
        BaseServiceSubscribtionRequest request,
        SafeStreamController<BaseSubscribtionEvent> controller
      })> _controllers = {};
  Future<IResult<({SocketTransport transport, Stream<List<int>> stream})>>
      _getOrCreateTransport() async {
    SocketTransport? transport = _transport;
    if (transport == null) {
      final netSdk = netApi.netSdk();
      if (netSdk.isErr) return netSdk.cast();
      final newTransport = (await netSdk.unwrap().createSocketTransport(
              mode: provider.mode,
              url: url,
              headers: headers,
              rawScoketConfig: switch (protocol) {
                ServiceProtocol.ssl ||
                ServiceProtocol.tcp =>
                  NetConfigRawSocket(eof: "\n".codeUnits, encoding: encoding),
                _ => null
              },
              protocol: switch (protocol) {
                ServiceProtocol.ssl => NetProtocol.tls,
                ServiceProtocol.tcp => NetProtocol.tcp,
                ServiceProtocol.websocket => NetProtocol.webSocket,
                _ => throw APIErrorConst.invalidServiceConfiguration,
              }))
          .transformError((error) => NetSdkException(error));
      if (newTransport.isErr) return newTransport.cast();
      transport = _transport = newTransport.unwrap();
    }
    final connect = await transport.connect(timeout: connectTimeout);
    return connect.toResult().map((stream) => (transport: transport!, stream: stream));
  }

  Future<IResult<void>> _connect() async {
    return await _lock.run(() async {
      if (_status == SocketStatus.dispose) {
        return ResultErr.fromException(APIErrorConst.clientDisposed);
      }
      if (_status != SocketStatus.disconnect) {
        return ResultOk(null);
      }
      _status = SocketStatus.pending;
      final connect = await _getOrCreateTransport();
      final result = await connect.andThenAsync<void>((e) async {
        _transport = e.transport;
        _subscription = e.stream.listen(_onMessge, onDone: _onClose, onError: (e) {
          Logging.error(
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "connect",
                  msg: "sockket connecting unexpected error.",
                  err: e),
              when: () => switch (e) {
                    NetResponseStreamError err => err.error.isDevError(),
                    _ => false
                  });
          _onClose();
        }, cancelOnError: true);
        final verify = await verifyConnection();
        return verify.mapErr((e) {
          _subscription?.cancel();
          _subscription = null;
          return e.exception;
        });
      });

      return result.map((e) {
        _status = SocketStatus.connect;
        onConnect();
      }).mapErr((e) {
        e.logError(runtime: runtimeType, function: "_connect", mode: LoggerMode.info);
        _status = SocketStatus.disconnect;
        return e.exception;
      });
    });
  }

  void _onClose({SocketStatus? status}) {
    _lock.run(() {
      if (_status == SocketStatus.dispose) return;
      _status = status ?? SocketStatus.disconnect;
      switch (_status) {
        case SocketStatus.disconnect:
          _transport?.unsubscribe();
          break;
        case SocketStatus.dispose:
          _transport?.close();
          break;
        default:
          break;
      }
      _subscription?.cancel().catchError((e) {});
      _subscription = null;
      onDisconnect();
      if (status == SocketStatus.dispose) {
        _transport = null;
        onDispose();
      }
      Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "_onClose",
            msg: "socket closed $status ${_transport?.id}"),
      );
      cancelTimer();
    });
  }

  Future<IResult<void>> verifyConnection() async {
    return ResultOk.okVoid;
  }

  // Future<IResult<void>> _addMessage(List<int> message) async {
  //   startTimer();
  //   await requestCooldown?.wait();
  //   final transport = _transport;
  //   if (transport == null) {
  //     return ResultErr.fromException(APIErrorConst.connectionClosed);
  //   }
  //   final result = await transport.send(message, timeout: addMessageTimeout);
  //   return result.toResult();
  // }

  Future<IResult<Map<String, dynamic>>> addMessageInternal(
      SocketRequestCompleter message, Duration timeout) async {
    startTimer();
    final transport = _transport;
    if (transport == null) {
      return ResultErr.fromException(APIErrorConst.connectionClosed);
    }
    _requests[message.id] = message;
    await requestCooldown?.wait();
    final add = await transport.send(message.params, timeout: addMessageTimeout);
    final result = await add.toResult().andThenAsync((e) {
      return message.wait(timeout);
    });
    _requests.remove(message.id);
    return result;
  }

  Future<IResult<Map<String, dynamic>>> addMessage(
      SocketRequestCompleter message, Duration timeout) async {
    final connect = await _connect();
    return connect.andThenAsync((e) async {
      if (!isConnected) {
        return ResultErr.fromException(APIErrorConst.socketConnectingFailed);
      }
      return addMessageInternal(message, timeout);
    });
  }

  SocketRequestCompleter? getRequest(int id) {
    return _requests.remove(id);
  }

  void onMessage(List<int> event) {
    final Map<String, dynamic> data = StringUtils.decodeJson(event);
    if (data.hasValue("id")) {
      final int id = int.parse(data["id"]!.toString());
      final request = getRequest(id);
      request?.complete(data);
      if (request != null) return;
    }

    for (final i in _controllers.entries) {
      final controller = i.value.controller;
      if (!controller.hasListener) continue;
      final e = i.value.request.toEvent(i.key, data);
      if (e != null) {
        controller.add(e);
        break;
      }
    }
  }

  void close() => _onClose(status: SocketStatus.disconnect);
  @override
  void dispose() => _onClose(status: SocketStatus.dispose);

  void _onMessge(List<int> event) {
    startTimer();
    onMessage(event);
  }

  @override
  Future<BaseServiceResponse> doSocketRequest(
      {required BaseServiceRequestParams request,
      required Duration timeout,
      Object? overrideData}) async {
    final SocketRequestCompleter message = SocketRequestCompleter(
        request.encodeBody(protocol: protocol) ?? [], request.requestID);
    final respnse = await addMessage(message, timeout);
    return respnse.fold(
      onOk: (respnse) => request.toResponse(respnse),
      onErr: (error) => throw error.exception,
    );
  }

  @override
  Future<IResult<void>> connect(Duration timeout) async {
    final connect = await _connect();
    return connect.andThen((e) {
      if (!isConnected) {
        return ResultErr.fromException(APIErrorConst.socketConnectingFailed);
      }
      return ResultOk.okVoid;
    });
  }

  @override
  Future<IResult<BaseServiceResponse>> doSocketRequestBridge(
      {required BaseServiceRequestParams request,
      required Duration timeout,
      Object? overrideData}) async {
    // request.subscribtionParams?.
    final SocketRequestCompleter message = SocketRequestCompleter(
        request.encodeBody(protocol: protocol) ?? [], request.requestID);
    final respnse = await addMessage(message, timeout);
    return respnse.map((e) => ServiceSuccessRespose(response: StringUtils.encodeJson(e)));
  }

  ({Stream<BaseSubscribtionEvent> stream, Object? identifier}) _createSubscribtionStream({
    required BaseServiceSubscribtionRequest<dynamic, dynamic,
            BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
        request,
    required BaseServiceResponse response,
    bool broadcast = false,
  }) {
    final identifier = request.toIdentifier(response);
    SafeStreamController<BaseSubscribtionEvent>? controller;
    if (identifier != null) {
      controller = switch (broadcast) {
        true => SafeStreamController.broadcast(
            name: "SocketServiceClient._createSubscribtionStreams"),
        false => SafeStreamController(
            name: "SocketServiceClient._createSubscribtionStreams",
            controller: StreamController(onCancel: () {
              _controllers.remove(identifier);
              if (broadcast) {
                controller?.close();
              }
              request.buildUnsubscribeRequest(identifier, 0);
            }),
          )
      };
      _controllers[identifier] = (controller: controller, request: request);
    }
    return (stream: controller?.stream() ?? Stream.empty(), identifier: identifier);
  }

  @override
  Future<IResult<ServiceSubscribtionResponse>> doSocketRequestBridgeSubscribtion({
    required BaseServiceRequestParams params,
    required BaseServiceSubscribtionRequest<dynamic, dynamic,
            BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
        request,
    required Duration timeout,
    bool broadcast = false,
  }) async {
    return IResult.call(() async {
      final response = await doSocketRequest(request: params, timeout: timeout);
      final stream = _createSubscribtionStream(
          request: request, response: response, broadcast: broadcast);
      return ServiceSubscribtionResponse(
          identifier: stream.identifier, response: response, stream: stream.stream);
    });
  }

  @override
  Future<BaseServiceSubscribtionResponse> doSubscribtionRequest({
    required BaseServiceRequestParams params,
    required BaseServiceSubscribtionRequest<dynamic, dynamic,
            BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
        request,
    required Duration timeout,
    bool broadcast = false,
  }) async {
    final response = await doSocketRequest(request: params, timeout: timeout);
    final stream = _createSubscribtionStream(
        request: request, response: response, broadcast: broadcast);
    return DefaultServiceSubscribtionResponse(
      response: response,
      stream: stream.stream,
    );
  }

  @override
  void onTimerEvent() {
    super.onTimerEvent();
    close();
  }

  @override
  void onDisconnect() {
    super.onDisconnect();
    final request = _requests.values.toList();
    _requests.clear();
    for (final i in request) {
      i.error(APIErrorConst.connectionClosed);
    }
    final controllers = _controllers.clone();
    _controllers.clear();
    for (final i in controllers.entries) {
      i.value.controller.close();
    }
  }

  @override
  int? get transportId => _transport?.id;
}

class SocketServiceClient extends BaseSocketServiceClient {
  final Duration defaultRequestTimeout;
  SocketServiceClient(
      {required super.provider,
      required super.netApi,
      required this.defaultRequestTimeout,
      super.addMessageTimeout,
      super.connectTimeout,
      super.encoding,
      super.outputEncoding,
      super.requestCooldown,
      super.timeoutDuration});

  @override
  Future<IResult<void>> verifyConnection() async {
    if (provider.service != APIProviderServices.electrum) {
      return ResultOk.okVoid;
    }
    final request = ElectrumRequestVersion(
        clientName: ProvidersConst.userAgent,
        protocolVersion: ProvidersConst.supportedElectrumVersion);
    final message = request.buildRequest(0);
    final SocketRequestCompleter completer = SocketRequestCompleter(
        message.encodeBody(protocol: protocol) ?? [], message.requestID);
    final result = await addMessageInternal(completer, defaultRequestTimeout);
    return result.andThen((result) {
      final response = message.toResponse(result);
      return IResult.callSync(
        () {
          request.onResonse(
              BitcoinProvider.parseResponse(response: response, params: message));
        },
        mode: LoggerMode.debug,
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "verifyConnection",
            msg: "Unexpected or unsupported electrum version."),
      );
    });
  }
}
