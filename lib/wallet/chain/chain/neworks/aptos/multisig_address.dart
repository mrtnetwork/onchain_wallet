part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class AptosMultisigAccountPublicKeyInfo with AppSerialization, Equality {
  /// public key bytes
  final List<int> publicKey;

  /// Aptos crypto key scheme (ED25519,Secp256k1)
  final AptosSupportKeyScheme keyScheme;

  /// bip32 key index for generate private key.
  final Bip32DerivationIndex derivationIndex;
  AptosMultisigAccountPublicKeyInfo._(
      {required List<int> publicKey,
      required this.keyScheme,
      required this.derivationIndex})
      : publicKey = publicKey.asImmutableBytes;
  factory AptosMultisigAccountPublicKeyInfo.create(
      {required List<int> publicKey,
      required AptosSupportKeyScheme keyScheme,
      required Bip32DerivationIndex derivationIndex}) {
    try {
      switch (keyScheme) {
        case AptosSupportKeyScheme.multiEd25519:
        case AptosSupportKeyScheme.multiKey:
          throw WalletExceptionConst.invalidAccountData(
              "AptosMultisigAccountPublicKeyInfo.create");
        default:
          break;
      }
      return AptosMultisigAccountPublicKeyInfo._(
          publicKey: publicKey, keyScheme: keyScheme, derivationIndex: derivationIndex);
    } catch (_) {
      throw WalletExceptionConst.invalidAccountData(
          "AptosMultisigAccountPublicKeyInfo.create");
    }
  }
  factory AptosMultisigAccountPublicKeyInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.aptosMultisigAccountPublicKey);
    return AptosMultisigAccountPublicKeyInfo._(
        publicKey: values.rawValueAt(0),
        keyScheme: AptosSupportKeyScheme.fromValue(values.rawValueAt(1)),
        derivationIndex:
            Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(2)));
  }

  String toHex() {
    return CryptoKeyUtils.toPublicKeyHex(
        publicKey, derivationIndex.currencyCoin.conf.type);
  }

  @override
  List get variables => [derivationIndex, keyScheme];

  /// convert to aptos public key for creating authenticated.
  PUBLICKEY toAptosPublicKey<PUBLICKEY extends AptosCryptoPublicKey>() {
    final AptosCryptoPublicKey publicKey = switch (keyScheme) {
      AptosSupportKeyScheme.ed25519 ||
      AptosSupportKeyScheme.signleKeyEd25519 =>
        AptosED25519PublicKey.fromBytes(this.publicKey),
      AptosSupportKeyScheme.signleKeySecp256k1 =>
        AptosSecp256k1PublicKey.fromBytes(this.publicKey),
      _ => throw WalletExceptionConst.invalidAccountData(
          "AptosMultisigAccountPublicKeyInfo.toAptosPublicKey")
    };
    return publicKey.cast();
  }

  /// convert to IPublic key for generating address
  PUBLICKEY toPublicKey<PUBLICKEY extends IPublicKey>() {
    final IPublicKey publicKey = switch (keyScheme) {
      AptosSupportKeyScheme.ed25519 ||
      AptosSupportKeyScheme.signleKeyEd25519 =>
        Ed25519PublicKey.fromBytes(this.publicKey),
      AptosSupportKeyScheme.signleKeySecp256k1 =>
        Secp256k1PublicKey.fromBytes(this.publicKey),
      _ => throw WalletExceptionConst.invalidAccountData(
          "AptosMultisigAccountPublicKeyInfo.toPublicKey")
    };
    if (publicKey is! PUBLICKEY) {
      throw AppInternalError.internalError("AptosMultisigAccountPublicKeyInfo");
    }
    return publicKey;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.aptosMultisigAccountPublicKey;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(publicKey),
        CborIntValue(keyScheme.value),
        derivationIndex.toCbor()
      ];
}

class AptosMultisigAccountInfo with AppSerialization {
  /// List of public keys
  final List<AptosMultisigAccountPublicKeyInfo> publicKeys;

  /// required signature
  final int requiredSignature;

  /// multisig keyscheme. (MultiEd25519 or MultiKey)
  final AptosSupportKeyScheme keyScheme;
  AptosMultisigAccountInfo._(
      {required List<AptosMultisigAccountPublicKeyInfo> publicKeys,
      required this.requiredSignature,
      required this.keyScheme})
      : publicKeys = publicKeys.immutable;
  factory AptosMultisigAccountInfo.create(
      {required List<AptosMultisigAccountPublicKeyInfo> publicKeys,
      required AptosSupportKeyScheme keyScheme,
      required int requiredSignature}) {
    try {
      switch (keyScheme) {
        case AptosSupportKeyScheme.multiEd25519:
          AptosMultiEd25519AccountPublicKey(
              threshold: requiredSignature,
              publicKeys: publicKeys
                  .map((e) => e.toAptosPublicKey<AptosED25519PublicKey>())
                  .toList());
          break;
        case AptosSupportKeyScheme.multiKey:
          AptosMultiKeyAccountPublicKey(
              requiredSignature: requiredSignature,
              publicKeys: publicKeys.map((e) => e.toAptosPublicKey()).toList());
          break;
        default:
          throw WalletExceptionConst.invalidAccountData(
              "AptosMultisigAccountInfo.create");
      }
      return AptosMultisigAccountInfo._(
          publicKeys: publicKeys,
          requiredSignature: requiredSignature,
          keyScheme: keyScheme);
    } catch (_) {
      throw WalletExceptionConst.invalidAccountData("AptosMultisigAccountInfo.create");
    }
  }
  factory AptosMultisigAccountInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.aptosMultisigAccountInfo);
    return AptosMultisigAccountInfo._(
        publicKeys: values
            .listAt<CborTagValue>(0)
            .map((e) => AptosMultisigAccountPublicKeyInfo.deserialize(object: e))
            .toList(),
        requiredSignature: values.rawValueAt(1),
        keyScheme: AptosSupportKeyScheme.fromValue(values.rawValueAt(2)));
  }

  /// generate mutlisig public key for create authenticated.
  PUBLICKEY toAptosMutlisigPublicKey<PUBLICKEY extends AptosAccountPublicKey>() {
    final publicKey = switch (keyScheme) {
      AptosSupportKeyScheme.multiEd25519 => AptosMultiEd25519AccountPublicKey(
          publicKeys:
              publicKeys.map((e) => e.toAptosPublicKey<AptosED25519PublicKey>()).toList(),
          threshold: requiredSignature),
      AptosSupportKeyScheme.multiKey => AptosMultiKeyAccountPublicKey(
          publicKeys: publicKeys.map((e) => e.toAptosPublicKey()).toList(),
          requiredSignature: requiredSignature),
      _ => throw WalletExceptionConst.invalidAccountData(
          "AptosMultisigAccountInfo.toAptosMutlisigPublicKey")
    };
    return publicKey.cast();
  }

  /// generate aptos authenticated for transaction.
  AptosAccountAuthenticator createAccountAuthenticated(
      List<AptosAnySignature> signatures) {
    assert(signatures.length == requiredSignature, "invalid signature length.");
    if (signatures.length < requiredSignature) {
      throw AppCryptoException("insufficient_signatures");
    }
    final bitmap =
        AptosUtils.createSignatureBitMap(List.generate(requiredSignature, (i) => i));
    switch (keyScheme) {
      case AptosSupportKeyScheme.multiEd25519:
        return AptosAccountAuthenticatorMultiEd25519(
            publicKey: toAptosMutlisigPublicKey(),
            signature: AptosMultiEd25519Signature(
                signatures: signatures
                    .map((e) => AptosEd25519Signature(e.signatureBytes()))
                    .toList(),
                bitmap: bitmap));
      case AptosSupportKeyScheme.multiKey:
        return AptosAccountAuthenticatorMultiKey(
            publicKey: toAptosMutlisigPublicKey(),
            signature: AptosMultiKeySignature(signatures: signatures, bitmap: bitmap));
      default:
        throw WalletExceptionConst.invalidAccountData(
            "AptosMultisigAccountInfo.createAccountAuthenticated");
    }
  }

  /// generate aptos address
  AptosAddress generateAddress() {
    final String address = switch (keyScheme) {
      AptosSupportKeyScheme.multiEd25519 => AptosAddrEncoder().encodeMultiEd25519Key(
          publicKeys: publicKeys.map((e) => e.toPublicKey<Ed25519PublicKey>()).toList(),
          threshold: requiredSignature),
      AptosSupportKeyScheme.multiKey => AptosAddrEncoder().encodeMultiKey(
          publicKeys: publicKeys.map((e) => e.toPublicKey()).toList(),
          requiredSignature: requiredSignature),
      _ => throw WalletExceptionConst.invalidAccountData(
          "AptosMultisigAccountInfo.generateAddress")
    };
    return AptosAddress(address);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.aptosMultisigAccountInfo;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(publicKeys.map((e) => e.toCbor()).toList()),
        CborIntValue(requiredSignature),
        CborIntValue(keyScheme.value)
      ];
}
