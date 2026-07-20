import 'dart:async';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/gprc.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/client/client.dart';
import 'package:on_chain_wallet/wallet/api/service/types/socket_status.dart';
import 'package:on_chain_wallet/wallet/api/utils/waiter.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class GrpcServiceClient extends IServiceClientGrpc with TimerEvent {
  final DefaultAPIProvider provider;
  final Duration addMessageTimeout;
  final Duration connectTimeout;
  @override
  final INetApi netApi;

  GrpcServiceClient({
    required this.provider,
    required this.netApi,
    Duration? requestCooldown,
    this.addMessageTimeout = NetworkConst.socketAddMessageTimeout,
    this.connectTimeout = NetworkConst.socketConnectTimeout,
    this.timeoutDuration = NetworkConst.socketIdleTimout,
  }) : requestCooldown =
            requestCooldown == null ? null : ApiRequestTimingGuard(requestCooldown);

  SocketStatus _status = SocketStatus.disconnect;
  bool get isConnected => _status == SocketStatus.connect;
  GrpcTransport? _transport;
  final ApiRequestTimingGuard? requestCooldown;
  final _lock = SafeAtomicLock();
  @override
  final Duration timeoutDuration;

  String get url => provider.url;

  @override
  Future<List<int>> doGrpcRequest(
      {required BaseGRPCServiceRequestParams request, required Duration timeout}) async {
    final result = await _unaray(
        method: request.method(), buffer: request.toBuffer(), timeout: timeout);
    return result.fold(
      onOk: (value) => value,
      onErr: (error) => throw error.exception,
    );
  }

  @override
  Future<Stream<List<int>>> doGrpcRequestStreamAsync(
      {required BaseGRPCServiceRequestParams request, required Duration timeout}) async {
    final result = await _stream(
        method: request.method(), buffer: request.toBuffer(), timeout: timeout);
    return result.fold(
      onOk: (value) => value,
      onErr: (error) => throw error.exception,
    );
  }

  Future<IResult<GrpcTransport>> _connect() async {
    return await _lock.run(() async {
      if (_status == SocketStatus.dispose) {
        return ResultErr.fromException(APIErrorConst.clientDisposed);
      }
      GrpcTransport? transport = _transport;
      if (_status != SocketStatus.disconnect) {
        if (transport != null) {
          return ResultOk(transport);
        }
        return ResultErr.fromException(APIErrorConst.connectionClosed);
      }
      _status = SocketStatus.pending;

      Future<IResult<GrpcTransport>> getTransport() async {
        GrpcTransport? transport = _transport;
        if (transport == null) {
          final netSkd = netApi.netSdk();
          return netSkd.andThenAsync((netsdk) async {
            final transport = await netsdk
                .createGrpcTransport(
                  mode: provider.mode,
                  url: provider.url,
                )
                .timeout(connectTimeout,
                    onTimeout: () => Err(NetResultStatus.requestTimeout));
            Logging.error(
              when: () => transport.isErr,
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "getTransport",
                  msg:
                      "Create grpc transport failed: ${transport.transformError((error) => NetSdkException(error))}"),
            );
            return transport.transformError((error) => NetSdkException(error));
          });
        }
        return ResultOk(transport);
      }

      final result = await getTransport();
      return result.map((transport) {
        _status = SocketStatus.connect;
        _transport = transport;
        onConnect();
        return transport;
      }).mapErr((err) {
        _status = SocketStatus.disconnect;
        return err.exception;
      });
    });
  }

  Future<IResult<R>> _providerCaller<R>(
      {required Future<IResult<R>> Function(GrpcTransport transport) fn,
      required Duration timeout}) async {
    final transport = await _connect();
    return transport.andThenAsync((transport) async {
      startTimer();
      await requestCooldown?.wait();
      final response = await fn(transport).timeout(timeout,
          onTimeout: () => ResultErr<R>.fromException(APIErrorConst.timeoutException));
      return response;
    });
  }

  Future<IResult<List<int>>> _unaray({
    required String method,
    required Duration timeout,
    List<int>? buffer,
  }) async {
    return await _providerCaller(
        fn: (GrpcTransport transport) async {
          final result = await transport.unaray(
              method: method, buffer: buffer ?? [], timeout: timeout);
          return result.toResult();
        },
        timeout: timeout);
  }

  Future<IResult<Stream<List<int>>>> _stream({
    required String method,
    required Duration timeout,
    List<int>? buffer,
  }) async {
    Future<IResult<Stream<List<int>>>> call(GrpcTransport transport) async {
      final result =
          transport.stream(method: method, buffer: buffer ?? [], timeout: timeout);
      return ResultOk(result);
    }

    return await _providerCaller(fn: call, timeout: timeout);
  }

  void _onClose({SocketStatus? status}) {
    _lock.run(() {
      if (_status == SocketStatus.dispose) return;
      _status = status ?? SocketStatus.disconnect;
      switch (status) {
        case SocketStatus.disconnect:
          break;
        case SocketStatus.dispose:
          _transport?.close();
          _transport = null;
          onDispose();
          break;
        default:
          break;
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
  Future<IResult<List<int>>> doGrpcRequestBridge(
      {required BaseGRPCServiceRequestParams request, required Duration timeout}) async {
    return await _unaray(
        method: request.method(), buffer: request.toBuffer(), timeout: timeout);
  }

  @override
  Future<IResult<Stream<List<int>>>> doGrpcRequestStreamAsyncBridge(
      {required BaseGRPCServiceRequestParams request, required Duration timeout}) async {
    return await _stream(
        method: request.method(), buffer: request.toBuffer(), timeout: timeout);
  }

  @override
  Future<IResult<void>> initTor({Duration? timeout}) async {
    return netApi.initTor(timeout: timeout);
  }

  void close() => _onClose(status: SocketStatus.disconnect);

  @override
  void dispose() => _onClose(status: SocketStatus.dispose);

  @override
  void onTimerEvent() {
    super.onTimerEvent();
    close();
  }

  @override
  int? get transportId => _transport?.id;
}
