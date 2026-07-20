part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class SuiMultisigAccountPublicKeyInfo with AppSerialization, Equality {
  final List<int> publicKey;
  final int weight;
  final SuiSupportKeyScheme keyScheme;
  final Bip32DerivationIndex derivationIndex;
  SuiMultisigAccountPublicKeyInfo._(
      {required List<int> publicKey,
      required this.weight,
      required this.keyScheme,
      required this.derivationIndex})
      : publicKey = publicKey.asImmutableBytes;
  factory SuiMultisigAccountPublicKeyInfo.create(
      {required List<int> publicKey,
      required int wieght,
      required SuiSupportKeyScheme keyScheme,
      required Bip32DerivationIndex derivationIndex}) {
    try {
      SuiMultisigPublicKeyInfo(
          publicKey: SuiCryptoPublicKey.fromBytes(
              keyBytes: publicKey, algorithm: keyScheme.suiKeyAlgorithm),
          weight: wieght);
      return SuiMultisigAccountPublicKeyInfo._(
          publicKey: publicKey,
          weight: wieght,
          keyScheme: keyScheme,
          derivationIndex: derivationIndex);
    } catch (_) {
      throw WalletExceptionConst.invalidAccountData(
          "SuiMultisigAccountPublicKeyInfo.create");
    }
  }
  factory SuiMultisigAccountPublicKeyInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.suiMultisigAccountPublicKey);
    return SuiMultisigAccountPublicKeyInfo._(
        publicKey: values.rawValueAt(0),
        weight: values.rawValueAt(1),
        keyScheme: SuiSupportKeyScheme.fromValue(values.rawValueAt(2)),
        derivationIndex:
            Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(3)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.suiMultisigAccountPublicKey;
  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(publicKey),
        CborIntValue(weight),
        CborIntValue(keyScheme.value),
        derivationIndex.toCbor()
      ];
  String toHex() {
    return CryptoKeyUtils.toPublicKeyHex(
        publicKey, derivationIndex.currencyCoin.conf.type);
  }

  @override
  List get variables => [derivationIndex, weight, keyScheme];
}

class SuiMultisigAccountInfo with AppSerialization {
  final List<SuiMultisigAccountPublicKeyInfo> publicKeys;
  final int threshold;
  SuiMultisigAccountInfo._(
      {required List<SuiMultisigAccountPublicKeyInfo> publicKeys,
      required this.threshold})
      : publicKeys = publicKeys.immutable;
  factory SuiMultisigAccountInfo.create(
      {required List<SuiMultisigAccountPublicKeyInfo> publicKeys,
      required int threshold}) {
    try {
      SuiMultisigAccount(
          privateKeys: [],
          publicKey: SuiMultisigAccountPublicKey(
              publicKeys: publicKeys
                  .map((e) => SuiMultisigPublicKeyInfo(
                      publicKey: SuiCryptoPublicKey.fromBytes(
                          keyBytes: e.publicKey, algorithm: e.keyScheme.suiKeyAlgorithm),
                      weight: e.weight))
                  .toList(),
              threshold: threshold));
      return SuiMultisigAccountInfo._(publicKeys: publicKeys, threshold: threshold);
    } catch (_) {
      throw WalletExceptionConst.invalidAccountData("SuiMultisigAccountInfo.create");
    }
  }
  factory SuiMultisigAccountInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.suiMultisigAccountInfo);
    return SuiMultisigAccountInfo._(
        publicKeys: values
            .listAt<CborTagValue>(0)
            .map((e) => SuiMultisigAccountPublicKeyInfo.deserialize(object: e))
            .toList(),
        threshold: values.rawValueAt(1));
  }

  SuiMultisigAccountPublicKey toSuiMutlisigPublicKey() {
    return SuiMultisigAccountPublicKey(
        publicKeys: publicKeys
            .map((e) => SuiMultisigPublicKeyInfo(
                publicKey: SuiCryptoPublicKey.fromBytes(
                    keyBytes: e.publicKey, algorithm: e.keyScheme.suiKeyAlgorithm),
                weight: e.weight))
            .toList(),
        threshold: threshold);
  }

  SuiBaseSignature createTransactionAuthenticated(List<SuiGenericSignature> signatures) {
    int bitmap = 0;
    int weight = 0;
    for (int i = 0; i < publicKeys.length; i++) {
      final publicKey = publicKeys[i];
      bitmap |= 1 << i;
      weight += publicKey.weight;
      if (weight >= threshold) break;
    }
    return SuiMultisigSignature(
        publicKey: toSuiMutlisigPublicKey(), signatures: signatures, bitmap: bitmap);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.suiMultisigAccountInfo;
  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(publicKeys.map((e) => e.toCbor()).toList()),
        CborIntValue(threshold)
      ];
}
