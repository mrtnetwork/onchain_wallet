import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateMultisigCall with AppSerialization, Equality {
  final List<int>? callData;
  final List<int> callHash;
  final String callHashHex;
  final String? callDataHex;
  SubstrateMultisigCall({List<int>? callData, required List<int> callHash})
      : callData = callData?.asImmutableBytes,
        callHash = callHash.asImmutableBytes,
        callHashHex = BytesUtils.toHexString(callHash),
        callDataHex = BytesUtils.tryToHexString(callData);
  factory SubstrateMultisigCall.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.substrateMultisigCall);
    return SubstrateMultisigCall(
        callData: values.rawValueAt(0), callHash: values.rawValueAt(1));
  }

  @override
  List get variables => [callHash];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.substrateMultisigCall;

  @override
  List<CborObject?> get serializationItems =>
      [callData?.toCborBytes(), CborBytesValue(callHash)];
}

class SubstrateMultisigCallData {
  final SubstrateMultisigCall call;
  final SubstrateWeightV2? weight;
  final Map<String, dynamic>? content;
  final SubstrateMultisig? multisig;
  SubstrateMultisigCallData copyWith({
    SubstrateMultisigCall? call,
    SubstrateWeightV2? weight,
    Map<String, dynamic>? content,
    SubstrateMultisig? multisig,
  }) {
    return SubstrateMultisigCallData(
        call: call ?? this.call,
        weight: weight ?? this.weight,
        content: content ?? this.content,
        multisig: multisig ?? this.multisig);
  }

  SubstrateMultisigCallData(
      {required this.call, this.weight, Map<String, dynamic>? content, this.multisig})
      : content = content?.immutable;
}
