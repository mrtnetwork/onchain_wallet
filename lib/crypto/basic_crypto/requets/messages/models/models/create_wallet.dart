import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';

final class CryptoCreateWalletResponse with AppSerialization {
  final ViewMasterKey masterKey;
  final List<int> checksum;
  CryptoCreateWalletResponse({required this.masterKey, required List<int> checksum})
      : checksum = checksum.asImmutableBytes;

  factory CryptoCreateWalletResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoCreateWalletResponse(
        masterKey: ViewMasterKey.deserialize(object: values.objectAt(0)),
        checksum: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [masterKey.toCbor(), CborBytesValue(checksum)];
}
