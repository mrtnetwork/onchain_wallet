// import 'dart:async';

// import 'package:blockchain_utils/service/models/params.dart';
// import 'package:blockchain_utils/utils/string/string.dart';
// import 'package:on_chain_bridge/net_sdk/types/config.dart';
// import 'package:on_chain_wallet/app/core.dart';
// import 'package:on_chain_wallet/network/bridge/client/client.dart';
// import 'package:on_chain_wallet/network/bridge/onchain/types/actions.dart';
// import 'package:on_chain_wallet/network/bridge/onchain/types/events.dart';
// import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
// import 'package:on_chain_wallet/network/bridge/types/bridge/client.dart';
// import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
// import 'package:on_chain_wallet/wallet/api/service/client/client.dart';
// import 'package:on_chain_wallet/wallet/api/service/types/types.dart';
// import 'package:on_chain_wallet/network/net_api/api.dart';

// abstract class ExternalServiceClient extends IServiceClientWebsocket
//     implements IServiceClientGrpc, IServiceClientHttp {
//   final IBridgeClient client;
//   final WCMSession session;
//   DefaultAPIProvider get provider;
//   int? get networkId;
//   final Map<String, BridgeClientStreamEvent> _controllers = {};
//   StreamSubscription<BridgeEventOnChainSessionActionClientEventStream>? _listener;

//   ExternalServiceClient({required this.client, required this.session});

//   @override
//   ServiceProtocol get protocol => provider.protocol;
//   @override
//   Future<List<int>> doGrpcRequest(
//       {required BaseGRPCServiceRequestParams request, required Duration timeout}) async {
//     final result = await client.sendRequestAndGetResponse(
//       action: WCMActionRequestNetworkClientRequest.grpc(
//           network: networkId, identifier: provider.identifier, request: request),
//     );
//     final response = result.unwrap();
//     assert(response.statusCode == 200);
//     assert(response.status == ServiceResponseType.success);
//     return response.body ?? [];
//   }

//   @override
//   Future<BaseServiceResponse> doSocketRequest(
//       {required BaseServiceRequestParams request,
//       required Duration timeout,
//       Object? overrideData}) async {
//     final result = await client.sendRequestAndGetResponse(
//       action: WCMActionRequestNetworkClientRequest.socket(
//           network: networkId, identifier: provider.identifier, request: request),
//     );
//     final response = result.unwrap();
//     return switch (response.status) {
//       ServiceResponseType.error => ServiceErrorResponse(
//           statusCode: response.statusCode, error: StringUtils.tryDecode(response.body)),
//       ServiceResponseType.success =>
//         request.toResponse(response.body, statusCode: response.statusCode),
//     };
//   }

//   @override
//   Future<BaseServiceResponse> doHttpRequest(
//       {required BaseServiceRequestParams request,
//       required Uri uri,
//       required NetMode mode,
//       required Duration timeout,
//       List<int>? allowStatus,
//       ProviderAuthenticated? authenticated}) async {
//     final result = await client.sendRequestAndGetResponse(
//       action: WCMActionRequestNetworkClientRequest.http(
//           network: networkId, identifier: provider.identifier, request: request),
//     );
//     final response = result.unwrap();
//     return switch (response.status) {
//       ServiceResponseType.error => ServiceErrorResponse(
//           statusCode: response.statusCode, error: StringUtils.tryDecode(response.body)),
//       ServiceResponseType.success =>
//         request.toResponse(response.body, statusCode: response.statusCode),
//     };
//   }

//   void _onBridgeEvent(BridgeEventOnChainSessionActionClientEventStream event) {
//     final controller = _controllers[event.request.id];
//     if (controller == null) {
//       return;
//     }
//     switch (event.request) {
//       case WCMEventNetworkClientStreamData(:final data):
//         controller.add(data);
//         break;
//       case WCMEventNetworkClientStreamStatus(:final error):
//         if (error != null) {
//           controller.error(error);
//         }
//         controller.close();
//         break;
//     }
//   }

//   @override
//   Future<Stream<List<int>>> doGrpcRequestStreamAsync(
//       {required BaseGRPCServiceRequestParams request,
//       required Duration timeout,
//       bool broadcast = false}) async {
//     final result = await client.sendRequestAndGetResponse(
//       action: WCMActionRequestNetworkClientRequest.grpc(
//           network: networkId,
//           identifier: provider.identifier,
//           request: request,
//           isStream: true),
//     );
//     final response = result.unwrap();
//     final id = response.subscribtionId;
//     assert(response.statusCode == 200);
//     assert(response.status == ServiceResponseType.success);
//     assert(id != null);
//     if (id == null) throw APIErrorConst.serviceInternalError;
//     final controller = switch (broadcast) {
//       false => StreamController<List<int>>(),
//       true => StreamController<List<int>>.broadcast()
//     };

//     controller.onCancel = () {
//       client.sendOnChainRequest(
//           action:
//               WCMActionRequestNetworkClientSocketUnsubscribe(network: networkId, id: id));
//     };
//     _controllers[id] = BridgeClientStreamEventGrpc(id: id, controller: controller);
//     return controller.stream;
//   }

//   @override
//   Future<BaseServiceSubscribtionResponse> doSubscribtionRequest(
//       {required BaseServiceRequestParams params,
//       required BaseServiceSubscribtionRequest<dynamic, dynamic,
//               BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
//           request,
//       Duration? timeout,
//       bool broadcast = false}) async {
//     final result = await client.sendRequestAndGetResponse(
//       action: WCMActionRequestNetworkClientRequest.socket(
//           network: networkId,
//           identifier: provider.identifier,
//           request: params,
//           subscribtionRequest: request),
//     );
//     final response = result.unwrap();
//     final id = response.subscribtionId;
//     final serviceResponse = switch (response.status) {
//       ServiceResponseType.error => ServiceErrorResponse(
//           statusCode: response.statusCode, error: StringUtils.tryDecode(response.body)),
//       ServiceResponseType.success =>
//         params.toResponse(response.body, statusCode: response.statusCode),
//     };
//     final identifier = request.toIdentifier(serviceResponse);

//     if (identifier != null &&
//         id != null &&
//         serviceResponse.type == ServiceResponseType.success) {
//       final controller = switch (broadcast) {
//         false => StreamController<BaseSubscribtionEvent>(),
//         true => StreamController<BaseSubscribtionEvent>.broadcast()
//       };

//       controller.onCancel = () {
//         client.sendOnChainRequest(
//             action: WCMActionRequestNetworkClientSocketUnsubscribe(
//                 network: networkId, id: id));
//       };
//       _controllers[id] = BridgeClientStreamEventSubscribtion(
//           id: id, controller: controller, request: request);
//       return ServiceSubscribtionResponse(
//           response: serviceResponse, stream: controller.stream);
//     }
//     return ServiceSubscribtionResponse(
//         response: serviceResponse, stream: const Stream.empty());
//   }

//   @override
//   Future<IResult<void>> connect(Duration timeout) async {
//     _listener = client.onChainEvent
//         .where((e) {
//           return switch (e) {
//             BridgeEventOnChainSessionActionClientEventStream(:final request)
//                 when request.network == networkId =>
//               true,
//             _ => false,
//           };
//         })
//         .cast<BridgeEventOnChainSessionActionClientEventStream>()
//         .listen(_onBridgeEvent);
//     return ResultOk(null);
//   }

//   @override
//   bool supportProtocol(ServiceProtocol protocol) {
//     return true;
//   }
// }

// class ExternalNetworkServiceClient extends ExternalServiceClient {
//   @override
//   final int networkId;
//   @override
//   final DefaultAPIProvider provider;
//   ExternalNetworkServiceClient(
//       {required this.networkId,
//       required super.client,
//       required super.session,
//       required this.provider});

//   @override
//   Future<IResult<void>> connect(Duration timeout) async {
//     return ResultOk(null);
//   }

//   @override
//   Future<IResult<List<int>>> doGrpcRequestBridge(
//       {required BaseGRPCServiceRequestParams request, required Duration timeout}) {
//     //  implement doGrpcRequestBridge
//     throw UnimplementedError();
//   }

//   @override
//   Future<IResult<Stream<List<int>>>> doGrpcRequestStreamAsyncBridge(
//       {required BaseGRPCServiceRequestParams request, required Duration timeout}) {
//     //  implement doGrpcRequestStreamAsyncBridge
//     throw UnimplementedError();
//   }

//   @override
//   Future<IResult<BaseServiceResponse>> doHttpRequestBridge(
//       {required BaseServiceRequestParams request,
//       required Uri uri,
//       required NetMode mode,
//       required Duration timeout,
//       List<int>? allowStatus,
//       ProviderAuthenticated? authenticated}) {
//     //  implement doHttpRequestBridge
//     throw UnimplementedError();
//   }

//   @override
//   Future<IResult<BaseServiceResponse>> doSocketRequestBridge(
//       {required BaseServiceRequestParams request,
//       required Duration timeout,
//       Object? overrideData}) {
//     //  implement doSocketRequestBridge
//     throw UnimplementedError();
//   }

//   @override
//   Future<IResult<ServiceSubscribtionResponse>> doSocketRequestBridgeSubscribtion(
//       {required BaseServiceRequestParams params,
//       required BaseServiceSubscribtionRequest<dynamic, dynamic,
//               BaseSubscribtionEvent<dynamic>, BaseServiceRequestParams>
//           request,
//       required Duration timeout}) {
//     //  implement doSocketRequestBridgeSubscribtion
//     throw UnimplementedError();
//   }

//   @override
//   Future<IResult<void>> initTor(Duration timeout) {
//     //  implement initTor
//     throw UnimplementedError();
//   }

//   @override
//   void dispose() {}

//   @override
//   //  implement transportId
//   int? get transportId => null;

//   @override
//   //  implement netApi
//   INetApi get netApi => throw UnimplementedError();
// }
