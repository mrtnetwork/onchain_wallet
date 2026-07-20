part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class AccessMnemonicResponse extends CryptoKeyData {
  final Mnemonic mnemonic;
  final List<SubWalletMnemonicResponse> subWallets;
  AccessMnemonicResponse._(
      {required this.mnemonic, required List<SubWalletMnemonicResponse> subWallets})
      : subWallets = subWallets.immutable,
        super._();

  factory AccessMnemonicResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accessMnemonicResponse);
    return AccessMnemonicResponse._(
      mnemonic: Mnemonic.fromString(values.rawValueAt(0)),
      subWallets: values
          .listAt<CborTagValue>(1)
          .map((e) => SubWalletMnemonicResponse.deserialize(object: e))
          .toList(),
    );
  }

  // @override
  // String get keyName => "mnemonic";

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.accessMnemonicResponse;

  @override
  List<CborObject?> get serializationItems => [
        CborStringValue(mnemonic.toStr()),
        CborListValue.definite(subWallets.map((e) => e.toCbor()).toList())
      ];
}

final class SubWalletMnemonicResponse with AppSerialization {
  final int subWalletId;
  final Mnemonic mnemonic;
  const SubWalletMnemonicResponse._({required this.subWalletId, required this.mnemonic});

  factory SubWalletMnemonicResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.subWalletMnemonicResponse);
    return SubWalletMnemonicResponse._(
        mnemonic: Mnemonic.fromString(values.rawValueAt(0)),
        subWalletId: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.subWalletMnemonicResponse;

  @override
  List<CborObject?> get serializationItems => [
        CborStringValue(mnemonic.toStr()),
        CborIntValue(subWalletId),
      ];
}
