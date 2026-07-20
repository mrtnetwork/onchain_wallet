import 'dart:async';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_wallet/network/net_api/models/auth.dart';
import 'package:on_chain_wallet/network/net_api/models/models.dart';
import 'package:on_chain_wallet/network/net_api/models/transport.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/app/utils/method/utiils.dart';

abstract class IHttpTransportClient {
  Future<IResult<NetResponseHttp>> post({
    required Uri uri,
    required Duration timeout,
    required HTTPClientType clientMode,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
    NetMode mode = NetMode.clearnet,
    List<int>? body,
  });
  Future<IResult<NetResponseHttp>> get<T>({
    required Uri uri,
    required Duration timeout,
    required NetMode mode,
    required HTTPClientType clientMode,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
  });
  Future<IResult<NetResponseHttp>> getStream(
      {required Uri uri,
      required Duration timeout,
      required Duration streamingTimeout,
      Map<String, String> headers = const {},
      HttpMethod method = HttpMethod.get,
      CbOnHttpStreamProgress? onProgress,
      CancelableListener? cancelable,
      NetMode mode = NetMode.clearnet});
}

class DefaultHttpTransportClient implements IHttpTransportClient {
  DefaultHttpTransportClient(INetSdkApi netSdkApi)
      : _clientManager = HttpTransportManager(netSdkApi);
  final HttpTransportManager _clientManager;
  @override
  Future<IResult<NetResponseHttp>> post({
    required Uri uri,
    required Duration timeout,
    required HTTPClientType clientMode,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
    NetMode mode = NetMode.clearnet,
    List<int>? body,
  }) async {
    final data = await _clientManager.call(
        uri: uri,
        timeout: timeout,
        mode: mode,
        type: clientMode,
        method: HttpMethod.post,
        authenticated: authenticated,
        body: body,
        headers: headers);
    return data;
  }

  @override
  Future<IResult<NetResponseHttp>> get<T>({
    required Uri uri,
    required Duration timeout,
    required NetMode mode,
    required HTTPClientType clientMode,
    ProviderAuthenticated? authenticated,
    Map<String, String>? headers,
  }) async {
    final data = await _clientManager.call(
        uri: uri,
        type: clientMode,
        method: HttpMethod.get,
        timeout: timeout,
        mode: mode,
        authenticated: authenticated,
        headers: headers);
    return data;
  }

  @override
  Future<IResult<NetResponseHttp>> getStream(
      {required Uri uri,
      required Duration timeout,
      required Duration streamingTimeout,
      Map<String, String> headers = const {},
      HttpMethod method = HttpMethod.get,
      CbOnHttpStreamProgress? onProgress,
      CancelableListener? cancelable,
      NetMode mode = NetMode.clearnet}) async {
    return _clientManager.stream(
        uri: uri,
        method: method,
        timeout: timeout,
        mode: mode,
        headers: headers,
        onProgress: onProgress,
        cancelable: cancelable,
        streamingTimeout: streamingTimeout);
  }
}
