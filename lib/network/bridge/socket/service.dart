import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/wallet/api/utils/waiter.dart';

class BridgeSocketService {
  final BridgeProtocol protocol;
  final TypeCbGenerateBridgeUrl onGenerateUrl;
  final AppContext context;
  BridgeSocketService(
      {required this.onGenerateUrl, required this.protocol, required this.context});
  final SafeStreamController<RelayClientResponse> _controller =
      SafeStreamController.broadcast(name: "BridgeSocketService");
  final StreamValue<SocketConnectionStatus> statusStream =
      StreamValue(SocketConnectionClosed(), name: "BridgeSocketService");
  Stream<RelayClientResponse> get stream => _controller.stream();
  SocketConnectionStatus get status => statusStream.value;
  BridgeSocketConnection? _transport;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<bool>? _connectivityStream;
  final _lock = SafeAtomicLock();

  void _onMessage(List<int> msg) {
    final Map<String, dynamic> data = StringUtils.decodeJson(msg);
    final response = RelayClientResponse.fromJson(data);
    _controller.add(response);
    if (status.connected) _transport?.retryLogic.reset();
  }

  void _onConnect() {
    _controller.add(RelayClientConnectResponse());
  }

  void _onConectivityChange(bool isOnline) {
    _lock.run(() async {
      if (isOnline) {
        if (status case SocketConnectionDisconnected(:final error)
            when error == APIErrorConst.noNetworkConnection) {
          init();
        }
      } else {
        _onClose(SocketConnectionDisconnected(error: APIErrorConst.noNetworkConnection));
      }
    });
  }

  Future<IResult<BridgeSocketConnection>> _getOrCreateTransport() async {
    final transport = _transport;
    if (transport == null || transport.url.isExpired) {
      final url = await onGenerateUrl(protocol);
      if (url.isErr) return url.cast();
      transport?.dispose();
      final newTransport = await context.netApi.netSdk().andThenAsync((e) async {
        final result = await e.createWebsocketTransport(url: url.unwrap().url);
        return result.transformError((error) => NetSdkException(error));
      });
      if (newTransport.isErr) {
        return ResultErr.fromException(AppInternalError(
            interalError: newTransport.unwrapErr().exception,
            where: "BridgeSocketService._connectInternal"));
      }
      return ResultOk(BridgeSocketConnection(
        url: url.unwrap(),
        transport: newTransport.unwrap(),
        callback: (status) => statusStream.value = status,
      ));
    }
    return ResultOk(transport);
  }

  Future<IResult<void>> _connectInternal() async {
    return await _lock.run(() async {
      final transport = await _getOrCreateTransport();
      return transport.map((transport) {
        _transport = transport;
        transport.connect().then((e) {
          e.map((e) {
            _lock.run(() async {
              statusStream.value = SocketConnectionConnected();
              _subscription = transport.transport.stream.listen(_onMessage, onDone: () {
                _onClose(
                    SocketConnectionDisconnected(error: APIErrorConst.connectionClosed));
              }, onError: (e, trace) {
                _onClose(
                    SocketConnectionDisconnected(error: IExceptionUtils.findError(e)));
              }, cancelOnError: true);
              _onConnect();
              _startConnectivityDetection();
            });
          }).mapErr((e) {
            if (e.canceled()) return e.exception;
            statusStream.value = SocketConnectionDisconnected(error: e.exception);
            return e.exception;
          });
        });
      }).mapErr((e) {
        statusStream.value = SocketConnectionDisconnected(error: e.exception);
        return e.exception;
      });
    });
  }

  Future<void> _onClose(SocketConnectionStatus status) async {
    await _lock.run(() async {
      switch (this.status) {
        case SocketConnectionClosed():
        case SocketConnectionDisposed():
          return;
        default:
          break;
      }
      _transport?.dispose();
      _transport = null;
      _subscription?.cancel().catchError((e) {});
      _subscription = null;
      statusStream.value = status;
      _controller.add(RelayClientDisconnectResponse());
      Logging.error(
          when: () => status.isError,
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "_onClose",
              msg: "Bridge socket connection closed ${statusStream.value}"));
      if (status.allowRetry) _connectInternal();
    });
  }

  Future<IResult<void>> sendMessage(RelayClientRequest mesesage) async {
    final data = mesesage.toRelayMessage();
    final transport = _transport;
    if (status.connected && transport != null) {
      final result = await transport.transport.send(StringUtils.encodeJson(data));
      return result.toResult();
    }
    return ResultErr.fromException(BridgeExceptionConst.connectionTerminated);
  }

  void _closeConnectivity() {
    _connectivityStream?.cancel();
    _connectivityStream = null;
  }

  void _startConnectivityDetection() {
    _closeConnectivity();
    _connectivityStream =
        context.platformUtls.connectivity().ok()?.listen(_onConectivityChange);
  }

  Future<IResult<void>> init() async {
    return _lock.run(() async {
      final status = this.status;
      assert(!(status.disposed || status.isPending));
      if (status.disposed || status.isPending) return ResultOk.okVoid;
      statusStream.silent = SocketConnectionDisconnected();
      _closeConnectivity();
      _connectInternal();
      return ResultOk.okVoid;
    });
  }

  Future<void> close() async {
    await _onClose(SocketConnectionClosed());
    _closeConnectivity();
  }

  Future<void> dispose() async {
    await _onClose(SocketConnectionDisposed());
    _closeConnectivity();
    _controller.close();
  }
}

class BridgeSocketConnection {
  final BridgeServerUrl url;
  final SocketTransport transport;
  final SocketRetryConnection retryLogic = SocketRetryConnection();
  OnceCancelable? _cancelable;
  TypeCbBridgeSocketStatus? callback;
  BridgeSocketConnection(
      {required this.url, required this.transport, required this.callback});

  void onStatusCanged(SocketConnectionStatus status) {
    final callback = this.callback;
    if (callback != null) callback(status);
  }

  Future<IResult<({Stream<List<int>> stream, SocketTransport transport})>>
      connect() async {
    final cancelable = _cancelable = OnceCancelable();
    final result = await IResult.wait(() async {
      final future = retryLogic
          .wait<IResult<({Stream<List<int>> stream, SocketTransport transport})>>(
        onTimeout: (int count) async {
          Logging.info(
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "_connect",
                  msg: "Bridge socket connection retry $count."));
          if (!cancelable.isCanceled) onStatusCanged(SocketConnectionPending());
          final newTransport = transport;
          final result = await transport.connect();
          final connection = result
              .toResult()
              .map((stream) => (transport: newTransport, stream: stream));
          return connection.andAsync((connection, error) {
            if (cancelable.isCanceled) {
              connection?.transport.unsubscribe();
              return ResultOk(ResultErr.fromException(AppExceptionConst.requestCanceled));
            }
            if (connection != null) return ResultOk(ResultOk(connection));
            final err = error!;
            if (err.exception.isInternalError) return ResultOk(err);
            if (!cancelable.isCanceled) {
              onStatusCanged(SocketConnectionPending(latestError: err.exception));
            }
            return ResultErr.fromException(err.exception);
          });
        },
      );
      return await future;
    }, cancelable: cancelable);
    if (result.isErr) return result.cast();
    return result.unwrap();
  }

  void dispose() {
    callback = null;
    _cancelable?.cancel();
    _cancelable = null;
    transport.close();
  }
}
