import 'package:on_chain_wallet/network/bridge/types/server/types.dart';

abstract class IBridgeStorage {
  Future<void> savePublishMessage(ClientPublishMessage message);
  Future<void> removePublishMessage(ClientPublishMessage message);
  Future<List<ClientPublishMessage>> publishMessages(String clientId);
  Future<List<ClientPublishMessage>> receiveMessages(String clientId);
}

class BridgeStorageMemory extends IBridgeStorage {
  BridgeStorageMemory();
  List<ClientPublishMessage> cachedMessages = [];

  @override
  Future<List<ClientPublishMessage>> publishMessages(String clientId) async {
    return cachedMessages.where((e) => e.clientId == clientId).toList();
  }

  @override
  Future<List<ClientPublishMessage>> receiveMessages(String clientId) async {
    return cachedMessages.where((e) => e.clientId != clientId).toList();
  }

  @override
  Future<void> removePublishMessage(ClientPublishMessage message) async {
    cachedMessages.remove(message);
  }

  @override
  Future<void> savePublishMessage(ClientPublishMessage message) async {
    cachedMessages.add(message);
  }
}
