part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ICardanoAddress extends ChainAccount<ADAAddress, TokenCore, NFTCore,
        ADAWalletTransaction, WalletCardanoNetwork>
    with CardanoChainAccountRepository, CardanoChainAccountController {
  final OnceRunnerWithData<ADAAddressUtxos> _accountUtxosRunner = OnceRunnerWithData();

  Future<IResult<ADAAddressUtxos>> _getAccountUtxosController() async {
    return _accountUtxosRunner.get(onFetch: _storageGetAccountUtxos);
  }

  Future<IResult<Set<ADAAddressUtxo>>> _getAccountUtxos() async {
    final result = await _getAccountUtxosController();
    return result.map((e) => e.utxos);
  }

  Future<IResult<void>> _updateAccountUtxox(Iterable<ADAAddressUtxo> utxos) async {
    final controller = await _getAccountUtxosController();
    return controller.andThenAsync((controller) async {
      if (controller.updateUtxos(utxos)) {
        final save = await _storageSaveAccountUtxos(controller);
        return save.andThenAsync((e) => _updateAccountBalance(controller.totalLovelace));
      }
      return await _updateAccountBalance(controller.totalLovelace);
    });
  }

  ICardanoAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required this.addressInfo,
      required super.identifier,
      required super.id,
      this.rewardKeyIndex})
      : rewardAddress = CardanoUtils.extractRewardAddress(networkAddress);

  factory ICardanoAddress._newAccount({
    required ADAAddress address,
    required CryptoCoins coin,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required List<int> publicKey,
    required WalletCardanoNetwork network,
    required DerivationIndex? rewardIndex,
    required String identifier,
    required CardanoAddrDetails addressInfo,
    required String? id,
  }) {
    return ICardanoAddress._(
        coin: coin,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        addressInfo: addressInfo,
        rewardKeyIndex: rewardIndex,
        identifier: identifier,
        id: id);
  }

  factory ICardanoAddress.deserialize(
      {required WalletCardanoNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue cborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.cardanoMultisigAccount.isValidTags(cborTag.tags)) {
      return ICardanoMultiSigAddress.deserialize(
          network: network, id: id, object: cborTag, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.cardanoAccount);

    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final ADAAddress adaAddress =
        ADAAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }

    final CardanoAddrDetails addrDetails =
        CardanoAddrDetails.deserialize(object: values.objectAt<CborTagValue>(4));
    Bip32DerivationIndex? rewardIndex =
        values.maybeObjectAt<Bip32DerivationIndex, CborTagValue>(
            5, (e) => Bip32DerivationIndex.deserialize(object: e));
    if (adaAddress.addressType == ADAAddressType.base && rewardIndex == null) {
      throw WalletExceptionConst.invalidAccountData("ICardanoAddress.deserialize");
    }
    final String identifier = values.rawValueAt(6);
    return ICardanoAddress._(
        coin: coin,
        address: adaAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: adaAddress,
        network: network,
        addressInfo: addrDetails,
        rewardKeyIndex: rewardIndex,
        identifier: identifier,
        id: id);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cardanoAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        addressInfo.toCbor(),
        rewardKeyIndex?.toCbor(),
        identifier.toCbor()
      ];

  @override
  List get variables {
    return [derivationIndex, network.value, networkAddress.addressType, addressInfo];
  }

  final BaseCardanoAddressDetails addressInfo;

  final ADARewardAddress? rewardAddress;

  final DerivationIndex? rewardKeyIndex;

  bool get isBaseAddress => addressInfo.addressType == ADAAddressType.base;
  bool get isRewardAddress => addressInfo.addressType == ADAAddressType.reward;
  @override
  String? get type => addressInfo.addressType.name;

  List<DerivationIndex> get keyIndexes =>
      [derivationIndex, if (rewardKeyIndex != null) rewardKeyIndex!];

  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    switch ((derivationIndex, rewardKeyIndex)) {
      case (DerivableIndex index, DerivableIndex? rewardIndex):
        return [index, if (rewardIndex != null) rewardIndex];
      default:
        throw AppCryptoExceptionConst.invalidDerivationKey;
    }
  }

  @override
  NewAccountParams toAccountParams() {
    if (addressInfo case CardanoAddrDetails addressInfo) {
      if (derivationIndex is DerivableIndex) {
        return CardanoNewAddressParams(
            addressType: addressInfo.addressType,
            deriveIndex: derivationIndex.cast(),
            rewardKeyIndex: rewardKeyIndex?.cast(),
            addressDetails: addressInfo,
            customHdPath: addressInfo.hdPath,
            customHdPathKey: addressInfo.hdPathKey,
            coin: coin);
      }
    }
    throw AppCryptoExceptionConst.invalidDerivationKey;
  }

  List<int>? get publicKey => addressInfo.publicKey;

  List<int>? get rewardPublicKey {
    if (isRewardAddress) return publicKey;
    if (isBaseAddress) return addressInfo.stakePubkey;
    return null;
  }

  @override
  void _dispose() {
    super._dispose();
    _accountUtxosRunner.dispose();
  }
}

final class ICardanoMultiSigAddress extends ICardanoAddress
    implements MultiSigCryptoAccountAddress {
  @override
  CardanoMultisigNewAddressParams toAccountParams() {
    return CardanoMultisigNewAddressParams(addressInfo: addressInfo, coin: coin);
  }

  factory ICardanoMultiSigAddress._newAccount({
    required ADAAddress address,
    required CryptoCoins coin,
    required WalletCardanoNetwork network,
    required String identifier,
    required CardanoMultiSignatureAddressDetails addressInfo,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return ICardanoMultiSigAddress._(
        coin: coin,
        address: address.address,
        networkAddress: address,
        network: network,
        database: database,
        identifier: identifier,
        addressInfo: addressInfo,
        id: id);
  }

  factory ICardanoMultiSigAddress.deserialize(
      {required WalletCardanoNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.cardanoMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final ADAAddress adaAddress =
        ADAAddress.deserializeIAddress(bytes: values.rawValueAt(1));
    final int networkId = values.rawValueAt(2);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }

    final CardanoMultiSignatureAddressDetails addrDetails =
        CardanoMultiSignatureAddressDetails.deserialize(
            object: values.objectAt<CborTagValue>(3));
    final String identifier = values.rawValueAt(4);
    return ICardanoMultiSigAddress._(
        coin: coin,
        address: adaAddress.address,
        networkAddress: adaAddress,
        network: network,
        addressInfo: addrDetails,
        database: database,
        identifier: identifier,
        id: id);
  }
  ICardanoMultiSigAddress._({
    required super.coin,
    required super.address,
    required super.network,
    required super.addressInfo,
    required super.identifier,
    required super.networkAddress,
    required super.id,
    required super.database,
  }) : super._(
            derivationIndex: MultiSigAddressIndex(),
            rewardKeyIndex: networkAddress.addressType == ADAAddressType.base
                ? MultiSigAddressIndex()
                : null);
  @override
  CardanoMultiSignatureAddressDetails get addressInfo =>
      super.addressInfo as CardanoMultiSignatureAddressDetails;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cardanoMultisigAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        addressInfo.toCbor(),
        identifier.toCbor()
      ];
  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    switch (request) {
      case null:
      case AccountDerivationIndexRequestSigners():
        return addressInfo.keyIndexes;
      case AccountDerivationIndexRequestAddress():
        return [];
      default:
        throw AppInternalError.internalError("Invalid request");
    }
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByPublicKey;
}

base mixin CardanoChainAccountController
    on
        ChainAccount<ADAAddress, TokenCore, NFTCore, ADAWalletTransaction,
            WalletCardanoNetwork>,
        CardanoChainAccountRepository {}
base mixin CardanoChainAccountRepository on ChainAccount<ADAAddress, TokenCore, NFTCore,
    ADAWalletTransaction, WalletCardanoNetwork> {
  Future<IResult<void>> _storageSaveAccountUtxos(ADAAddressUtxos utxos) async {
    final storagekey = ADANetworkStorageId.utxos;
    return await _storage.insertNetworkStorage(storage: storagekey, value: utxos);
  }

  Future<IResult<ADAAddressUtxos>> _storageGetAccountUtxos() async {
    final storagekey = ADANetworkStorageId.utxos;
    final data = await _storage.queryNetworkStorage(storage: storagekey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(ADAAddressUtxos());
      final result = IResult.callSync(
        () => ADAAddressUtxos.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "_storageGetAccountUtxos",
            err: exception,
            trace: trace.toString()),
      );
      return result.and((utxos, _) => ResultOk(utxos ?? ADAAddressUtxos()));
    });
  }
}
