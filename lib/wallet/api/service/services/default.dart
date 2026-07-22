import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/actions.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/wallet/api/service/client/client.dart';
import 'package:on_chain_wallet/wallet/api/service/protocols/grpc.dart';
import 'package:on_chain_wallet/wallet/api/service/protocols/http.dart';
import 'package:on_chain_wallet/wallet/api/service/protocols/socket.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/types.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class MultiChainServiceClient
    implements
        IServiceProvider<BaseServiceRequestParams, BaseGRPCServiceRequestParams>,
        Equality {
  final IServiceClient client;
  final Duration timeout;
  final DefaultAPIProvider provider;
  MultiChainServiceClient(
      {required this.client, required this.timeout, required this.provider});

  factory MultiChainServiceClient.fromProvider(
      {required DefaultAPIProvider provider,
      required INetApi netApi,
      Duration? requestCooldown}) {
    Duration? timeout = provider.timeout;
    requestCooldown ??= provider.requestCooldown;
    timeout ??= switch (provider.mode) {
      NetMode.clearnet => NetworkConst.defaultRequestTimeout,
      NetMode.tor => NetworkConst.defaultTorRequestTimeout,
    };
    requestCooldown ??= NetworkConst.defaultRequestCooldown;
    return switch (provider.protocol) {
      ServiceProtocol.ssl ||
      ServiceProtocol.tcp ||
      ServiceProtocol.websocket =>
        MultiChainServiceClient(
            client: SocketServiceClient(
                defaultRequestTimeout: timeout,
                provider: provider,
                requestCooldown: requestCooldown,
                netApi: netApi),
            timeout: timeout,
            provider: provider),
      ServiceProtocol.http => MultiChainServiceClient(
          client: HttpServiceClient(
              provider: provider, requestCooldown: requestCooldown, netApi: netApi),
          timeout: timeout,
          provider: provider),
      ServiceProtocol.grpc => MultiChainServiceClient(
          client: GrpcServiceClient(
              provider: provider, requestCooldown: requestCooldown, netApi: netApi),
          timeout: timeout,
          provider: provider),
    };
  }

  Duration buildRequestTimeout(Duration? timeout) {
    if (timeout == null) return this.timeout;
    if (provider.mode.isTor) {
      return Duration(milliseconds: (timeout.inMilliseconds * 1.75).ceil());
    }
    return timeout;
  }

  // factory MultiChainServiceClient.fromProviderAndClient(
  //     {required DefaultAPIProvider provider,
  //     required Duration timeout,
  //     required IServiceClient client}) {
  //   final protocol = provider.protocol;
  //   assert(client.supportProtocol(protocol),
  //       "Client does not support ${protocol.name} protocol.");
  //   return switch (protocol) {
  //     ServiceProtocol.ssl ||
  //     ServiceProtocol.tcp ||
  //     ServiceProtocol.websocket =>
  //       MultiChainServiceClient(client: client, timeout: timeout, provider: provider),
  //     ServiceProtocol.http =>
  //       MultiChainServiceClient(client: client, timeout: timeout, provider: provider),
  //     ServiceProtocol.grpc =>
  //       MultiChainServiceClient(client: client, timeout: timeout, provider: provider),
  //   };
  // }

  @override
  Future<BaseServiceResponse> doRequest(BaseServiceRequestParams params,
      {Duration? timeout}) async {
    final allowStatusCodes = <int>[
      ...params.successStatusCodes ?? [],
      ...params.errorStatusCodes ?? []
    ];
    final cTimeout = buildRequestTimeout(timeout);
    switch (client) {
      case IServiceClientHttp service when provider.protocol.isHttp:
        return service.doHttpRequest(
            request: params,
            uri: params.encodeUrl(provider.url),
            mode: provider.mode,
            authenticated: provider.auth,
            encoding: params.responseEncoding,
            timeout: cTimeout,
            allowStatus: allowStatusCodes.nullOnEmoty);
      case IServiceClientWebsocket service when provider.protocol.isSocket:
        return service.doSocketRequest(request: params, timeout: cTimeout);
      default:
        throw APIErrorConst.serviceInternalError;
    }
  }

  Future<IResult<BridgeClientRequestResponse>> doRequestBridge<T>(
      WCMActionRequestNetworkClientRequest request,
      {Duration? timeout}) async {
    final cTimeout = buildRequestTimeout(timeout);
    switch ((request.request, client, request.subscribtionRequest, request.isStream)) {
      case (BaseServiceRequestParams params, IServiceClientHttp service, null, false)
          when provider.protocol.isHttp:
        final result = await service.doHttpRequestBridge(
            request: params,
            uri: params.encodeUrl(provider.url),
            mode: provider.mode,
            authenticated: provider.auth,
            timeout: cTimeout,
            allowStatus: <int>[
              ...params.successStatusCodes ?? [],
              ...params.errorStatusCodes ?? []
            ].nullOnEmoty);
        return result.andThen((e) => switch (e) {
              ServiceSuccessRespose() => ResultOk(BridgeClientRequestResponse(
                  response: WCMResultNetworkClientRequest(
                      status: ServiceResponseType.success,
                      statusCode: e.statusCode,
                      body: params.toEncodingResponse(e,
                          encoding: ServiceReponseEncoding.binary)),
                )),
              ServiceErrorResponse() => ResultOk(BridgeClientRequestResponse(
                  response: WCMResultNetworkClientRequest(
                      status: ServiceResponseType.error,
                      statusCode: e.statusCode,
                      body: StringUtils.tryEncode(e.error)))),
              _ => ResultErr.fromException(APIErrorConst.failedToParseResponseContent)
            });
      case (
            BaseServiceRequestParams params,
            IServiceClientWebsocket service,
            BaseServiceSubscribtionRequest request,
            true
          )
          when provider.protocol.isSocket:
        final result = await service.doSocketRequestBridgeSubscribtion(
            request: request, timeout: cTimeout, params: params);
        return result.andThenAsync((e) {
          return switch (e.response) {
            ServiceSuccessRespose respose => ResultOk(BridgeClientRequestResponse(
                stream: e.identifier == null
                    ? null
                    : e.stream.map((e) => e.toCbor().encode()),
                response: WCMResultNetworkClientRequest(
                    status: ServiceResponseType.success,
                    subscribtionId: e.identifier == null ? null : '',
                    statusCode: respose.statusCode,
                    body: params.toEncodingResponse(respose,
                        encoding: ServiceReponseEncoding.binary)))),
            ServiceErrorResponse err => ResultOk(BridgeClientRequestResponse(
                response: WCMResultNetworkClientRequest(
                    status: ServiceResponseType.error,
                    statusCode: err.statusCode,
                    body: StringUtils.tryEncode(err.error)))),
            _ => ResultErr.fromException(APIErrorConst.failedToParseResponseContent)
          };
        });
      case (BaseServiceRequestParams params, IServiceClientWebsocket service, null, false)
          when provider.protocol.isSocket:
        final result =
            await service.doSocketRequestBridge(request: params, timeout: cTimeout);
        return result.andThen((e) => switch (e) {
              ServiceSuccessRespose() => ResultOk(BridgeClientRequestResponse(
                  response: WCMResultNetworkClientRequest(
                      status: ServiceResponseType.success,
                      statusCode: e.statusCode,
                      body: params.toEncodingResponse(e,
                          encoding: ServiceReponseEncoding.binary)))),
              ServiceErrorResponse() => ResultOk(BridgeClientRequestResponse(
                  response: WCMResultNetworkClientRequest(
                      status: ServiceResponseType.error,
                      statusCode: e.statusCode,
                      body: StringUtils.tryEncode(e.error)))),
              _ => ResultErr.fromException(APIErrorConst.failedToParseResponseContent)
            });

      case (BaseGRPCServiceRequestParams params, IServiceClientGrpc client, null, false)
          when provider.protocol.isGrpc:
        final result =
            await client.doGrpcRequestBridge(request: params, timeout: cTimeout);
        return result.map((e) => BridgeClientRequestResponse(
            response: WCMResultNetworkClientRequest(
                status: ServiceResponseType.success, statusCode: 200, body: e)));
      case (BaseGRPCServiceRequestParams params, IServiceClientGrpc client, null, true)
          when provider.protocol.isGrpc:
        final result = await client.doGrpcRequestStreamAsyncBridge(
            request: params, timeout: cTimeout);
        return result.map((e) => BridgeClientRequestResponse(
            stream: e,
            response: WCMResultNetworkClientRequest(
                status: ServiceResponseType.success,
                statusCode: 200,
                body: null,
                subscribtionId: '')));
      default:
        return ResultErr.fromException(APIErrorConst.serviceInternalError);
    }
  }

  @override
  Future<List<int>> doGrpcRequest(BaseGRPCServiceRequestParams params,
      {Duration? timeout}) {
    final cTimeout = buildRequestTimeout(timeout);
    switch (client) {
      case IServiceClientGrpc client:
        return client.doGrpcRequest(request: params, timeout: cTimeout);
      default:
        throw APIErrorConst.serviceInternalError;
    }
  }

  @override
  Stream<List<int>> doGrpcRequestStream(BaseGRPCServiceRequestParams params,
      {Duration? timeout}) {
    throw APIErrorConst.serviceInternalError;
  }

  @override
  Future<Stream<List<int>>> doGrpcRequestStreamAsync(BaseGRPCServiceRequestParams params,
      {Duration? timeout}) {
    final cTimeout = buildRequestTimeout(timeout);
    switch (client) {
      case IServiceClientGrpc client:
        return client.doGrpcRequestStreamAsync(request: params, timeout: cTimeout);
      default:
        throw APIErrorConst.serviceInternalError;
    }
  }

  @override
  Future<BaseServiceSubscribtionResponse> doSubscribtionRequest(
      {required BaseServiceRequestParams params,
      required BaseServiceSubscribtionRequest<dynamic, dynamic,
              BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
          request,
      Duration? timeout}) {
    final cTimeout = buildRequestTimeout(timeout);
    switch (client) {
      case IServiceClientWebsocket client:
        return client.doSubscribtionRequest(
            request: request, timeout: cTimeout, params: params);
      default:
        throw APIErrorConst.serviceInternalError;
    }
  }

  Future<IResult<void>> initTor() async {
    return client.initTor();
  }

  void dispose() {
    client.dispose();
  }

  @override
  List<dynamic> get variables => [provider];
}
