part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

enum CryptoPublicKeyDataType {
  public(AppSerializationIdentifier.accessPubliKeyResponse),
  ada(AppSerializationIdentifier.accessAdaPubliKeyResponse),
  monero(AppSerializationIdentifier.accessMoneroPublicKeyResponse),
  zip32(AppSerializationIdentifier.accessZip32PublicKeyResponse);

  final AppSerializationIdentifier tag;
  const CryptoPublicKeyDataType(this.tag);
  static CryptoPublicKeyDataType fromTag(List<int>? tags) {
    return CryptoPublicKeyDataType.values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("CryptoPublicKeyDataType"));
  }
}

enum CryptoPrivateKeyDataType {
  public(AppSerializationIdentifier.accessPrivateKeyResponse),
  ada(AppSerializationIdentifier.accessAdaLegacyPrivateKeyResponse),
  monero(AppSerializationIdentifier.accessMoneroPrivateKeyResponse),
  zip32(AppSerializationIdentifier.accessZip32PrivateKeyResponse);

  final AppSerializationIdentifier tag;
  const CryptoPrivateKeyDataType(this.tag);
  static CryptoPrivateKeyDataType fromTag(List<int>? tags) {
    return CryptoPrivateKeyDataType.values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("CryptoPrivateKeyDataType"));
  }
}

sealed class CryptoKeyData with AppSerialization {
  // abstract final String keyName;
  const CryptoKeyData._();
}

sealed class CryptoPublicKeyData extends CryptoKeyData {
  CryptoPublicKeyData._(
      {required this.type,
      required this.extendedKey,
      required this.comprossed,
      required this.chainCode,
      required this.uncomprossed,
      required this.curve,
      required this.coin})
      : super._();
  final CryptoPublicKeyDataType type;
  final String? extendedKey;
  final String comprossed;
  final String? chainCode;
  final String? uncomprossed;
  final EllipticCurveTypes curve;
  final CryptoCoins coin;

  late final String normalizedComprossedKey =
      CryptoKeyUtils.normalizePublicKeyHex(comprossed, curve);

  late final List<int> normalizedComprossedBytes =
      BytesUtils.fromHexString(normalizedComprossedKey).immutable;

  PublicKeysView get toViewKey => PublicKeysView._(
      extendKey: extendedKey,
      comprossed: comprossed,
      uncomprossed: uncomprossed,
      chainCode: chainCode,
      // keyName: keyName,
      keyType: type);

  factory CryptoPublicKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue cbor =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = CryptoPublicKeyDataType.fromTag(cbor.tags);
    switch (type) {
      case CryptoPublicKeyDataType.public:
        return PublicKeyData.deserialize(object: cbor);
      case CryptoPublicKeyDataType.ada:
        return AdaLegacyPublicKeyData.deserialize(object: cbor);
      case CryptoPublicKeyDataType.monero:
        return MoneroPublicKeyData.deserialize(object: cbor);
      case CryptoPublicKeyDataType.zip32:
        return Zip32PublicKeyData.deserialize(object: cbor);
    }
  }

  List<int> keyBytes(
      {PubKeyModes mode = PubKeyModes.compressed, bool immutable = false}) {
    final List<int> keyBytes = switch (mode) {
      PubKeyModes.compressed => BytesUtils.fromHexString(comprossed),
      PubKeyModes.uncompressed => () {
          assert(uncomprossed != null, "should not use uncomprossed mode.");
          return BytesUtils.fromHexString(uncomprossed ?? comprossed);
        }(),
    };
    if (immutable) return keyBytes.asImmutableBytes;
    return keyBytes;
  }

  List<int>? uncomprossedkeyBytes() {
    return BytesUtils.tryFromHexString(uncomprossed);
  }

  List<int>? chainCodeBytes() {
    return BytesUtils.tryFromHexString(chainCode);
  }

  List<int> bip32KeyBytes() {
    return [
      ...keyBytes(),
      ...chainCodeBytes() ?? List<int>.filled(0, Bip32KeyDataConst.chaincodeByteLen)
    ];
  }

  T cast<T extends CryptoPublicKeyData>() {
    if (this is! T) {
      throw AppInternalError.internalError("CryptoPublicKeyData");
    }
    return this as T;
  }

  HDKeyManager? toHdKey();
}

sealed class CryptoPrivateKeyData extends CryptoKeyData {
  abstract final CryptoPrivateKeyDataType type;
  const CryptoPrivateKeyData._() : super._();
  HDKeyManager toHdKey();
  List<int> privateKeyBytes();
  abstract final String privateKey;
  abstract final String? extendedKey;
  abstract final CryptoPublicKeyData publicKey;
  abstract final CryptoCoins coin;
  abstract final String? wif;
  PrivateKeysView get toViewKey => PrivateKeysView._(
      extendKey: extendedKey,
      privateKey: privateKey,
      wif: wif,
      curve: coin.conf.type,
      // keyName: keyName,
      keyType: type,
      inNetworkStyle: null);
  factory CryptoPrivateKeyData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue cbor =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = CryptoPrivateKeyDataType.fromTag(cbor.tags);
    switch (type) {
      case CryptoPrivateKeyDataType.public:
        return PrivateKeyData.deserialize(object: cbor);
      case CryptoPrivateKeyDataType.ada:
        return ADALegacyPrivateKeyData.deserialize(object: cbor);
      case CryptoPrivateKeyDataType.monero:
        return MoneroPrivateKeyData.deserialize(object: cbor);
      case CryptoPrivateKeyDataType.zip32:
        return Zip32PrivateKeyData.deserialize(object: cbor);
    }
  }
  factory CryptoPrivateKeyData._fromSeed(
      {required CryptoCoins coin,
      // required String keyName,
      required List<int> seedBytes}) {
    switch (coin) {
      case SubstrateCoins coin:
        final substrate =
            CryptoKeyUtils.seedToSubstratePrivateKey(seedBytes: seedBytes, coin: coin);
        return PrivateKeyData._(coin: coin, key: substrate);
      case ZIP32Coins coin:
        return Zip32PrivateKeyData._fromSeed(seedBytes: seedBytes, coin: coin);
      case BipCoins coin:
        final account = CryptoKeyUtils.seedToBipKey(seedBytes: seedBytes, coin: coin);
        return CryptoPrivateKeyData._fromBip32(account: account, coin: coin);
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
  }
  factory CryptoPrivateKeyData._fromBip32({
    required HDKeyManager account,
    required CryptoCoins coin,
  }) {
    switch (account) {
      case Zip32Base account when coin is ZIP32Coins:
        return Zip32PrivateKeyData._fromZip32(account: account, coin: coin);
      case Bip32Base account when coin == Bip44Coins.moneroEd25519Slip:
        return MoneroPrivateKeyData._fromBip32(account: account, coin: coin);
      case Bip32Base account:
        return PrivateKeyData._fromBip32(coin: coin, account: account);
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
  }
  T cast<T extends CryptoPrivateKeyData>() {
    if (this is! T) {
      throw AppInternalError.internalError("CryptoPrivateKeyData");
    }
    return this as T;
  }
}

enum Zip32Porotcol {
  zcashOrchard(1),
  zcashSapling(2);

  final int value;
  const Zip32Porotcol(this.value);
  static Zip32Porotcol fromValue(int? value) {
    return Zip32Porotcol.values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("Zip32Porotcol"));
  }
}

sealed class BaseZip32PrivateKeyData extends CryptoPrivateKeyData {
  const BaseZip32PrivateKeyData() : super._();
  abstract final Zip32Porotcol protocol;
}

sealed class BaseZip32PublicKeyData extends CryptoPublicKeyData {
  BaseZip32PublicKeyData(
      {required super.type,
      required super.extendedKey,
      required super.chainCode,
      required super.comprossed,
      required super.uncomprossed,
      required super.curve,
      required this.protocol,
      required super.coin})
      : super._();
  final Zip32Porotcol protocol;
}

final class CryptoPublicKeyDataWithInfo with AppSerialization {
  final CryptoPublicKeyData key;
  final DerivableIndex index;
  final PublicKeysView viewKey;
  final String? walletName;
  final String? importedKeyName;
  CryptoPublicKeyDataWithInfo(
      {required this.key,
      required this.index,
      this.walletName,
      this.importedKeyName,
      PublicKeysView? viewKey})
      : viewKey = viewKey ?? key.toViewKey;
  factory CryptoPublicKeyDataWithInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborObject: object,
        cborBytes: bytes);
    return CryptoPublicKeyDataWithInfo(
        key: CryptoPublicKeyData.deserialize(object: values.objectAt(0)),
        index: DerivableIndex.deserialize(object: values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [key.toCbor(), index.toCbor()];

  CryptoPublicKeyDataWithInfo copyWith({
    CryptoPublicKeyData? key,
    DerivableIndex? index,
    PublicKeysView? viewKey,
    String? walletName,
    String? importedKeyName,
  }) {
    return CryptoPublicKeyDataWithInfo(
        key: key ?? this.key,
        index: index ?? this.index,
        viewKey: viewKey ?? this.viewKey,
        walletName: walletName ?? this.walletName,
        importedKeyName: importedKeyName ?? this.importedKeyName);
  }
}

final class CryptoPrivateKeyDataWithInfo with AppSerialization {
  final CryptoPrivateKeyData key;
  final DerivableIndex? index;
  final PrivateKeysView viewKey;
  final String? walletName;
  final String? importedKeyName;
  CryptoPrivateKeyDataWithInfo(
      {required this.key,
      this.index,
      this.walletName,
      this.importedKeyName,
      PrivateKeysView? viewKey})
      : viewKey = viewKey ?? key.toViewKey;
  factory CryptoPrivateKeyDataWithInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborObject: object,
        cborBytes: bytes);
    return CryptoPrivateKeyDataWithInfo(
        key: CryptoPrivateKeyData.deserialize(object: values.objectAt(0)),
        index: values.maybeObjectAt<DerivableIndex, CborTagValue>(
            1, (e) => DerivableIndex.deserialize(object: e)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [key.toCbor(), index?.toCbor()];

  CryptoPrivateKeyDataWithInfo copyWith({
    CryptoPrivateKeyData? key,
    DerivableIndex? index,
    PrivateKeysView? viewKey,
    String? walletName,
    String? importedKeyName,
  }) {
    return CryptoPrivateKeyDataWithInfo(
        key: key ?? this.key,
        index: index ?? this.index,
        viewKey: viewKey ?? this.viewKey,
        walletName: walletName ?? this.walletName,
        importedKeyName: importedKeyName ?? this.importedKeyName);
  }
}
