// import 'package:on_chain_wallet/app/core.dart';
// import 'package:on_chain_wallet/bridge/client/client.dart';
// import 'package:on_chain_wallet/bridge/onchain/types/actions.dart';
// import 'package:on_chain_wallet/bridge/onchain/types/types.dart';
// import 'package:on_chain_wallet/wallet/api/service/core/service.dart';
// import 'package:on_chain_wallet/wallet/api/service/manager/default.dart';
// import 'package:on_chain_wallet/wallet/api/service/protocols/external.dart';
// import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
// import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
// import 'package:on_chain_wallet/wallet/wallet.dart';

// class ExternalNetworkServiceManager<
//         PROVIDER extends APIProvider,
//         NETWORK extends WalletNetwork,
//         CLIENT extends CLIENTNWORK<NETWORK>,
//         NPROVIDER extends NetworkApiProvider<NETWORK, CLIENT, PROVIDER>>
//     extends DefaultNetworkServiceManager<PROVIDER, NETWORK, CLIENT, NPROVIDER> {
//   final WCMSession session;
//   @override
//   final BridgeClientDefault bridgeClient;
//   final Duration timeout;
//   final Duration? requestCooldown;
//   @override
//   final NETWORK network;
//   void onBrdigeEvent(BridgeEventOnChainSessionActionClientEventProviderChanged event) {
//     onChangeProvider(event.request.provider.cast<NPROVIDER>());
//   }

//   ExternalNetworkServiceManager(
//       {required this.timeout,
//       required this.requestCooldown,
//       required this.network,
//       required this.bridgeClient,
//       required this.session}) {
//     bridgeClient.onChainEvent
//         .where((e) {
//           return switch (e) {
//             BridgeEventOnChainSessionActionClientEventProviderChanged(:final request) =>
//               request.network == network.value,
//             _ => false
//           };
//         })
//         .cast<BridgeEventOnChainSessionActionClientEventProviderChanged>()
//         .listen(onBrdigeEvent);
//   }

//   @override
//   Future<MultiChainServiceClient> clientCreateService(APIProvider provider) async {
//     return MultiChainServiceClient.fromProviderAndClient(
//         provider: provider,
//         timeout: timeout,
//         client: ExternalNetworkServiceClient(
//             networkId: network.value,
//             client: bridgeClient,
//             session: session,
//             provider: provider));
//   }

//   @override
//   Future<IResult<NPROVIDER?>> getActiveService() async {
//     final provider = await bridgeClient.sendOnChainRequestAndGetResult(
//         action: WCMActionRequestNetworkClientConnect(network: network.value));
//     return provider.map((e) => e.cast<NPROVIDER>());
//   }

//   @override
//   void onClientStatusChanged(INetworkServiceNotify status) {
//   }
// }
