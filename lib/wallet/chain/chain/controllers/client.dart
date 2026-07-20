part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class DefaultMainChainClientContext<
        NETWORKADDRESS extends IAddress,
        TOKEN extends TokenCore,
        NFT extends NFTCore,
        NETWORK extends WalletNetwork,
        TRANSACTION extends ChainTransaction,
        ADDRESS extends ChainAccount<NETWORKADDRESS, TOKEN, NFT, TRANSACTION, NETWORK>,
        CLIENT extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
        NETWORKPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>>
    extends DefaultNetworkServiceManager<NETWORK, CLIENT, NETWORKPROVIDER>
    implements
        IChainContext<NETWORKADDRESS, TOKEN, NFT, NETWORK, TRANSACTION, ADDRESS, CLIENT,
            NETWORKPROVIDER> {
  // @override
  // BridgeClientDefault get bridgeClient => controller.bridgeController();
  // final Map<String, StreamSubscription<List<int>>> _subscribtions = {};
  // void _clientPublishEvent(
  //     {required WCMEventNetworkClient event, required WCMSession session}) {
  //   // controller.bridgeController().sendOnChainRequest(action: event, session: session);
  // }

  // void _clientHandleSubscribtion(
  //     {required Stream<List<int>> stream,
  //     required String subId,
  //     required WCMSession session}) {
  //   StreamSubscription<List<int>> subscription = stream.listen(
  //     (e) {
  //       final data =
  //           WCMEventNetworkClientStreamData(data: e, id: subId, network: network.value);
  //       _clientPublishEvent(event: data, session: session);
  //       // _publishResponse(response: ResultOk(data), event: event)
  //     },
  //     onError: (e) {
  //       final data = WCMEventNetworkClientStreamStatus(
  //           status: WCMEventNetworkClientStreamStatusType.disconnect,
  //           id: subId,
  //           error: IExceptionUtils.findError(e),
  //           network: network.value);
  //       _clientPublishEvent(event: data, session: session);
  //     },
  //     onDone: () {
  //       final data = WCMEventNetworkClientStreamStatus(
  //           status: WCMEventNetworkClientStreamStatusType.disconnect,
  //           id: subId,
  //           network: network.value);
  //       _clientPublishEvent(event: data, session: session);
  //     },
  //   );
  //   _subscribtions[subId] = subscription;
  // }

  // Future<IResult<T>> _clientPublishResponse<T extends AppSerialization?>(
  //     {required IResult<T> response,
  //     required BridgeEventOnChainSessionActionClient event}) async {
  //   final publish = await bridgeClient.publish(BridgeRequestMessage.response(
  //       response: response.fold(
  //         onOk: (e) => TopicResponseSuccess(e?.toCbor().encode() ?? <int>[]),
  //         onErr: (error) => TopicResponseError.wallet(error.exception),
  //       ),
  //       session: event.session,
  //       correlationId: event.correlationId));
  //   return publish.andThen((_) => response);
  // }

  // Future<IResult<({MultiChainServiceClient service, CLIENT client})>> _clientGetService(
  //     IServiceRequestParams request, String identifier) async {
  //   final client = await this.client();
  //   return client.andThen((e) {
  //     final provider = e.networkProvider.getRequestProvider(request);
  //     return provider.andThen((p) {
  //       final service = e.services().firstWhereOrNull((e) => e.provider == p);
  //       if (service == null) {
  //         return ResultErr.fromException(WalletExceptionConst.providerNotFound);
  //       }
  //       return ResultOk((service: service, client: e));
  //     });
  //   });
  // }

  // Future<void> _onBrdigeEvent(BridgeEventOnChainSessionActionClient event) async {
  //   switch (event.request) {
  //     case WCMActionRequestNetworkClientRequest request:
  //       final result =
  //           await (await _clientGetService(request.request, request.providerIdentifier))
  //               .andThenAsync<BridgeClientRequestResponse>((e) async {
  //
  //         ///
  //         return await e.service
  //             .doRequestBridge(request, timeout: const Duration(seconds: 3));
  //       });
  //       _clientPublishResponse(
  //               response: result.map((e) {
  //                 final response = e.response;
  //                 if (response.subscribtionId == null || e.stream == null) {
  //                   return response;
  //                 }
  //                 return response.withSubscribtionId(
  //                     "${network.value}_${event.session.clientId}_${UUID.generateUUIDv4()}");
  //               }),
  //               event: event)
  //           .then((e) {
  //         e.foldOne(
  //           (value, error) {
  //             final subscribtionId = value?.subscribtionId;
  //             final stream = result.ok()?.stream;
  //             if (subscribtionId == null || stream == null) return;
  //             _clientHandleSubscribtion(
  //                 stream: stream, subId: subscribtionId, session: event.session);
  //           },
  //         );
  //       });
  //       break;
  //     case WCMActionRequestNetworkClientSocketUnsubscribe(:var id):
  //       final subscribtion = _subscribtions.remove(id);
  //       subscribtion?.cancel();
  //       _clientPublishResponse(response: ResultOk(null), event: event);
  //       break;
  //     case WCMActionRequestNetworkClientConnect():
  //       final result = (await client()).map((e) {
  //         return e.networkProvider;
  //       });
  //       _clientPublishResponse(response: result, event: event);
  //       break;
  //   }
  // }

  @override
  Future<MultiChainServiceClient> clientCreateService(DefaultAPIProvider provider) async {
    return MultiChainServiceClient.fromProvider(
        provider: provider, netApi: controller.config.netApi);
  }
}
