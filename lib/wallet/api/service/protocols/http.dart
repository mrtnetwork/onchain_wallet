import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/client/client.dart';
import 'package:on_chain_wallet/wallet/api/utils/waiter.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class HttpServiceClient extends IServiceClientHttp {
  final DefaultAPIProvider provider;
  final ApiRequestTimingGuard? requestCooldown;
  @override
  final INetApi netApi;
  HttpServiceClient({
    required this.provider,
    Duration? requestCooldown,
    required this.netApi,
  }) : requestCooldown =
            requestCooldown == null ? null : ApiRequestTimingGuard(requestCooldown);

  @override
  Future<BaseServiceResponse> doHttpRequest(
      {required BaseServiceRequestParams request,
      required Uri uri,
      required NetMode mode,
      required Duration timeout,
      required ServiceReponseEncoding encoding,
      List<int>? allowStatus,
      ProviderAuthenticated? authenticated}) async {
    final Map<String, String> headers = {
      if (request.requestMethod.isPost &&
          !request.headers.hasValueForKeyIgnoreCase("Content-Type"))
        'Content-Type': 'application/json',
      ...request.headers
    };
    switch (encoding) {
      case ServiceReponseEncoding.map:
      case ServiceReponseEncoding.listOfMap:
      case ServiceReponseEncoding.json:
        headers['Accept'] = 'application/json';
        break;
      default:
        break;
    }
    await requestCooldown?.wait();

    return await _onServiceException(
        request: request,
        fn: () async {
          final transport = netApi.http();
          return transport.andThenAsync((transport) async {
            return switch (request.requestMethod.isPost) {
              false => await transport.get(
                  uri: uri,
                  timeout: timeout,
                  mode: mode,
                  retryLogic: provider.retryLogic,
                  clientMode: HTTPClientType.cached,
                  headers: headers,
                  authenticated: authenticated),
              true => await transport.post(
                  uri: uri,
                  clientMode: HTTPClientType.cached,
                  timeout: timeout,
                  retryLogic: provider.retryLogic,
                  headers: headers,
                  mode: mode,
                  body: request.encodeBody(protocol: ServiceProtocol.http),
                  authenticated: authenticated)
            };
          });
        },
        allowStatus: allowStatus,
        url: uri);
  }

  @override
  Future<IResult<BaseServiceResponse>> doHttpRequestBridge(
      {required BaseServiceRequestParams request,
      required Uri uri,
      required NetMode mode,
      required Duration timeout,
      List<int>? allowStatus,
      ProviderAuthenticated? authenticated}) async {
    return await IResult.call(() => doHttpRequest(
        request: request,
        uri: uri,
        mode: mode,
        timeout: timeout,
        allowStatus: allowStatus,
        authenticated: authenticated,
        encoding: ServiceReponseEncoding.binary));
  }

  static Future<BaseServiceResponse> _onServiceException(
      {required Future<IResult<NetResponseHttp>> Function() fn,
      required BaseServiceRequestParams request,
      final List<int>? allowStatus,
      required Uri url}) async {
    final response = await fn();
    return response.fold(
      onOk: (response) {
        try {
          return request.toResponse(response.body, statusCode: response.statusCode);
        } on APIError {
          rethrow;
        } catch (e) {
          throw APIError.fromException(message: e, url: url.toString());
        }
      },
      onErr: (error) {
        throw APIError.fromException(message: error.exception, url: url.toString());
      },

      /// 191582853900
    );
  }

  @override
  Future<IResult<void>> connect(Duration timeout) async {
    return ResultOk<void>(null);
  }

  @override
  void dispose() {
    onDispose();
  }

  /// 1000000000
  @override
  int? get transportId => null;
}
