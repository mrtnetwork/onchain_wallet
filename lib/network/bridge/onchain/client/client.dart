// import 'dart:async';

// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:on_chain_bridge/dev/dev.dart';
// import 'package:on_chain_wallet/app/core.dart';
// import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
// import 'package:on_chain_wallet/network/bridge/client/client.dart';
// import 'package:on_chain_wallet/network/bridge/onchain/types/actions.dart';
// import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
// import 'package:on_chain_wallet/network/bridge/server/types/types.dart';
// import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
// import 'package:on_chain_wallet/network/bridge/types/topic_message.dart';
// import 'package:on_chain_wallet/network/bridge/utils/utils.dart';
// import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages.dart';
// import 'package:on_chain_wallet/crypto/types/sym_key.dart';
// import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';

// // typedef ONGETWALLETSESSIONDATA = Future<WCMSession?> Function(String topic);
// // typedef ONWALLETSESSIONPROPOSEREQUEST = Future<IResult<ExternalWalletBackupWithSession>>
// //     Function(WCMPairingRequest proposal);
// // typedef ONWALLETPAIRVERIFY = Future<IResult<void>> Function(
// //     WCMActionRequestVerifyPair, PairedConnectionSession seesion);

// // typedef ONPAIRINGURI = void Function(Uri uri);

// class BridgeClientOnChainPairing {
//   // final BridgeClientDefault client;
//   // BridgeClientOnChainPairing(this.client) {
//   //   client.onChainEvent.listen(_onEvent);
//   // }

//   // final Map<String, (BridgeSession, Completer<IResult<BridgeEventOnChainPairingPorpose>>)>
//   //     _pairingSessions = {};

//   // Future<void> _onEvent(BridgeEventOnChain event) async {
//   //   switch (event) {
//   //     // case BridgeEventOnChainConnected():
//   //     //   // Handle this case.
//   //     //   throw UnimplementedError();
//   //     // case BridgeEventOnChainDisconnected():
//   //     //   // Handle this case.
//   //     //   throw UnimplementedError();
//   //     // case BridgeEventOnChainPairingAction():
//   //     //   // Handle this case.
//   //     //   throw UnimplementedError();
//   //     // case BridgeEventOnChainMessageStatus():
//   //     //   // Handle this case.
//   //     //   throw UnimplementedError();
//   //     // case BridgeEventOnChainSessionAction():
//   //     //   // Handle this case.
//   //     //   throw UnimplementedError();
//   //     case BridgeEventOnChainPairingPorpose(:final topic):
//   //       _pairingSessions[topic]?.$2.complete(ResultOk(event));
//   //       break;
//   //     default:
//   //       break;
//   //   }
//   // }

//   // Future<IResult<PairedConnectionSession>> createPairingConnection(
//   //     {required ONWALLETSESSIONPROPOSEREQUEST onSessionPropose,
//   //     required ONPAIRINGURI onPiringUri,
//   //     Cancelable? cancelable}) async {
//   //   final connectionKey = await generateConnectionKey();
//   //   return connectionKey.andThenAsync((connectionKey) async {
//   //     final data = BridgeUri(topic: connectionKey.topic, symkey: connectionKey.key);
//   //     final Uri uri = WalletConnectUtils.createUri(data);
//   //     final pairingSession = BridgeSession(
//   //         symKey: connectionKey.key,
//   //         topic: connectionKey.topic,
//   //         type: BridgeSessionType.pairingOnChain,
//   //         protocol: BridgeProtocol.onChain);
//   //     final result = await client.addAndSubscribeSession(pairingSession);

//   //     return result.andThenAsync((_) async {
//   //       onPiringUri(uri);
//   //       final completer = Completer<IResult<BridgeEventOnChainPairingPorpose>>();
//   //       _pairingSessions[connectionKey.topic] = (pairingSession, completer);
//   //       cancelable?.setup(completer);
//   //       Duration? timeout = data.timeout();
//   //       if (timeout == null) {
//   //         return ResultErr<PairedConnectionSession>.fromException(
//   //             BridgeExceptionConst.pairingRequestTimeout);
//   //       }
//   //       final result = await completer.future.timeout(
//   //         timeout,
//   //         onTimeout: () {
//   //           return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
//   //         },
//   //       );
//   //       if (result.isError(BridgeExceptionConst.pairingRequestTimeout)) {
//   //         disconnectPairing(pairingSession);
//   //       }
//   //       return result.andThenAsync(
//   //         (proposal) async {
//   //           final key = QuickCrypto.generateRandom();
//   //           final symKey =
//   //               SymKey(privateKey: key, targetPublicKey: proposal.request.publicKey);
//   //           final response = await onSessionPropose(
//   //               WCMPairingRequest(request: proposal.request, key: symKey));
//   //           return response.andAsync(
//   //             (value, error) async {
//   //               if (error != null) {
//   //                 client.publish(BridgeRequestMessage.response(
//   //                     response: TopicResponseError.wallet(error.exception),
//   //                     session: proposal.message.session,
//   //                     correlationId: proposal.correlationId));
//   //                 return error.cast();
//   //               }
//   //               final pairingInfo = WCMActionPairingPorposeResponse(
//   //                   encryptedWallet: value!.encodedBackup, publicKey: symKey.publicKey());
//   //               final result = await client.publish(BridgeRequestMessage.response(
//   //                   response: TopicResponseSuccess.wallet(pairingInfo),
//   //                   session: proposal.message.session,
//   //                   correlationId: proposal.correlationId));
//   //               return result.mapAsync(
//   //                 (_) {
//   //                   return PairedConnectionSession(
//   //                       session: WCMSession(value.session), symKey: symKey, uri: data);
//   //                 },
//   //               );
//   //             },
//   //           );
//   //         },
//   //       );
//   //     });
//   //   });
//   // }

//   // Future<IResult<WCMExternalWalletBackup>> pair(
//   //     {required Uri uri, Cancelable? cancelable}) async {
//   //   final BridgeUri parsedUri = WalletConnectUtils.parseUri(uri);
//   //   final String topic = parsedUri.topic;
//   //   final methods = parsedUri.methods.map(BridgeKnownMethods.fromName);
//   //   if (methods.any((e) => e == BridgeKnownMethods.unregisteredMethod)) {
//   //     return ResultErr.fromException(BridgeExceptionConst.unsuportedMethod);
//   //   }
//   //   Duration? timeout = parsedUri.timeout();
//   //   if (timeout == null) {
//   //     return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
//   //   }

//   //   final pairingSession = BridgeSession(
//   //       symKey: parsedUri.symkey,
//   //       topic: topic,
//   //       type: BridgeSessionType.pairingOnChain,
//   //       protocol: BridgeProtocol.onChain);
//   //   final subscribe = await client.addAndSubscribeSession(pairingSession);
//   //   return subscribe.andThenAsync((_) async {
//   //     final timeout = parsedUri.timeout();
//   //     if (timeout == null) {
//   //       return ResultErr.fromException(BridgeExceptionConst.pairingRequestTimeout);
//   //     }
//   //     final symKey = await generateKeyPair();
//   //     final action = WCMActionPairingPorpose(
//   //         expiry: DateTime.now().add(timeout), publicKey: symKey.publicKey);
//   //     final result = await client.sendRequestAndGetResponse(
//   //       action: action,
//   //       session: pairingSession,
//   //     );
//   //     return result.andThenAsync((data) async {
//   //       return ResultOk(WCMExternalWalletBackup(
//   //           backup: ExternalWalletBackup.deserialize(bytes: data.encryptedWallet),
//   //           key: SymKey(privateKey: symKey.privateKey, targetPublicKey: data.publicKey)));
//   //     });
//   //   });
//   // }

//   // Future<IResult<PairedConnectionSession>> walletPairing(
//   //     {required ONWALLETSESSIONPROPOSEREQUEST onSessionPropose,
//   //     required ONPAIRINGURI onPiringUri,
//   //     required ONWALLETPAIRVERIFY onVerifyPairing,
//   //     Cancelable? cancelable}) async {
//   //   throw UnimplementedError();
//   // }

//   // Future<X25519Keypair> generateKeyPair() async {
//   //   return X25519Keypair.generate();
//   // }

//   // Future<IResult<PairingConnectionKey>> generateConnectionKey() async {
//   //   final key = QuickCrypto.generateRandom();
//   //   final result = await client.context.cryptoLib.excute(NoneEncryptedRequestHashing(
//   //       type: CryptoRequestHashingType.sha256, dataBytes: key));
//   //   return result.map((hash) =>
//   //       PairingConnectionKey(key: key, topic: BytesUtils.toHexString(hash.data)));
//   // }

//   // Future<GeneratedSharedKey> generateSymKey(SymKey symKey) async {
//   //   final result = await client.context.cryptoLib.excuteSync(
//   //       message: CryptoRequestGenerateWalletConnectSymKeyInfo(
//   //           publicKey: symKey.targetPublicKey, privateKey: symKey.privateKey),
//   //       context: client.context);
//   //   return result.unwrap();
//   // }

//   // Future<void> disconnectPairing(BridgeSession session) async {
//   //   final pairing = _pairingSessions.remove(session.topic);
//   //   if (pairing == null) return;
//   //   client.disconnectPairing(session);
//   // }

//   // Future<IResult<void>> listenOnSession(IBridgeSession session) async {
//   //   return client.subscribe(session);
//   // }
// }
