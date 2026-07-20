import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/substrate/substrate.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

abstract class LookupField {
  const LookupField();
  T cast<T extends LookupField>() {
    if (this is! T) {
      throw AppInternalError.internalError("LookupField");
    }
    return this as T;
  }
}

class CallLookupField extends LookupField {
  final MetadataTypeInfo type;
  final int lockupId;
  final Si1Variant variant;
  final CallMethodInfo method;
  const CallLookupField(
      {required this.type,
      required this.lockupId,
      required this.variant,
      required this.method});
}

class StorageLookupField extends LookupField {
  final MetadataTypeInfo? form;
  final StorageInfo storage;
  const StorageLookupField({required this.form, required this.storage});
}

class SubstrateStorageQueryParams {
  final StorageInfo storage;
  final Object? input;
  final String pallet;
  const SubstrateStorageQueryParams({
    required this.pallet,
    required this.storage,
    required this.input,
  });
}

class RuntimeMethodLookupField extends LookupField {
  final List<MetadataTypeInfo> validators;
  final RuntimeApiMethodInfo method;
  final String apiName;
  RuntimeMethodLookupField(
      {required List<MetadataTypeInfo> validators,
      required this.method,
      required this.apiName})
      : validators = validators.immutable;
}

class ExtrinsicPayloadInfo {
  final String payload;
  final List<int> payloadBytes;
  final List<int> callHash;
  final String serializedExtrinsic;
  final Object? payloadInfo;
  final List<int> methodBytes;
  final String method;
  final DynamicExtrinsicBuilder? extrinsic;
  ExtrinsicPayloadInfo._(
      {required this.payload,
      required this.serializedExtrinsic,
      required this.payloadInfo,
      required this.method,
      required this.extrinsic,
      required List<int> methodBytes,
      required List<int> payloadBytes,
      required List<int> callHash})
      : payloadBytes = payloadBytes.asImmutableBytes,
        callHash = callHash.asImmutableBytes,
        methodBytes = methodBytes.asImmutableBytes;
  factory ExtrinsicPayloadInfo(
      {required List<int> serializedExtrinsic,
      DynamicExtrinsicBuilder? extrinsic,
      Object? payloadInfo,
      required List<int> method}) {
    final payload = SubstrateUtils.createPayload(serializedExtrinsic);
    return ExtrinsicPayloadInfo._(
        payload: BytesUtils.toHexString(payload, prefix: "0x"),
        serializedExtrinsic: BytesUtils.toHexString(serializedExtrinsic, prefix: "0x"),
        payloadInfo: payloadInfo,
        method: BytesUtils.toHexString(method, prefix: "0x"),
        payloadBytes: payload,
        extrinsic: extrinsic,
        callHash: SubstrateUtils.callHash(method),
        methodBytes: method);
  }
}

class ExtrinsicInfo {
  final int version;
  final ExtrinsicPayloadInfo payload;
  final String serializedExtrinsic;
  final List<int>? encodeSignature;
  ExtrinsicInfo._({
    required this.payload,
    required this.serializedExtrinsic,
    required this.version,
    List<int>? signature,
  }) : encodeSignature = signature?.asImmutableBytes;
  factory ExtrinsicInfo({
    required int version,
    required ExtrinsicPayloadInfo payload,
    required String serializedExtrinsic,
    // bool signed = true,
    required List<int>? encodeSignature,
  }) {
    return ExtrinsicInfo._(
        payload: payload,
        serializedExtrinsic: _serialize(
            serializedExtrinsic: serializedExtrinsic,
            methodData: payload.method,
            extrinsicVersion: version,
            signed: encodeSignature != null),
        version: version,
        signature: encodeSignature);
  }
  static String _serialize(
      {required String serializedExtrinsic,
      required String methodData,
      required int extrinsicVersion,
      bool signed = true}) {
    final extrinsicBytes = BytesUtils.fromHexString(serializedExtrinsic);
    final callData = BytesUtils.fromHexString(methodData);
    final version = (extrinsicVersion |
        (signed ? SubstrateConstant.bitSigned : SubstrateConstant.bitUnsigned));
    final encode = [version, ...extrinsicBytes, ...callData];
    return BytesUtils.toHexString(encode, prefix: "0x");
  }

  List<int> serialize({bool encodeLength = true}) {
    final extrinsicBytes = BytesUtils.fromHexString(serializedExtrinsic);
    if (encodeLength) {
      final length =
          LayoutSerializationUtils.encodeLength(extrinsicBytes.length.toString());
      return [...length, ...extrinsicBytes];
    }
    return extrinsicBytes;
  }

  String serializeHex({bool encodeLength = true}) {
    return BytesUtils.toHexString(serialize(), prefix: '0x');
  }
}

class SubstrateDefaultTransfer {
  final BaseSubstrateAddress address;
  final BigInt value;
  SubstrateDefaultTransfer({required this.address, required this.value});
  Object _getDest(SubstrateAddressEncodingType type) {
    return switch (type) {
      SubstrateAddressEncodingType.substrate => {"Id": address.toBytes()},
      SubstrateAddressEncodingType.key32 ||
      SubstrateAddressEncodingType.ethereum =>
        address.toBytes(),
    };
  }

  Map<String, dynamic> toJson(
      {required SubstrateAddressEncodingType addressType,
      BalancesCallPalletMethod method = BalancesCallPalletMethod.transferAllowDeath,
      bool usePallet = false}) {
    final toJson = {
      method.method: {"dest": _getDest(addressType), "value": value}
    };
    if (!usePallet) return toJson;
    return {SubtrateMetadataPallet.balances.name: toJson};
  }

  List<int> encode(
      {required MetadataApi metadata,
      required SubstrateAddressEncodingType addressType,
      BalancesCallPalletMethod method = BalancesCallPalletMethod.transferAllowDeath}) {
    final Map<String, dynamic> input = {
      method.method: {"dest": _getDest(addressType), "value": value}
    };
    return metadata.encodeCall(
        palletNameOrIndex: "balances", value: input, fromTemplate: false);
  }
}
