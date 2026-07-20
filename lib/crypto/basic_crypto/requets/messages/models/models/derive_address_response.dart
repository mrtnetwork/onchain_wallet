import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

final class CryptoDeriveAddressResponse with AppSerialization {
  final NewAccountParams accountParams;
  final CryptoPublicKeyData? publicKey;

  CryptoDeriveAddressResponse({required this.accountParams, this.publicKey});
  factory CryptoDeriveAddressResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return CryptoDeriveAddressResponse(
        accountParams: NewAccountParams.deserialize(object: values.objectAt(0)),
        publicKey: values.maybeObjectAt<CryptoPublicKeyData, CborTagValue>(
            1, (e) => CryptoPublicKeyData.deserialize(object: e)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [accountParams.toCbor(), publicKey?.toCbor()];
}
