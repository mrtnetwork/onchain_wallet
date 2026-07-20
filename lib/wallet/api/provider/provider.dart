import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class DefaultProvider<INNER extends IProvider<MultiChainServiceClient, PARAMS>,
        PARAMS extends IServiceRequestParams>
    extends IGrpcProvider<MultiChainServiceClient, PARAMS, BaseGRPCServiceRequestParams> {
  final INNER inner;
  DefaultProvider(this.inner);
  @override
  MultiChainServiceClient get service => inner.service;
  INetApi get netApi => inner.service.client.netApi;

  @override
  Future<RESULT> request<RESULT, SERVICERESPONSE>(
      IServiceRequest<RESULT, SERVICERESPONSE, PARAMS> request,
      {Duration? timeout}) async {
    try {
      return await inner.request(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }

  @override
  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
      IServiceRequest<RESULT, SERVICERESPONSE, PARAMS> request,
      {Duration? timeout}) async {
    try {
      return await inner.requestDynamic(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }

  IGrpcProvider _getInnerGrpc() {
    final inner = this.inner;
    if (inner is! IGrpcProvider) {
      throw AppInternalError.internalError("_getInnerGrpc",
          reason: "Unexpected provider type.");
    }
    return inner as IGrpcProvider;
  }

  @override
  Future<List<RESULT>> requestOnce<RESULT>(
      IGRPCServiceRequest<RESULT, BaseGRPCServiceRequestParams> request,
      {Duration? timeout}) async {
    try {
      return await _getInnerGrpc().requestOnce(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }

  @override
  Future<List<RESULT>> requestOnceAsync<RESULT>(
      IGRPCServiceRequest<RESULT, BaseGRPCServiceRequestParams> request,
      {Duration? timeout}) async {
    try {
      return await _getInnerGrpc().requestOnceAsync(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }

  @override
  Stream<RESULT> requestStream<RESULT>(
      IGRPCServiceRequest<RESULT, BaseGRPCServiceRequestParams> request,
      {Duration? timeout}) {
    try {
      return _getInnerGrpc().requestStream(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }

  @override
  Future<Stream<RESULT>> requestStreamAsync<RESULT>(
      IGRPCServiceRequest<RESULT, BaseGRPCServiceRequestParams> request,
      {Duration? timeout}) async {
    try {
      return await _getInnerGrpc().requestStreamAsync(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }
}
