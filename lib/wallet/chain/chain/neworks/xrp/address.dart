part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

enum XrpAddressType {
  xAddress("x_address"),
  classic("classic_address");

  final String value;
  const XrpAddressType(this.value);
}

final class IXRPAddress extends ChainAccount<XRPBaseAddress, RippleIssueToken,
    RippleNFToken, XRPWalletTransaction, WalletXRPNetwork> {
  final XrpAddressType addressType;
  final int? tag;

  IXRPAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required List<int> publicKey,
      required super.address,
      required super.network,
      required super.networkAddress,
      required this.tag,
      required super.identifier,
      required super.id,
      int? lastUpdateLedgerIndex})
      : publicKey = publicKey.asImmutableBytes,
        addressType = tag == null ? XrpAddressType.classic : XrpAddressType.xAddress;
  factory IXRPAddress._newAccount({
    required CryptoCoins coin,
    required int? tag,
    required XRPBaseAddress address,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required List<int> publicKey,
    required WalletXRPNetwork network,
    required String identifier,
    required String? id,
  }) {
    return IXRPAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        tag: tag,
        identifier: identifier,
        id: id);
  }
  factory IXRPAddress.deserialize(
      {required WalletXRPNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue cborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.rippleMultisigAccount.isValidTags(cborTag.tags)) {
      return IXRPMultisigAddress.deserialize(
          network: network, id: id, object: cborTag, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: cborTag, identifier: AppSerializationIdentifier.rippleAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final List<int> publicKey = values.rawValueAt(2);

    ///TODO
    final XRPBaseAddress rippleAddress =
        XRPBaseAddress.deserializeIAddress(bytes: values.rawValueAt(3));
    final int? tag = values.rawValueAt(4);
    final int networkId = values.rawValueAt(5);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(6);
    final int? lastUpdateLedgerIndex = values.rawValueAt(7);
    return IXRPAddress._(
        coin: coin,
        publicKey: publicKey,
        address: rippleAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: rippleAddress,
        network: network,
        tag: tag,
        identifier: identifier,
        lastUpdateLedgerIndex: lastUpdateLedgerIndex,
        id: id);
  }

  XRPPublicKey toXRPPublicKey() {
    switch (derivationIndex) {
      case DerivableIndex index:
        final algorithm = XRPKeyAlgorithm.values
            .firstWhere((element) => element.curveType == index.currencyCoin.conf.type);
        return XRPPublicKey.fromBytes(publicKey, algorithm: algorithm);
      default:
        throw WalletExceptionConst.featureUnavailableForMultiSignature;
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.rippleAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(publicKey),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        tag?.toCbor(),
        network.value.toCbor(),
        identifier.toCbor()
      ];
  @override
  List get variables {
    return [tag, derivationIndex, network.value];
  }

  EllipticCurveTypes get curveType => coin.conf.type;

  @override
  String get type => addressType.value;

  @override
  String get baseAddress => networkAddress.classicAddress;
  final List<int> publicKey;

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index =>
        RippleNewAddressParams(deriveIndex: index, coin: coin, tag: tag),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }

  Future<IResult<void>> _storageSaveAccountLedgeIndex(int ledgerIndex) async {
    final storagekey = XRPNetworkStorageId.addressLedgerIndex;
    return await _storage.insertNetworkStorageRaw(
        storage: storagekey, value: LayoutConst.lebU32().serialize(ledgerIndex));
  }

  Future<IResult<int?>> _stoageGetAccountLedgerIndex() async {
    final storagekey = XRPNetworkStorageId.addressLedgerIndex;
    final data = await _storage.queryNetworkStorage(storage: storagekey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(null);
      final result = IResult.callSync(
        () => LayoutConst.lebU32().deserialize(bytes).value,
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "_stoageGetAccountLedgerIndex",
            err: exception,
            trace: trace.toString()),
      );
      return result.unwrapOrNull();
    });
  }

  List<int>? toXrplPublicKeyBytes() {
    switch (derivationIndex) {
      case DerivableIndex index:
        final algorithm = XRPKeyAlgorithm.values
            .firstWhere((element) => element.curveType == index.currencyCoin.conf.type);
        return RippleUtils.toXrplPublicKeyBytes(publicKey, algorithm);
      default:
        return [];
    }
  }
}

final class IXRPMultisigAddress extends IXRPAddress
    implements MultiSigCryptoAccountAddress {
  IXRPMultisigAddress._(
      {required super.address,
      required super.network,
      required super.coin,
      required super.networkAddress,
      required super.tag,
      required this.multiSignatureAccount,
      required super.identifier,
      required super.database,
      required super.id})
      : super._(derivationIndex: MultiSigAddressIndex(), publicKey: const []);
  @override
  RippleMultiSigNewAddressParams toAccountParams() {
    return RippleMultiSigNewAddressParams(
        coin: coin,
        masterAddress: networkAddress,
        multiSigAccount: multiSignatureAccount);
  }

  factory IXRPMultisigAddress._newAccount({
    required WalletXRPNetwork network,
    required CryptoCoins coin,
    required int? tag,
    required XRPBaseAddress address,
    required RippleMultiSignatureAddress multiSigAccount,
    required String identifier,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return IXRPMultisigAddress._(
        coin: coin,
        multiSignatureAccount: multiSigAccount,
        address: address.address,
        networkAddress: address,
        network: network,
        database: database,
        tag: tag,
        identifier: identifier,
        id: id);
  }
  factory IXRPMultisigAddress.deserialize(
      {required WalletXRPNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.rippleMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final int? tag = values.rawValueAt(2);
    final int networkId = values.rawValueAt(3);
    final XRPBaseAddress rippleAddress =
        XRPBaseAddress.deserializeIAddress(bytes: values.rawValueAt(1));
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final RippleMultiSignatureAddress multiSigAccount =
        RippleMultiSignatureAddress.deserialize(object: values.objectAt<CborTagValue>(4));
    final String identifier = values.rawValueAt(5);
    return IXRPMultisigAddress._(
        coin: coin,
        address: rippleAddress.address,
        networkAddress: rippleAddress,
        network: network,
        database: database,
        tag: tag,
        multiSignatureAccount: multiSigAccount,
        identifier: identifier,
        id: id);
  }

  final RippleMultiSignatureAddress multiSignatureAccount;

  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;
  @override
  EllipticCurveTypes get curveType =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  @override
  List get variables {
    return [tag, derivationIndex, network.value, multiSignatureAccount];
  }

  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    switch (request) {
      case null:
      case AccountDerivationIndexRequestSigners():
        return multiSignatureAccount.signers.map((e) => e.derivationIndex).toList();
      case AccountDerivationIndexRequestAddress():
        return [];
      default:
        throw AppInternalError.internalError("Invalid request");
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.rippleMultisigAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        tag?.toCbor(),
        network.value.toCbor(),
        multiSignatureAccount.toCbor(),
        identifier.toCbor()
      ];
  @override
  IAdressType get iAddressType => IAdressType.multisigByAddress;
}
