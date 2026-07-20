part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

enum ZCashNewAddressDerivationMode {
  unified(1),
  sapling(2),
  transparent(3),
  transparentMultisig(4);

  final int value;
  bool get isUnifiedAddress => this == unified;
  const ZCashNewAddressDerivationMode(this.value);
  static ZCashNewAddressDerivationMode fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("ZCashNewAddressDerivationMode"),
    );
  }

  ZcashProtocol get protocol {
    return switch (this) {
      ZCashNewAddressDerivationMode.unified => ZcashProtocol.orchard,
      ZCashNewAddressDerivationMode.sapling => ZcashProtocol.sapling,
      ZCashNewAddressDerivationMode.transparent ||
      ZCashNewAddressDerivationMode.transparentMultisig =>
        ZcashProtocol.transparent,
    };
  }

  bool get isSapling => this == sapling;
}

sealed class ZcashNewAddressParams extends NewDerivableAccountParams<IZcashAddress> {
  final ZCashNewAddressDerivationMode mode;
  const ZcashNewAddressParams({required this.mode});
  List<ZcashAccountCreationParams>? get params;
  factory ZcashNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue decode = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: decode, identifier: NewAccountParamsType.zcashNewAddressParams.tag);
    final mode = ZCashNewAddressDerivationMode.fromValue(values.rawValueAt(0));
    return switch (mode) {
      ZCashNewAddressDerivationMode.unified =>
        ZcashNewAddressParamsUnified._deserialize(object: decode),
      ZCashNewAddressDerivationMode.sapling =>
        ZcashNewAddressParamsSapling._deserialize(object: decode),
      ZCashNewAddressDerivationMode.transparent =>
        ZcashNewAddressParamsTransparent._deserialize(object: decode),
      ZCashNewAddressDerivationMode.transparentMultisig =>
        ZcashNewAddressParamsTransparentMultisignature._deserialize(object: decode),
    };
  }
  @override
  NewAccountParamsType get type => NewAccountParamsType.zcashNewAddressParams;
}

sealed class ZcashShieldAddressParams extends ZcashNewAddressParams {
  ZcashShieldAddressParams({required super.mode, required this.currentHeight});
  final int currentHeight;
  List<DiversifiableFullViewingKey> get fvks;
}

final class ZcashNewAddressParamsUnified extends ZcashShieldAddressParams {
  @override
  DerivableIndex get deriveIndex => throw UnimplementedError();
  @override
  final CryptoCoins coin;

  @override
  final List<ZcashAccountCreationParams>? params;
  final ZcashDerivedAccountInfo? derivedAccount;
  @override
  final List<DiversifiableFullViewingKey> fvks;
  final ZcashNetwork network;
  final List<BigInt> existsIndexes;
  @override
  CryptoProcessLevel get level => CryptoProcessLevel.high;

  ZcashNewAddressParamsUnified._({
    required this.params,
    this.derivedAccount,
    required this.network,
    required this.coin,
    required super.currentHeight,
    List<BigInt> existsIndexes = const [],
    List<DiversifiableFullViewingKey> fvks = const [],
  })  : fvks = fvks.immutable,
        existsIndexes = existsIndexes.immutable,
        super(mode: ZCashNewAddressDerivationMode.unified);
  factory ZcashNewAddressParamsUnified({
    List<ZcashAccountCreationParams>? params,
    required ZcashNetwork network,
    required CryptoCoins coin,
    required int currentHeight,
    ZcashDerivedAccountInfo? derivedAccount,
    List<BigInt> existsIndexes = const [],
    List<DiversifiableFullViewingKey> fvks = const [],
  }) {
    if (params == null && derivedAccount == null) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
    }
    int length = params?.length ?? derivedAccount!.receivers.length;
    Set<ZcashAccountInfoType>? types = params?.map((e) => e.type).toImutableSet;
    types ??= derivedAccount!.receivers.map((e) => e.type).toImutableSet;
    if (types.isEmpty ||
        types.length != length ||
        types.where((e) => e.isTransparent).length > 1 ||
        types.where((e) => e.isShielded).isEmpty) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
    }
    if (derivedAccount != null) {
      final sheildTypes =
          types.where((e) => e.isShielded).map((e) => e.protocol).toList();
      if (sheildTypes.length != fvks.length ||
          fvks.any((e) => !sheildTypes.contains(e.protocol))) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
    }
    return ZcashNewAddressParamsUnified._(
        params: params,
        derivedAccount: derivedAccount,
        network: network,
        fvks: fvks,
        coin: coin,
        existsIndexes: existsIndexes,
        currentHeight: currentHeight);
  }

  factory ZcashNewAddressParamsUnified._deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.zcashNewAddressParams.tag);
    return ZcashNewAddressParamsUnified(
        params: values
            .listAt<CborTagValue>(1)
            .map((e) => ZcashAccountCreationParams.deserialize(object: e))
            .toList()
            .nullOnEmoty,
        derivedAccount: values.maybeObjectAt<ZcashDerivedAccountInfo, CborTagValue>(
            2, (e) => ZcashDerivedAccountInfo.deserialize(object: e)),
        network: ZcashNetwork.fromValue(values.rawValueAt(3)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(4)),
        existsIndexes: values.listAt<CborBigIntValue>(5).map((e) => e.value).toList(),
        fvks: values
            .listAt<CborBytesValue>(6)
            .map((e) => DiversifiableFullViewingKey.fromBytes(e.value))
            .toList(),
        currentHeight: values.rawValueAt(7));
  }

  @override
  IZcashAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    final derivedAccount = this.derivedAccount;

    // throw UnimplementedError();
    if (derivedAccount == null || network is! WalletZcashNetwork) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams.toAccount");
    }
    final defaultIndex =
        derivedAccount.receivers.firstWhereOrNull((e) => e.type.isShielded)?.index ??
            derivedAccount.receivers.firstWhereOrNull((e) => e.type.isTransparent)?.index;
    if (defaultIndex == null || defaultIndex is! DerivableIndex) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams.toAccount");
    }
    return IZcashAddress._newAccount(
        network: network,
        account: derivedAccount,
        coin: coin,
        database: database,
        derivationIndex: defaultIndex,
        identifier: NewAccountParams.toIdentifier(derivedAccount.address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        CborListValue.definite(params?.map((e) => e.toCbor()).toList() ?? <CborObject>[]),
        derivedAccount?.toCbor(),
        network.value.toCbor(),
        coin.identifier.toCbor(),
        CborListValue.definite(existsIndexes.map((e) => CborBigIntValue(e)).toList()),
        AppSerialization.listFromObjects(
            fvks.map((e) => CborBytesValue(e.toBytes())).toList()),
        currentHeight.toCbor()
      ];
}

final class ZcashNewAddressParamsSapling extends ZcashShieldAddressParams {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;

  final ZcashAccountCreationParamsSapling? param;
  final ZcashDerivedAccountInfo? derivedAccount;
  final ZcashNetwork network;
  final List<BigInt> existsIndexes;
  final SaplingDiversifiableFullViewingKey? fvk;

  ZcashNewAddressParamsSapling._({
    required this.param,
    this.derivedAccount,
    required this.network,
    required this.coin,
    required this.deriveIndex,
    required super.currentHeight,
    this.fvk,
    this.existsIndexes = const [],
  }) : super(mode: ZCashNewAddressDerivationMode.sapling);
  factory ZcashNewAddressParamsSapling(
      {ZcashAccountCreationParamsSapling? param,
      required ZcashNetwork network,
      required CryptoCoins coin,
      required int currentHeight,
      List<BigInt> existsIndexes = const [],
      ZcashDerivedAccountInfo? derivedAccount,
      SaplingDiversifiableFullViewingKey? fvk}) {
    DerivableIndex index;
    if (coin.conf.type != EllipticCurveTypes.redJubJub) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
    }
    if (derivedAccount != null) {
      if (fvk == null ||
          !fvk.protocol.isSapling ||
          derivedAccount.receivers.length != 1 ||
          !derivedAccount.receivers[0].type.protocol.isSapling) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
      index = derivedAccount.receivers[0].cast<ZcsahAccountInfoSapling>().index;
    } else {
      if (param == null) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
      index = param.index;
    }
    return ZcashNewAddressParamsSapling._(
        param: param,
        derivedAccount: derivedAccount,
        network: network,
        coin: coin,
        existsIndexes: existsIndexes,
        deriveIndex: index,
        fvk: fvk,
        currentHeight: currentHeight);
  }

  factory ZcashNewAddressParamsSapling._deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.zcashNewAddressParams.tag);
    return ZcashNewAddressParamsSapling(
        param: values.maybeObjectAt<ZcashAccountCreationParamsSapling, CborTagValue>(
            1, (e) => ZcashAccountCreationParamsSapling.deserialize(object: e)),
        derivedAccount: values.maybeObjectAt<ZcashDerivedAccountInfo, CborTagValue>(
            2, (e) => ZcashDerivedAccountInfo.deserialize(object: e)),
        network: ZcashNetwork.fromValue(values.rawValueAt(3)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(4)),
        existsIndexes: values.listAt<CborBigIntValue>(5).map((e) => e.value).toList(),
        fvk: values.maybeRawValueAt<SaplingDiversifiableFullViewingKey, List<int>>(
          6,
          (v) => SaplingDiversifiableFullViewingKey.fromBytes(v),
        ),
        currentHeight: values.rawValueAt(7));
  }

  @override
  IZcashAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    final derivedAccount = this.derivedAccount;
    if (derivedAccount == null || network is! WalletZcashNetwork) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams.toAccount");
    }
    return IZcashAddress._newAccount(
        network: network,
        account: derivedAccount,
        database: database,
        coin: coin,
        derivationIndex: deriveIndex,
        identifier: NewAccountParams.toIdentifier(derivedAccount.address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        param?.toCbor(),
        derivedAccount?.toCbor(),
        network.value.toCbor(),
        coin.identifier.toCbor(),
        CborListValue.definite(existsIndexes.map((e) => CborBigIntValue(e)).toList()),
        AppSerialization.bytesToCbor(fvk?.toBytes()),
        currentHeight.toCbor()
      ];

  @override
  List<DiversifiableFullViewingKey> get fvks {
    final fvk = this.fvk;
    if (fvk == null) return [];
    return [fvk];
  }

  @override
  List<ZcashAccountCreationParams<DerivationIndex>>? get params =>
      switch (param) { ZcashAccountCreationParamsSapling param => [param], _ => null };

  @override
  CryptoProcessLevel get level => CryptoProcessLevel.high;
}

final class ZcashNewAddressParamsTransparent extends ZcashNewAddressParams {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;

  final ZcashAccountCreationParamsTransparent? param;
  final ZcashDerivedAccountInfo? derivedAccount;
  final ZcashNetwork network;

  ZcashNewAddressParamsTransparent._({
    required this.param,
    this.derivedAccount,
    required this.network,
    required this.coin,
    required this.deriveIndex,
  }) : super(mode: ZCashNewAddressDerivationMode.transparent);
  factory ZcashNewAddressParamsTransparent({
    ZcashAccountCreationParamsTransparent? param,
    required ZcashNetwork network,
    required CryptoCoins coin,
    ZcashDerivedAccountInfo? derivedAccount,
  }) {
    DerivableIndex index;
    if (coin is! BipCoins || coin.conf.type != EllipticCurveTypes.secp256k1) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
    }
    if (derivedAccount != null) {
      if (derivedAccount.receivers.length != 1 ||
          !derivedAccount.receivers[0].type.protocol.isTransparent ||
          derivedAccount.receivers[0].type == ZcashAccountInfoType.p2shMsig) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
      final transparent = derivedAccount.receivers[0].cast<ZcashAccountInfoTransparent>();

      index = switch (transparent.index) {
        Bip32DerivationIndex index => index,
        _ => throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams"),
      };
    } else {
      if (param == null) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
      index = param.index.cast();
    }
    return ZcashNewAddressParamsTransparent._(
        param: param,
        derivedAccount: derivedAccount,
        network: network,
        coin: coin,
        deriveIndex: index);
  }

  factory ZcashNewAddressParamsTransparent._deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.zcashNewAddressParams.tag);
    return ZcashNewAddressParamsTransparent(
        param: values.maybeObjectAt<ZcashAccountCreationParamsTransparent, CborTagValue>(
            1, (e) => ZcashAccountCreationParams.deserialize(object: e).cast()),
        derivedAccount: values.maybeObjectAt<ZcashDerivedAccountInfo, CborTagValue>(
            2, (e) => ZcashDerivedAccountInfo.deserialize(object: e)),
        network: ZcashNetwork.fromValue(values.rawValueAt(3)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(4)));
  }

  @override
  IZcashAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    final derivedAccount = this.derivedAccount;
    if (derivedAccount == null || network is! WalletZcashNetwork) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams.toAccount");
    }
    return IZcashAddress._newAccount(
        network: network,
        account: derivedAccount,
        coin: coin,
        derivationIndex: deriveIndex,
        database: database,
        identifier: NewAccountParams.toIdentifier(derivedAccount.address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        param?.toCbor(),
        derivedAccount?.toCbor(),
        network.value.toCbor(),
        coin.identifier.toCbor()
      ];

  @override
  List<ZcashAccountCreationParams<DerivationIndex>>? get params =>
      switch (param) { ZcashAccountCreationParamsSapling param => [param], _ => null };
}

final class ZcashNewAddressParamsTransparentMultisignature extends ZcashNewAddressParams {
  @override
  final CryptoCoins coin;

  final ZcashAccountCreationParamsP2shMultisig? param;
  final ZcashDerivedAccountInfo? derivedAccount;
  final ZcashNetwork network;

  ZcashNewAddressParamsTransparentMultisignature._({
    required this.param,
    this.derivedAccount,
    required this.network,
    required this.coin,
  }) : super(mode: ZCashNewAddressDerivationMode.transparentMultisig);
  factory ZcashNewAddressParamsTransparentMultisignature({
    ZcashAccountCreationParamsP2shMultisig? param,
    required ZcashNetwork network,
    required CryptoCoins coin,
    ZcashDerivedAccountInfo? derivedAccount,
  }) {
    if (coin is! BipCoins || coin.conf.type != EllipticCurveTypes.secp256k1) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
    }
    if (derivedAccount != null) {
      if (derivedAccount.receivers.length != 1 ||
          derivedAccount.receivers[0].type != ZcashAccountInfoType.p2shMsig) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
    } else {
      if (param == null) {
        throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams");
      }
    }
    return ZcashNewAddressParamsTransparentMultisignature._(
      param: param,
      derivedAccount: derivedAccount,
      network: network,
      coin: coin,
    );
  }

  factory ZcashNewAddressParamsTransparentMultisignature._deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.zcashNewAddressParams.tag);
    return ZcashNewAddressParamsTransparentMultisignature(
        param: values.maybeObjectAt<ZcashAccountCreationParamsP2shMultisig, CborTagValue>(
            1, (e) => ZcashAccountCreationParamsP2shMultisig.deserialize(object: e)),
        derivedAccount: values.maybeObjectAt<ZcashDerivedAccountInfo, CborTagValue>(
            2, (e) => ZcashDerivedAccountInfo.deserialize(object: e)),
        network: ZcashNetwork.fromValue(values.rawValueAt(3)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(4)));
  }

  @override
  IZcashAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    final derivedAccount = this.derivedAccount;
    if (derivedAccount == null || network is! WalletZcashNetwork) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams.toAccount");
    }
    final newAddr = IZcashMultisigAddress._newAccount(
        network: network,
        database: database,
        account: derivedAccount,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(derivedAccount.address.address),
        id: id);

    return newAddr;
  }

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        param?.toCbor(),
        derivedAccount?.toCbor(),
        network.value.toCbor(),
        coin.identifier.toCbor()
      ];

  @override
  DerivableIndex get deriveIndex => throw UnimplementedError();

  @override
  List<ZcashAccountCreationParams<DerivationIndex>>? get params =>
      switch (param) { ZcashAccountCreationParamsSapling param => [param], _ => null };
}
