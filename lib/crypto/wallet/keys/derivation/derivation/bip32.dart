part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

typedef Zip32DerivationIndex = Bip32DerivationIndex;

final class Bip32DerivationIndex extends DerivableIndex {
  final int? purpose;
  final int? coin;
  final int? accountLevel;
  final int? changeLevel;
  final int? addressIndex;
  @override
  final int? importedKeyId;
  final String? keyName;

  @override
  final String? hdPath;

  @override
  final SeedTypes seedGeneration;
  @override
  final CryptoCoins currencyCoin;

  @override
  final int? subId;

  Bip32DerivationIndex._({
    this.purpose,
    this.coin,
    this.accountLevel,
    this.changeLevel,
    this.addressIndex,
    required this.currencyCoin,
    required this.seedGeneration,
    this.importedKeyId,
    this.keyName,
    this.subId,
    String? hdPath,
  }) : hdPath =
            hdPath ?? _toPath([purpose, coin, accountLevel, changeLevel, addressIndex]);

  factory Bip32DerivationIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.accoutKeyIndex,
    );
    return Bip32DerivationIndex._(
        purpose: values.rawValueAt(0),
        coin: values.rawValueAt(1),
        accountLevel: values.rawValueAt(2),
        changeLevel: values.rawValueAt(3),
        addressIndex: values.rawValueAt(4),
        currencyCoin: CoinsUtils.getSerializationCoin(values.rawValueAt(5)),
        seedGeneration: SeedTypes.fromValue(values.rawValueAt(6)),
        keyName: values.rawValueAt(8),
        subId: values.rawValueAt(9),
        importedKeyId: values.rawValueAt(10));
  }
  factory Bip32DerivationIndex.byronLegacy(
      {required int firstIndex,
      required int secoundIndex,
      required CryptoCoins currencyCoin,
      String? keyName}) {
    return Bip32DerivationIndex(
        purpose: firstIndex,
        coin: secoundIndex,
        accountLevel: null,
        changeLevel: null,
        addressIndex: null,
        currencyCoin: currencyCoin,
        seedGeneration: SeedTypes.byronLegacySeed,
        keyName: keyName);
  }
  factory Bip32DerivationIndex.defaultBip(
      {required BipCoins coin, required SeedTypes seedGeneration}) {
    final path = Bip32PathParser.parse(coin.conf.defPath);
    return Bip32DerivationIndex(
      currencyCoin: coin,
      seedGeneration: seedGeneration,
      purpose: coin.proposal.purpose.index,
      coin: Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index,
      accountLevel: path.elems.elementAtOrNull(0)?.index,
      changeLevel: path.elems.elementAtOrNull(1)?.index,
      addressIndex: path.elems.elementAtOrNull(2)?.index,
    );
  }
  factory Bip32DerivationIndex.defaultZip(
      {required ZIP32Coins coin, required SeedTypes seedGeneration}) {
    final path = Bip32PathParser.parse(coin.conf.defPath);
    return Bip32DerivationIndex(
      currencyCoin: coin,
      seedGeneration: seedGeneration,
      purpose: coin.proposal.purpose.index,
      coin: Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index,
      accountLevel: path.elems.elementAtOrNull(0)?.index,
      changeLevel: path.elems.elementAtOrNull(1)?.index,
      addressIndex: path.elems.elementAtOrNull(2)?.index,
    );
  }

  factory Bip32DerivationIndex(
      {int? purpose,
      int? coin,
      int? accountLevel,
      int? changeLevel,
      int? addressIndex,
      required CryptoCoins currencyCoin,
      required SeedTypes seedGeneration,
      String? keyName}) {
    if ((!currencyCoin.proposal.isBip && !currencyCoin.proposal.isZip) ||
        currencyCoin.conf.type == EllipticCurveTypes.sr25519) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    return Bip32DerivationIndex._(
        purpose: purpose,
        coin: coin,
        accountLevel: accountLevel,
        changeLevel: changeLevel,
        addressIndex: addressIndex,
        currencyCoin: currencyCoin,
        seedGeneration: seedGeneration,
        keyName: keyName);
  }

  Bip32DerivationIndex copyWith(
      {int? purpose,
      int? coin,
      int? accountLevel,
      int? changeLevel,
      int? addressIndex,
      String? keyName}) {
    return Bip32DerivationIndex._(
        purpose: purpose ?? this.purpose,
        coin: coin ?? this.coin,
        accountLevel: accountLevel ?? this.accountLevel,
        changeLevel: changeLevel ?? this.changeLevel,
        addressIndex: addressIndex ?? this.addressIndex,
        seedGeneration: seedGeneration,
        currencyCoin: currencyCoin,
        importedKeyId: importedKeyId,
        keyName: keyName ?? this.keyName,
        subId: subId);
  }

  factory Bip32DerivationIndex.fromPath(
      {required String path,
      required CryptoCoins currencyCoin,
      required SeedTypes seedGeneration}) {
    final indexes = Bip32PathParser.parse(path).elems;
    if (indexes.length > 5) {
      throw AppCryptoException("unsupported_hd_wallet_index");
    }
    return Bip32DerivationIndex(
        purpose: indexes.elementAtOrNull(0)?.index,
        coin: indexes.elementAtOrNull(1)?.index,
        accountLevel: indexes.elementAtOrNull(2)?.index,
        changeLevel: indexes.elementAtOrNull(3)?.index,
        addressIndex: indexes.elementAtOrNull(4)?.index,
        currencyCoin: currencyCoin,
        seedGeneration: seedGeneration,
        keyName: null);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.accoutKeyIndex;

  @override
  List<CborObject?> get serializationItems => [
        purpose?.toCbor(),
        coin?.toCbor(),
        accountLevel?.toCbor(),
        changeLevel?.toCbor(),
        addressIndex?.toCbor(),
        currencyCoin.identifier.toCbor(),
        seedGeneration.value.toCbor(),
        CborNullValue(),
        keyName?.toCbor(),
        subId?.toCbor(),
        importedKeyId?.toCbor()
      ];

  @override
  List get variables => [
        purpose,
        coin,
        accountLevel,
        changeLevel,
        addressIndex,
        currencyCoin.conf.type,
        seedGeneration.name,
        importedKeyId,
        subId,
      ];

  static String? _toPath(List<int?> indexses) {
    if (indexses.isEmpty) return null;
    bool hasNull = false;
    for (final i in indexses) {
      if (hasNull && i != null) {
        throw AppCryptoExceptionConst.invalidDerivationKey;
      }
      hasNull |= i == null;
    }
    final bipIndexes = indexses.whereType<int>().map((e) => Bip32KeyIndex(e)).toList();
    if (bipIndexes.isEmpty) return null;
    return Bip32Path(elems: bipIndexes).toPath();
  }

  Bip44Levels level() => Bip44Levels.values.firstWhere((e) => e.value == _indexes.length);

  @override
  CryptoPrivateKeyData _derive(CryptoPrivateKeyData masterKey) {
    if (indexes.isEmpty) {
      return masterKey;
    }
    final key = masterKey.toHdKey();
    List<Bip32KeyIndex> bip32KeyIndexes = indexes.immutable;
    HDKeyManager deriveToIndex = key;
    for (final i in bip32KeyIndexes) {
      deriveToIndex = switch (deriveToIndex) {
        Zip32Base zip32 => zip32.childKey(i, context: OnChainCryptoContext.instance),
        _ => deriveToIndex.childKey(i)
      } as HDKeyManager;
    }
    return CryptoPrivateKeyData._fromBip32(account: deriveToIndex, coin: masterKey.coin);
  }

  List<int> get _indexes => <int?>[purpose, coin, accountLevel, changeLevel, addressIndex]
      .whereType<int>()
      .toList();

  List<Bip32KeyIndex> get indexes => _indexes.map((e) => Bip32KeyIndex(e)).toList();

  @override
  String toString() {
    return hdPath ?? "non_derivation";
  }

  @override
  AddressDerivationType get derivationType {
    return AddressDerivationType.bip32;
  }

  @override
  String get name => keyName ?? "main_key";

  @override
  Bip32DerivationIndex asImportedKey(int importKeyId) {
    if (subId != null) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    return Bip32DerivationIndex._(
        purpose: purpose,
        coin: coin,
        accountLevel: accountLevel,
        changeLevel: changeLevel,
        addressIndex: addressIndex,
        currencyCoin: currencyCoin,
        seedGeneration: seedGeneration,
        subId: subId,
        importedKeyId: importKeyId,
        keyName: keyName);
  }

  Bip32DerivationIndex take(Bip44Levels level) {
    final indexValues = _indexes;
    if (indexValues.length == level.value) return this;
    final indexes = indexValues.take(level.value).map((e) => Bip32KeyIndex(e)).toList();
    return Bip32DerivationIndex._(
      currencyCoin: currencyCoin,
      seedGeneration: seedGeneration,
      subId: subId,
      importedKeyId: importedKeyId,
      keyName: keyName,
      purpose: indexes.elementAtOrNull(0)?.index,
      coin: indexes.elementAtOrNull(1)?.index,
      accountLevel: indexes.elementAtOrNull(2)?.index,
      changeLevel: indexes.elementAtOrNull(3)?.index,
      addressIndex: indexes.elementAtOrNull(4)?.index,
    );
  }

  @override
  Bip32DerivationIndex asMainWallet() {
    return Bip32DerivationIndex._(
        purpose: purpose,
        coin: coin,
        accountLevel: accountLevel,
        changeLevel: changeLevel,
        addressIndex: addressIndex,
        currencyCoin: currencyCoin,
        seedGeneration: seedGeneration,
        subId: null,
        importedKeyId: null,
        keyName: keyName);
  }

  @override
  Bip32DerivationIndex asSubWalletKey(int subId) {
    if (importedKeyId != null) {
      throw AppCryptoExceptionConst.invalidDerivationKey;
    }
    return Bip32DerivationIndex._(
        purpose: purpose,
        coin: coin,
        accountLevel: accountLevel,
        changeLevel: changeLevel,
        addressIndex: addressIndex,
        currencyCoin: currencyCoin,
        seedGeneration: seedGeneration,
        subId: subId,
        importedKeyId: importedKeyId,
        keyName: keyName);
  }

  Bip32DerivationIndex? tryIncrementLatestLevel() {
    final cLevel = level();
    if (cLevel == Bip44Levels.master) {
      throw AppCryptoExceptionConst.unsupportedDerivationIncreament;
    }
    int? increment(Bip44Levels level) {
      int? v = switch (level) {
        Bip44Levels.master =>
          throw AppCryptoExceptionConst.unsupportedDerivationIncreament,
        Bip44Levels.purpose => purpose,
        Bip44Levels.coin => coin,
        Bip44Levels.account => accountLevel,
        Bip44Levels.change => changeLevel,
        Bip44Levels.addressIndex => addressIndex,
      };
      if (level == cLevel) {
        if (v == null) {
          throw AppInternalError.internalError("Level should not be null.");
        }
        final increment = v += 1;
        if (Bip32KeyIndex.isValidBip32Index(increment)) return increment;
        throw AppCryptoExceptionConst.bip32IndexOutOfRange;
      }
      return v;
    }

    try {
      return Bip32DerivationIndex._(
          purpose: increment(Bip44Levels.purpose),
          accountLevel: increment(Bip44Levels.account),
          addressIndex: increment(Bip44Levels.addressIndex),
          changeLevel: increment(Bip44Levels.change),
          coin: increment(Bip44Levels.coin),
          keyName: keyName,
          currencyCoin: currencyCoin,
          seedGeneration: seedGeneration,
          importedKeyId: importedKeyId,
          subId: subId);
    } catch (e) {
      if (e == AppCryptoExceptionConst.bip32IndexOutOfRange) {
        return null;
      }
      rethrow;
    }
  }

  Bip44Changes? change() =>
      Bip44Changes.values.firstWhereOrNull((e) => e.value == changeLevel);
  Bip32DerivationIndex withName(String name) {
    return Bip32DerivationIndex._(
        purpose: purpose,
        coin: coin,
        accountLevel: accountLevel,
        changeLevel: changeLevel,
        addressIndex: addressIndex,
        seedGeneration: seedGeneration,
        currencyCoin: currencyCoin,
        importedKeyId: importedKeyId,
        keyName: name,
        subId: subId,
        hdPath: hdPath);
  }

  @override
  bool get isMaster => purpose == null;

  @override
  DerivableIndex toMaster() {
    return Bip32DerivationIndex._(
      purpose: null,
      coin: null,
      accountLevel: null,
      changeLevel: null,
      addressIndex: null,
      seedGeneration: seedGeneration,
      currencyCoin: currencyCoin,
      importedKeyId: importedKeyId,
      keyName: name,
      subId: subId,
    );
  }
}
