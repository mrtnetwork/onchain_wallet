import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

import 'package:on_chain_wallet/crypto/wallet/keys.dart';

sealed class SignResponse with AppSerialization {
  T cast<T extends SignResponse>() {
    if (this is! T) {
      throw AppInternalError.internalError("CryptoPublicKeyData");
    }
    return this as T;
  }
}

final class GlobalSignResponse extends SignResponse {
  final List<int> signature;
  final DerivationIndex index;
  final CryptoPublicKeyData signerPubKey;
  GlobalSignResponse({
    required List<int> signature,
    required this.index,
    required this.signerPubKey,
  }) : signature = signature.asImmutableBytes;

  factory GlobalSignResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.globalSignature,
        cborObject: object);
    final index = DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0));
    final List<int> signature = values.rawValueAt(1);
    return GlobalSignResponse(
        signature: signature,
        index: index,
        signerPubKey:
            CryptoPublicKeyData.deserialize(object: values.objectAt<CborTagValue>(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.globalSignature;

  @override
  List<CborObject?> get serializationItems =>
      [index.toCbor(), signature.toCborBytes(), signerPubKey.toCbor()];
}

final class ZcashSignResponse extends SignResponse {
  final List<int> txData;
  final List<int> txHash;
  ZcashSignResponse({
    required List<int> txData,
    required List<int> txHash,
  })  : txData = txData.asImmutableBytes,
        txHash = txHash.asImmutableBytes;

  factory ZcashSignResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.runtimeTag,
        cborObject: object);
    return ZcashSignResponse(txData: values.rawValueAt(0), txHash: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [AppSerialization.bytesToCbor(txData), AppSerialization.bytesToCbor(txHash)];
}
