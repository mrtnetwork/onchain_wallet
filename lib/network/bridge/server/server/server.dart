// import 'dart:async';
// import 'dart:io';
// import 'package:blockchain_utils/cbor/cbor.dart';
// import 'package:blockchain_utils/utils/utils.dart';
// import 'package:on_chain_bridge/dev/dev.dart';
// import 'package:on_chain_bridge/serialization/serialization.dart';
// import 'package:on_chain_wallet/app/core.dart';
// import 'package:on_chain_wallet/network/bridge/server/storage/core.dart';
// import 'package:on_chain_wallet/network/bridge/server/types/types.dart';

// class BridgeServer {
//   StreamSubscription<HttpRequest>? _subscription;
//   Map<String, BridgeConnection> activeConnections = {};
//   Map<String, BridgeTopicManager> topics = {};
//   final _lock = SafeAtomicLock();

//   Future<void> startService() async {
//     final ip = InternetAddress.anyIPv4;
//     final server = await HttpServer.bind(ip, 8080);
//     _subscription = server.listen(
//       (request) async {
//         if (!WebSocketTransformer.isUpgradeRequest(request)) {
//           _closeConnection(request, "WebSocket connections only.", HttpStatus.forbidden);
//           return;
//         }

//         final clientId = request.uri.queryParameters["projectId"];
//         Logging.debug(
//           fn: () => AppLogData(
//               runtime: runtimeType,
//               function: "startService",
//               msg:
//                   "New connection: $clientId ${activeConnections.containsKey(clientId)}"),
//         );
//         if (clientId == null) {
//           _closeConnection(request, "Missing client id.", HttpStatus.unauthorized);
//           return;
//         }
//         _handleConnection(request, clientId);
//       },
//     );
//   }

//   void close() {
//     _subscription?.cancel();
//     _subscription = null;
//   }

//   String serializeMessage(RelayClientResponse msg) => StringUtils.fromJson(msg.toJson());

//   Future<void> onMessage(dynamic message, String connectionId) async {
//     Logging.debug(
//       fn: () => AppLogData(
//           runtime: runtimeType,
//           function: "onMessage",
//           msg: "New message from $connectionId"),
//     );
//     final String data = JsonParser.valueAsString(message);
//     final toJson = StringUtils.tryToJson<Map<String, dynamic>>(data);
//     if (toJson == null) return;
//     final reLayMessage = RelayClientRequest.fromJson(toJson);
//     final connection = activeConnections[connectionId];
//     if (connection == null) return;
//     RelayClientResponse response;
//     switch (reLayMessage) {
//       case RelayClientPublish message:
//         final topics = this.topics[message.topic] ??= BridgeTopicManager(message.topic);
//         final msg = ClientPublishMessage(message: message, clientId: connectionId);
//         response = await topics.publishMessage(msg);
//         Logging.debug(
//           fn: () => AppLogData(
//               runtime: runtimeType,
//               function: "onMessage",
//               msg: "New topic message ${message.topic}"),
//         );
//         break;
//       case RelayClientSubscribe subscribe:
//         final topics =
//             this.topics[subscribe.topic] ??= BridgeTopicManager(subscribe.topic);
//         await topics.addConnection(connection);
//         response = reLayMessage.toResponse();
//         Logging.debug(
//           fn: () => AppLogData(
//               runtime: runtimeType,
//               function: "onMessage",
//               msg: "Topic subscribe $connectionId ${subscribe.topic}"),
//         );
//         break;
//       case RelayClientUnsubscribe unsubscribe:
//         final topics = this.topics[unsubscribe.topic];
//         await topics?.removeConnection(connection);
//         response = reLayMessage.toResponse();
//         Logging.debug(
//           fn: () => AppLogData(
//               runtime: runtimeType,
//               function: "onMessage",
//               msg: "Topic unsubscribe ${unsubscribe.topic}"),
//         );
//         break;
//       default:
//         response = reLayMessage.toResponse();
//         break;
//     }
//     connection.sendMessage(serializeMessage(response));
//   }

//   Future<void> _handleConnection(HttpRequest request, String connectionId) async {
//     await _lock.run(() async {
//       {
//         final client = activeConnections.remove(connectionId);
//         if (client != null) {
//           client.close();
//         }
//       }
//       final socket = await WebSocketTransformer.upgrade(request);
//       final connection = BridgeConnection(connectionId: connectionId, socket: socket);
//       activeConnections[connectionId] = connection;
//       socket.listen(
//         (message) {
//           onMessage(message, connectionId);
//         },
//         onDone: () {
//           final client = activeConnections.remove(connectionId);
//           client?.close();
//           Logging.debug(
//             fn: () => AppLogData(
//                 runtime: runtimeType,
//                 function: "_handleConnection",
//                 msg: "client disconnected: $connectionId"),
//           );
//           for (final i in topics.values) {
//             if (i.connections.contains(connection)) {
//               i.removeConnection(connection);
//             }
//           }
//         },
//         onError: (error) {
//           Logging.error(
//             fn: () => AppLogData(
//                 runtime: runtimeType,
//                 function: "_handleConnection",
//                 msg: "client err: $connectionId $error"),
//           );
//         },
//       );
//     });
//   }

//   void _closeConnection(HttpRequest request, String msesage, int statusCode) {
//     request.response
//       ..statusCode = statusCode
//       ..write(msesage)
//       ..close();
//   }
// }

// class BridgeConnection with Equality {
//   final String connectionId;
//   final WebSocket socket;
//   bool _closed = false;
//   BridgeConnection({required this.connectionId, required this.socket});

//   bool sendMessage(String msg) {
//     if (_closed) return false;
//     socket.add(msg);
//     return true;
//   }

//   void close() {
//     if (_closed) return;
//     _closed = true;
//     socket.close().catchError((e) => null);
//   }

//   @override
//   List<dynamic> get variables => [connectionId];

//   @override
//   String toString() {
//     return "connectionId: $connectionId, is_online: ${!_closed}";
//   }
// }

// class BridgeTopicManager {
//   final String topic;
//   final _lock = SafeAtomicLock();
//   late final IBridgeStorage storage = BridgeStorageMemory();
//   BridgeTopicManager(this.topic);
//   final List<BridgeConnection> connections = [];

//   Future<void> onNewClient(String connectionId) async {
//     final messages = await storage.receiveMessages(connectionId);
//     for (final i in messages) {
//       await _publish(i);
//     }
//   }

//   Future<void> _publish(ClientPublishMessage message) async {
//     await _lock.run(() {
//       final activeConnections =
//           connections.where((e) => e.connectionId != message.clientId).toList();
//       Logging.debug(
//         fn: () => AppLogData(
//             runtime: runtimeType,
//             function: "_publish",
//             msg:
//                 "message ${message.messageId}, expired: ${message.message.isExpired()}, total connections $activeConnections"),
//       );

//       if (message.message.isExpired() || activeConnections.isEmpty) {
//         storage.removePublishMessage(message);
//         return;
//       }

//       if (activeConnections.isEmpty) return;
//       final messageString = message.toSubscribtionResponse();
//       bool publishOnce = false;
//       for (final i in activeConnections) {
//         publishOnce |= i.sendMessage(messageString);
//         Logging.debug(
//           fn: () => AppLogData(
//               runtime: runtimeType,
//               function: "onMessage",
//               msg:
//                   "Publish message from ${message.clientId} to client ${i.connectionId}"),
//         );
//       }
//       if (publishOnce) storage.removePublishMessage(message);
//     });
//   }

//   Future<void> addConnection(BridgeConnection connection) async {
//     await _lock.run(() async {
//       connections.remove(connection);
//       connections.add(connection);
//     });
//     onNewClient(connection.connectionId);
//   }

//   Future<bool> removeConnection(BridgeConnection connection) async {
//     await _lock.run(() => connections.remove(connection));
//     return true;
//   }

//   Future<RelayClientResponse> publishMessage(ClientPublishMessage message) async {
//     if (message.message.isExpired()) return message.message.toResponse();
//     try {
//       await storage.savePublishMessage(message);
//       return message.message.toResponse();
//     } finally {
//       _publish(message);
//     }
//   }
// }
