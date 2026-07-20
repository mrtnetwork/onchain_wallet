import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:zcash_dart/zcash.dart';

class FakeSaplingHashable extends Hashable<SaplingNode> {
  @override
  SaplingNode combine(
      {required TreeLevel level, required SaplingNode a, required SaplingNode b}) {
    throw UnimplementedError();
  }

  @override
  SaplingNode emptyLeaf() {
    throw UnimplementedError();
  }
}

class FakeOrchardHashable extends Hashable<OrchardMerkleHash> {
  @override
  OrchardMerkleHash combine(
      {required TreeLevel level,
      required OrchardMerkleHash a,
      required OrchardMerkleHash b}) {
    throw UnimplementedError();
  }

  @override
  OrchardMerkleHash emptyLeaf() {
    throw UnimplementedError();
  }
}

class SerializableChainMerkleState with AppSerialization {
  final ChainMerkleState state;
  const SerializableChainMerkleState(this.state);
  factory SerializableChainMerkleState.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return SerializableChainMerkleState(ChainMerkleState.deserialize(
        object: values.objectAt(0),
        orchardHashable: FakeOrchardHashable(),
        saplingHashable: FakeSaplingHashable()));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [state.toCbor()];
}
