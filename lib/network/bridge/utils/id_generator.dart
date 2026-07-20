import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';

abstract class BridgeMessageType {
  abstract final int type;

  static BridgeMessageType? fromType(int clientId, int? type) {
    if (type != null && type <= 2) {
      return PublishBridgeMessageType.fromType(type);
    }
    if (clientId >= BinaryOps.mask8) {
      return WCMBridgeMessageType.fromType(type);
    }
    return Web3BridgeMessageType.fromType(type);
  }
}

enum PublishBridgeMessageType implements BridgeMessageType {
  response(0),
  request(1),
  subscribe(2);

  @override
  final int type;
  const PublishBridgeMessageType(this.type);
  static PublishBridgeMessageType? fromType(int? type) {
    return values.firstWhereOrNull((e) => e.type == type);
  }
}

enum WCMBridgeMessageType implements BridgeMessageType {
  pairing(3),
  event(4),
  storage(5),
  client(6),
  wallet(7);

  @override
  final int type;
  const WCMBridgeMessageType(this.type);
  static WCMBridgeMessageType? fromType(int? type) {
    return values.firstWhereOrNull((e) => e.type == type);
  }
}

enum Web3BridgeMessageType implements BridgeMessageType {
  pairing(4),
  settle(5),
  update(6),
  delete(7),
  event(8),
  ping(9),
  request(10),
  ;

  @override
  final int type;
  const Web3BridgeMessageType(this.type);
  static Web3BridgeMessageType? fromType(int? type) {
    return values.firstWhereOrNull((e) => e.type == type);
  }
}

class WCNextIdGenerator {
  final int clientId;

  final _nanoMul = BigInt.from(1000000);
  BigInt _nextRcpId = BigInt.from(QuickCrypto.generateRandomInt(BinaryOps.mask16));
  int _nextPayloadId = QuickCrypto.generateRandomInt(BinaryOps.mask8);
  WCNextIdGenerator(this.clientId);
  static BigInt nextRandomRpcId() {
    return (BigInt.from(DateTime.now().millisecondsSinceEpoch) * BigInt.from(1000000)) +
        BigInt.from(QuickCrypto.generateRandomInt(BinaryOps.mask16));
  }

  BigInt nextRpcId() {
    return (BigInt.from(DateTime.now().millisecondsSinceEpoch) * _nanoMul) +
        (_nextRcpId += BigInt.one);
  }

  int nextPayloadId(BridgeMessageType request) {
    return DateTime.now().microsecondsSinceEpoch + _nextPayloadId++;
  }
}
