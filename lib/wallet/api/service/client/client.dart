import 'package:blockchain_utils/service/models/params.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/types/types.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

typedef ONSOCKETSUBSCRIBE = void Function(Map<String, dynamic>);

enum ISerivceClientStatus {
  connect,
  disconnect;

  bool get isDisconnect => this == disconnect;
}

typedef CbOnServiceClientStatus = Future<void> Function(ISerivceClientStatus status);

sealed class IServiceClient {
  INetApi get netApi;
  Future<IResult<void>> connect(Duration timeout);
  bool supportProtocol(ServiceProtocol protocol);

  Future<IResult<void>> initTor({Duration? timeout}) {
    return netApi.initTor(timeout: timeout);
  }

  void dispose();
  int? get transportId;
  ServiceProtocol get protocol;

  final Set<CbOnServiceClientStatus> _listeners = {};

  void addStatusListener(CbOnServiceClientStatus callback) {
    _listeners.add(callback);
  }

  void removeStatusListener(CbOnServiceClientStatus callback) {
    _listeners.remove(callback);
  }

  void onConnect() {
    for (final i in [..._listeners]) {
      i(ISerivceClientStatus.connect);
    }
  }

  void onDisconnect() {
    for (final i in [..._listeners]) {
      i(ISerivceClientStatus.disconnect);
    }
  }

  void onDispose() {
    _listeners.clear();
  }
}

abstract class IServiceClientHttp extends IServiceClient {
  Future<BaseServiceResponse> doHttpRequest(
      {required BaseServiceRequestParams request,
      required Uri uri,
      required NetMode mode,
      required Duration timeout,
      required ServiceReponseEncoding encoding,
      List<int>? allowStatus,
      ProviderAuthenticated? authenticated});
  Future<IResult<BaseServiceResponse>> doHttpRequestBridge(
      {required BaseServiceRequestParams request,
      required Uri uri,
      required NetMode mode,
      required Duration timeout,
      List<int>? allowStatus,
      ProviderAuthenticated? authenticated});
  @override
  ServiceProtocol get protocol => ServiceProtocol.http;
  @override
  bool supportProtocol(ServiceProtocol protocol) => protocol.isHttp;
}

abstract class IServiceClientWebsocket extends IServiceClient {
  Future<BaseServiceSubscribtionResponse> doSubscribtionRequest(
      {required BaseServiceRequestParams params,
      required BaseServiceSubscribtionRequest<dynamic, dynamic,
              BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
          request,
      required Duration timeout});
  Future<IResult<ServiceSubscribtionResponse>> doSocketRequestBridgeSubscribtion(
      {required BaseServiceRequestParams params,
      required BaseServiceSubscribtionRequest<dynamic, dynamic,
              BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
          request,
      required Duration timeout});
  Future<BaseServiceResponse> doSocketRequest(
      {required BaseServiceRequestParams request,
      required Duration timeout,
      Object? overrideData});

  Future<IResult<BaseServiceResponse>> doSocketRequestBridge(
      {required BaseServiceRequestParams request,
      required Duration timeout,
      Object? overrideData});

  @override
  bool supportProtocol(ServiceProtocol protocol) => protocol.isSocket;
}

abstract class IServiceClientGrpc extends IServiceClient {
  Future<List<int>> doGrpcRequest(
      {required BaseGRPCServiceRequestParams request, required Duration timeout});
  Future<Stream<List<int>>> doGrpcRequestStreamAsync(
      {required BaseGRPCServiceRequestParams request, required Duration timeout});

  Future<IResult<List<int>>> doGrpcRequestBridge(
      {required BaseGRPCServiceRequestParams request, required Duration timeout});
  Future<IResult<Stream<List<int>>>> doGrpcRequestStreamAsyncBridge(
      {required BaseGRPCServiceRequestParams request, required Duration timeout});

  @override
  bool supportProtocol(ServiceProtocol protocol) => protocol.isGrpc;
  @override
  ServiceProtocol get protocol => ServiceProtocol.grpc;
}
