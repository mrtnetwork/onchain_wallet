import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain_wallet/web3/web3/core/request/params.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/web3/core/request/web_request.dart';

typedef TypeCbWcRequest = Future<IResult<Web3MessageCore>> Function(
    Web3RequestWalletConnectApplicationInformation);
typedef TypeCbWcGetLocalAuth = Future<IResult<Web3APPData>> Function();
typedef TypeCbWcAuthRequest = Future<IResult<Web3DappInfo?>> Function(
    Web3ClientInfo onAuthRequest, bool create);
typedef TypeCbWcWalletMessage = void Function(WalletMessageRequest message);
typedef TypeCbWcClientMessage = Future<void> Function(WalletEventRequest message);

abstract class WalletConnectAddress {
  final String address;
  final String chain;
  final List<int>? publicKey;
  WalletConnectAddress(
      {required this.address, required this.chain, required List<int>? publicKey})
      : publicKey = publicKey?.asImmutableBytes;

  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "chains": [chain],
      "publicKey": BytesUtils.tryToHexString(publicKey, prefix: "0x"),
    }.withoutNullValue;
  }

  @override
  String toString() {
    return address;
  }
}

class WalletMessageRequest {
  final Web3WalletRequestParams message;
  final String requestId;
  final String topic;
  final String? wcRequestId;
  const WalletMessageRequest(
      {required this.message,
      required this.requestId,
      required this.topic,
      required this.wcRequestId});
}

class WalletEventRequest {
  final List<WalletConnectClientEvent> event;
  final WCSession? session;
  final String topic;
  const WalletEventRequest({required this.event, required this.topic, this.session});
}
