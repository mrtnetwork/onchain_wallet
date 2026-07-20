import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';

class IsolateNetSdkConnector {
  final INetSdk netSdk;
  final MessageChannel<ISolateMessageResponse<AppContextMessageNetSdkResponse>,
      ISolateMessageRequest<AppContextMessageNetSdkRequest>> connector;
  final Map<int, StreamSubscription<NetResponseStream>> _listeners = {};
  IsolateNetSdkConnector({required this.netSdk, required this.connector}) {
    connector.stream.listen(onMessage);
  }

  void onMessage(ISolateMessageRequest<AppContextMessageNetSdkRequest> request) {
    switch (request.message) {
      case AppContextMessageNetSdkRequestTransport():
        createTransport(request.as<AppContextMessageNetSdkRequestTransport>());
        break;
      case AppContextMessageNetSdkRequestRequest():
        sendRequest(request.as<AppContextMessageNetSdkRequestRequest>());
        break;
    }
  }

  Future<void> createTransport(
      ISolateMessageRequest<AppContextMessageNetSdkRequestTransport> request) async {
    final transport = await netSdk.createTransport(request.message.request);
    final result = AppContextMessageNetSdkResponseTransport(
        transportId: transport.map((e) => e.transportId));
    connector
        .add(ISolateMessageResponse.from(request: request, response: ResultOk(result)));
    final nRequest = request.message.request;
    transport.map((transport) {
      switch (nRequest.protocol) {
        case NetProtocol.http when !nRequest.http.streaming:
          break;
        default:
          _listeners[transport.transportId] = transport.stream.listen((e) =>
              connector.add(ISolateMessageResponse.from(
                  request: request,
                  id: -1,
                  response: ResultOk(AppContextMessageNetSdkResponseStream(
                      messages: e, transportId: transport.transportId)))));
          break;
      }
    });
  }

  Future<void> sendRequest(
      ISolateMessageRequest<AppContextMessageNetSdkRequestRequest> request) async {
    final msg = request.message;
    Result<NetResponseKind, NetResultStatus> result = await netSdk.sendRequest(
        msg.request.transportId, msg.request.kind, msg.request.timoutSecs);
    final response = AppContextMessageNetSdkResponseRequest(
        result: result.map((e) => NetResponse(
            transportId: msg.request.transportId, requestId: request.id, kind: e)));
    connector.add(ISolateMessageResponse.from(
      response: ResultOk(response),
      request: request,
    ));
    if (msg.request.kind case NetRequestCloseTransport()) {
      final listener = _listeners.remove(msg.request.transportId);
      listener?.cancel();
    }
  }

  Future<void> close() async {
    final subs = _listeners.values.toList();
    _listeners.clear();
    for (final i in subs) {
      i.cancel().catchError((e) => null);
    }
  }
}
