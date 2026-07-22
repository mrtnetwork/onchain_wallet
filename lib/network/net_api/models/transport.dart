import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/net_api/models/auth.dart';
import 'package:on_chain_wallet/network/net_api/models/models.dart';
import 'package:on_chain_wallet/network/net_api/models/stream.dart';

class HttpClientManagerConst {
  static const Duration idleTimeout = Duration(minutes: 3);
  static const Duration globalClientTimeout = Duration(seconds: 30);
  static const List<int> retryStatusCodes = [408, 500, 502, 503, 504];
  static final NetHttpRetryConfig retryConfig = NetHttpRetryConfig(
      maxRetry: 3,
      retryStatus: retryStatusCodes,
      retryDelay: const Duration(milliseconds: 350));
  static NetHttpRetryConfig createRetryLogic(ProviderRetryLogic? retryLogic) {
    if (retryLogic == null) return retryConfig;
    return NetHttpRetryConfig(
        maxRetry: 3,
        retryStatus: [...retryStatusCodes, ...retryLogic.statusCodes],
        retryDelay: retryLogic.timeout);
  }
}

class HttpTransportManager {
  final INetSdkApi netSdkApi;
  final Map<String, _Client> _clients = {};
  final _lock = SafeAtomicLock();

  HttpTransportManager(this.netSdkApi);
  Future<IResult<_Client>> _getClient({
    required Uri uri,
    required ProviderAuthenticated? authenticated,
    required HTTPClientType type,
    required NetMode mode,
    required bool streaming,
  }) async {
    final identifier =
        "${uri.scheme}_${uri.host}_${uri.port}_${authenticated.hashCode}_${mode.name}_$streaming";
    _clients[identifier]?.startTimer();
    return _lock.run(() async {
      final client = _clients[identifier];
      if (client != null) return ResultOk(client);
      final transport = await netSdkApi.createHttpTransport(
        url: uri.toString(),
        authenticated: authenticated,
        mode: mode,
        streaming: streaming,
      );
      return transport.transformError((error) => NetSdkException(error)).map((transport) {
        final newClient = _Client(
            client: transport,
            type: type,
            onDispose: () => _lock.run(() {
                  _clients.remove(identifier);
                }),
            timeoutDuration: switch (streaming) {
              true => HttpClientManagerConst.globalClientTimeout,
              false => HttpClientManagerConst.idleTimeout,
            });
        if (type != HTTPClientType.perRequest) {
          _clients[identifier] = newClient;
        }

        return newClient;
      });
    });
  }

  Future<IResult<NetResponseHttp>> call({
    required Uri uri,
    required HTTPClientType type,
    required HttpMethod method,
    required Duration timeout,
    required NetMode mode,
    ProviderRetryLogic? retryLogic,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
    List<int>? body,
  }) async {
    final client = await _getClient(
        uri: uri, type: type, authenticated: authenticated, mode: mode, streaming: false);
    return client.andThenAsync((client) async {
      return client.call(
          uri: uri,
          retryLogic: retryLogic,
          type: type,
          method: method,
          timeout: timeout,
          mode: mode,
          authenticated: authenticated,
          body: body,
          headers: headers);
    });
  }

  Future<IResult<NetResponseHttp>> stream({
    required Uri uri,
    required HttpMethod method,
    required Duration timeout,
    required NetMode mode,
    required Duration streamingTimeout,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
    List<int>? body,
    CbOnHttpStreamProgress? onProgress,
    CancelableListener? cancelable,
  }) async {
    final client = await _getClient(
        uri: uri,
        type: HTTPClientType.single,
        authenticated: authenticated,
        mode: mode,
        streaming: true);
    return client.andThenAsync((client) => client.stream(
        uri: uri,
        timeout: timeout,
        authenticated: authenticated,
        body: body,
        cancelable: cancelable,
        headers: headers ??= const {},
        method: method,
        mode: mode,
        onProgress: onProgress,
        streamingTimeout: streamingTimeout));
  }
}

class _Client with TimerEvent {
  final HttpTransport client;
  final HTTPClientType type;
  _Client({
    required this.client,
    required this.onDispose,
    required this.timeoutDuration,
    required this.type,
  }) {
    startTimer();
  }

  int _activeRequest = 0;

  Future<T> _call<T>(Future<T> Function() fn,
      {bool startTimerWhenComplete = true}) async {
    try {
      _activeRequest++;
      cancelTimer();
      return await fn();
    } finally {
      if (type == HTTPClientType.perRequest) {
        client.close();
      } else {
        if (--_activeRequest == 0) {
          startTimer();
        }
      }
    }
  }

  Future<IResult<NetResponseHttp>> call({
    required Uri uri,
    required HTTPClientType type,
    required HttpMethod method,
    required Duration timeout,
    required NetMode mode,
    ProviderRetryLogic? retryLogic,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
    List<int>? body,
  }) async {
    return _call(() async {
      final result = switch (method) {
        HttpMethod.get => await client.get(
            url: uri.toString(),
            headers: headers ?? {},
            timeout: timeout,
            retryConfig: HttpClientManagerConst.createRetryLogic(retryLogic),
          ),
        HttpMethod.post => await client.post(
            url: uri.toString(),
            headers: headers ?? {},
            body: body,
            timeout: timeout,
            retryConfig: HttpClientManagerConst.createRetryLogic(retryLogic)),
        _ => Err<NetResponseHttp, NetSdkException>(
            NetSdkException(NetResultStatus.invalidConfigParameters))
      };
      return result.toResult();
    });
  }

  IResult<Stream<NetResponseHttp>> _stream({
    required Uri uri,
    required HttpMethod method,
    required Duration timeout,
    required NetMode mode,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
    List<int>? body,
  }) {
    final result = client.stream(
        url: uri.toString(),
        headers: headers ?? {},
        timeout: timeout,
        retryConfig: HttpClientManagerConst.retryConfig,
        method: method,
        body: body);
    return result.toResult();
  }

  Future<IResult<NetResponseHttp>> stream(
      {required Uri uri,
      required Duration timeout,
      required Duration streamingTimeout,
      Map<String, String> headers = const {},
      HttpMethod method = HttpMethod.get,
      CbOnHttpStreamProgress? onProgress,
      CancelableListener? cancelable,
      List<int>? body,
      ProviderAuthenticated? authenticated,
      NetMode mode = NetMode.clearnet}) async {
    return _call(() async {
      final data = _stream(
          uri: uri,
          method: method,
          timeout: timeout,
          mode: mode,
          authenticated: authenticated,
          body: body,
          headers: headers);
      return await data.andThenAsync((stream) async {
        final Completer<IResult<NetResponseHttp>> completer = Completer();
        List<int> buffer = [];
        int? contentLength;
        NetResponseHttp? mainResponse;
        final subscribe = stream.listen((e) {
          if (!e.isSuccess) {
            completer.complete(ResultErr.fromException(
                APIError.fromNetResponseHttp(e, url: uri.toString())));
            return;
          }
          mainResponse ??= e;
          buffer.addAll(e.body);
          final totalLength = contentLength ??= mainResponse?.headers.getContentLength();
          if (onProgress != null) {
            onProgress(StreamProgress(
                loaded: buffer.length, total: totalLength, identifier: uri.toString()));
          }
        }, onDone: () {
          if (!completer.isCompleted) {
            final response = mainResponse;
            if (response == null) {
              completer.complete(ResultErr.fromException(APIError.fromNetSdk(
                  NetSdkException(NetResultStatus.connectionError),
                  url: uri.toString())));
            } else {
              completer.complete(ResultOk(response.copyWith(body: buffer)));
            }
          }
        }, onError: (e, trace) {
          completer.complete(ResultErr.from(e, trace: trace));
        }, cancelOnError: true);
        void onCancel() {
          if (!completer.isCompleted) {
            completer
                .complete(ResultErr.fromException(AppExceptionConst.requestCanceled));
          }
        }

        cancelable?.addListener(onCancel);
        final result = await completer.future.timeout(
          streamingTimeout,
          onTimeout: () => ResultErr.fromException(APIErrorConst.timeoutException),
        );
        cancelable?.removeListener(onCancel);
        return result.mapErr((e) {
          if (e.canceled()) {
            subscribe.cancel();
          }
          return e.exception;
        });
      });
    });
  }

  @override
  void onTimerEvent() {
    super.onTimerEvent();
    try {
      onDispose();
    } finally {
      dispose();
    }
  }

  void dispose() {
    cancelTimer();
    client.close();
  }

  final DynamicVoid onDispose;
  @override
  final Duration timeoutDuration;
}
