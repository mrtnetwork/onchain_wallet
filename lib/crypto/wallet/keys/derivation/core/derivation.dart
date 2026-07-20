part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

enum AddressDerivationType {
  bip32(AppSerializationIdentifier.accoutKeyIndex),
  substrate(AppSerializationIdentifier.substrateKeyIndex),
  multisig(AppSerializationIdentifier.multiSigAccountKeyIndex);

  final AppSerializationIdentifier tag;
  const AddressDerivationType(this.tag);
  bool get isMultiSig => this == AddressDerivationType.multisig;

  static AddressDerivationType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("AddressDerivationType"));
  }
}

sealed class DerivableIndex extends DerivationIndex {
  const DerivableIndex();
  String? get hdPath;

  DerivableIndex asImportedKey(int importKeyId);
  DerivableIndex asSubWalletKey(int subId);
  DerivableIndex asMainWallet();
  CryptoPrivateKeyData _derive(CryptoPrivateKeyData masterKey);
  SeedTypes get seedGeneration;
  CryptoCoins get currencyCoin;
  factory DerivableIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue cbor =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final key = AddressDerivationType.fromTag(cbor.tags);
    switch (key) {
      case AddressDerivationType.bip32:
        return Bip32DerivationIndex.deserialize(object: cbor);
      case AddressDerivationType.substrate:
        return SubstrateDerivationIndex.deserialize(object: cbor);
      case AddressDerivationType.multisig:
        throw AppCryptoExceptionConst.invalidDerivationKey;
    }
  }
  int? get subId;
  int? get importedKeyId;
  @override
  bool get isImportedKey => importedKeyId != null;
  bool get isSubstrate => derivationType == AddressDerivationType.substrate;
  bool get isBip32 => derivationType == AddressDerivationType.bip32;
  bool get isMaster;

  DerivableIndex toMaster();
}

sealed class DerivationIndex with AppSerialization, Equality {
  const DerivationIndex();
  AddressDerivationType get derivationType;
  String get name;
  bool get isMultiSig => derivationType.isMultiSig;
  bool get isImportedKey => false;

  factory DerivationIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue cbor =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final key = AddressDerivationType.fromTag(cbor.tags);
    switch (key) {
      case AddressDerivationType.bip32:
        return Bip32DerivationIndex.deserialize(object: cbor);
      case AddressDerivationType.substrate:
        return SubstrateDerivationIndex.deserialize(object: cbor);
      // case AddressDerivationType.zip32:
      //   return Zip32AddressIndex.deserialize(object: cbor);
      case AddressDerivationType.multisig:
        return MultiSigAddressIndex();
    }
  }

  T cast<T extends DerivationIndex>() {
    if (this is! T) {
      throw AppInternalError.internalError("DerivationIndex");
    }
    return this as T;
  }
}
