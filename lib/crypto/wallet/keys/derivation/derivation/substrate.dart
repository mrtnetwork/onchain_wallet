part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class SubstrateDerivationIndex extends DerivableIndex {
  @override
  final int? importedKeyId;
  final String? keyName;
  final String? substratePath;
  @override
  String? get hdPath => substratePath;

  @override
  final SeedTypes seedGeneration;

  @override
  final SubstrateCoins currencyCoin;

  @override
  bool get isMaster => substratePath == null;

  SubstrateDerivationIndex._(
      {required this.currencyCoin,
      this.subId,
      this.importedKeyId,
      this.keyName,
      required this.substratePath})
      : seedGeneration = SeedTypes.bip39Entropy;

  factory SubstrateDerivationIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.substrateKeyIndex);
    return SubstrateDerivationIndex._(
      currencyCoin: CoinsUtils.getSerializationCoin(values.rawValueAt(0)),
      substratePath: values.rawValueAt(1),
      keyName: values.rawValueAt(3),
      subId: values.rawValueAt(4),
      importedKeyId: values.rawValueAt(5),
    );
  }
  factory SubstrateDerivationIndex(
      {required SubstrateCoins currencyCoin, String? substratePath, String? keyName}) {
    if (currencyCoin.proposal != CoinProposal.substrate) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    if (substratePath != null) {
      final path = SubstratePathParser.parse(substratePath);
      substratePath = path.elems.isEmpty ? null : path.toStr();
    }

    return SubstrateDerivationIndex._(
        currencyCoin: currencyCoin,
        keyName: keyName,
        substratePath: substratePath,
        subId: null);
  }

  factory SubstrateDerivationIndex.fromPath(
      {required String substratePath, required SubstrateCoins currencyCoin}) {
    return SubstrateDerivationIndex(
        currencyCoin: currencyCoin, keyName: null, substratePath: substratePath);
  }

  @override
  DerivableIndex asImportedKey(int importKeyId) {
    if (subId != null) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    return SubstrateDerivationIndex._(
        currencyCoin: currencyCoin,
        importedKeyId: importKeyId,
        keyName: keyName,
        substratePath: substratePath,
        subId: subId);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.substrateKeyIndex;

  @override
  List<CborObject?> get serializationItems => [
        currencyCoin.identifier.toCbor(),
        hdPath?.toCbor(),
        CborNullValue(),
        keyName?.toCbor(),
        subId?.toCbor(),
        importedKeyId?.toCbor()
      ];

  @override
  List get variables => [currencyCoin.conf.type, substratePath, subId, importedKeyId];

  @override
  String toString() {
    return hdPath ?? "non_derivation";
  }

  @override
  AddressDerivationType get derivationType {
    return AddressDerivationType.substrate;
  }

  @override
  String get name => keyName ?? "main_key";

  @override
  CryptoPrivateKeyData _derive(CryptoPrivateKeyData masterKey) {
    final substratePath = this.substratePath;
    if (substratePath == null) return masterKey;
    final substrate = Substrate.fromPrivateKey(masterKey.privateKeyBytes(), currencyCoin);
    final derive = substrate.derivePath(substratePath);
    return PrivateKeyData._(coin: masterKey.coin, key: derive.priveKey.privKey);
  }

  @override
  final int? subId;

  @override
  SubstrateDerivationIndex asSubWalletKey(int subId) {
    if (importedKeyId != null) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    return SubstrateDerivationIndex._(
        currencyCoin: currencyCoin,
        importedKeyId: importedKeyId,
        keyName: keyName,
        substratePath: substratePath,
        subId: subId);
  }

  @override
  DerivableIndex asMainWallet() {
    return SubstrateDerivationIndex._(
        currencyCoin: currencyCoin,
        importedKeyId: null,
        keyName: keyName,
        substratePath: substratePath,
        subId: null);
  }

  @override
  DerivableIndex toMaster() {
    return SubstrateDerivationIndex._(
        currencyCoin: currencyCoin,
        importedKeyId: importedKeyId,
        keyName: keyName,
        substratePath: null,
        subId: subId);
  }
}
