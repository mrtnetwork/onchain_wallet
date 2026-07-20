// import 'package:blockchain_utils/utils/atomic/atomic.dart';
// import 'package:on_chain_wallet/app/core.dart';
// import 'package:on_chain_wallet/network/bridge/server/server/server.dart';
// import 'package:on_chain_wallet/network/bridge/server/types/types.dart';
// import 'package:on_chain_wallet/repository/action/action.dart';
// import 'package:on_chain_wallet/repository/core/controller.dart';

// import 'core.dart';

// typedef ONSTORAGEREADY<T> = Future<T> Function(List<ClientPublishMessage> cachedMessages);

// class BridgeStorageDefault extends IBridgeStorage {
//   final String topic;
//   @override
//   int get storage => APPDatabaseConst.bridgeStorage;

//   @override
//   String get tableId => APPDatabaseConst.mainTableName;

//   BridgeStorageDefault(this.topic);
//   List<ClientPublishMessage>? _cachedMessages;
//   final _lock = SafeAtomicLock();

//   @override
//   Future<void> savePublishMessage(ClientPublishMessage message) async {
//     await onStorageReady((cachedMessages) async {
//       cachedMessages.add(message);
//       // await insertStorage(
//       //     storageId: APPDatabaseConst.bridgeMessagesStorageId,
//       //     actionId: StorageActionId.bridge,
//       //     key: topic,
//       //     keyA: message.messageId,
//       //     value: message);
//     });
//   }

//   @override
//   Future<void> removePublishMessage(ClientPublishMessage message) async {
//     await onStorageReady((cachedMessages) async {
//       cachedMessages.remove(message);
//       // removeStorages(
//       //   actionId: StorageActionId.bridge,
//       //   storageId: APPDatabaseConst.bridgeMessagesStorageId,
//       //   key: topic,
//       //   keyA: message.messageId,
//       // );
//     });
//   }

//   @override
//   Future<List<ClientPublishMessage>> publishMessages(String clientId) async {
//     return onStorageReady(
//       (cachedMessages) async {
//         return cachedMessages.where((e) => e.clientId == clientId).toList();
//       },
//     );
//   }

//   @override
//   Future<List<ClientPublishMessage>> receiveMessages(String clientId) async {
//     return onStorageReady(
//       (cachedMessages) async {
//         return cachedMessages.where((e) => e.clientId != clientId).toList();
//       },
//     );
//   }

//   Future<List<ClientPublishMessage>> _getTopicMessages() async {
//     final cachedMessages = _cachedMessages;
//     return [];
//     // if (cachedMessages != null) return cachedMessages;
//     // return _lock.run(() async {
//     //   return _cachedMessages ??= await () async {
//     //     final data = await queriesStorageData(
//     //         actionId: StorageActionId.bridge,
//     //         storageId: APPDatabaseConst.bridgeMessagesStorageId,
//     //         key: topic);
//     //     return data.map((e) => ClientPublishMessage.deserialize(bytes: e)).toList();
//     //   }();
//     // });
//   }

//   Future<T> onStorageReady<T>(ONSTORAGEREADY<T> onReady) async {
//     final messages = await _getTopicMessages();
//     return onReady(messages);
//   }
// }
