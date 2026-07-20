part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ISubstrateAddress extends ChainAccount<BaseSubstrateAddress, SubstrateToken,
    NFTCore, SubstrateWalletTransaction, WalletSubstrateNetwork> {
  ISubstrateAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required List<int> publicKey,
      required super.address,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required super.id})
      : publicKey = publicKey.asImmutableBytes;

  factory ISubstrateAddress._newAccount({
    required List<int> publicKey,
    required WalletSubstrateNetwork network,
    required BaseSubstrateAddress address,
    required CryptoCoins coin,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required String identifier,
    required String? id,
  }) {
    return ISubstrateAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        identifier: identifier,
        id: id);
  }
  factory ISubstrateAddress.deserialize(
      {required WalletSubstrateNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue cborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.substrateMultisigAccount.isValidTags(cborTag.tags)) {
      return ISubstrateMultiSigAddress.deserialize(
          network: network, id: id, object: cborTag, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: cborTag, identifier: AppSerializationIdentifier.substrateAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final List<int> publicKey = values.rawValueAt(2);
    final BaseSubstrateAddress addr =
        BaseSubstrateAddress.deserializeIAddress(bytes: values.rawValueAt(3));
    final int networkId = values.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(5);
    return ISubstrateAddress._(
        coin: coin,
        publicKey: publicKey,
        address: addr.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: addr,
        network: network,
        identifier: identifier,
        id: id);
  }

  final List<int> publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.substrateAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        publicKey.toCborBytes(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        identifier.toCbor(),
      ];
  SubstrateKeyAlgorithm get keyScheme {
    if (networkAddress is SubstrateEthereumAddress) {
      return SubstrateKeyAlgorithm.ethereum;
    }
    return switch (coin.conf.type) {
      EllipticCurveTypes.sr25519 => SubstrateKeyAlgorithm.sr25519,
      EllipticCurveTypes.ed25519 => SubstrateKeyAlgorithm.ed25519,
      EllipticCurveTypes.secp256k1 => SubstrateKeyAlgorithm.ecdsa,
      _ => throw WalletExceptionConst.invalidAccountData("Unknow substrate key scheme.")
    };
  }

  @override
  List get variables {
    return [derivationIndex, network.value];
  }

  @override
  String? get type => null;

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index => SubstrateNewAddressParams(deriveIndex: index),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }
}

final class ISubstrateMultiSigAddress extends ISubstrateAddress
    with SubstrateChainAccountRepository
    implements MultiSigCryptoAccountAddress {
  factory ISubstrateMultiSigAddress._newAccount({
    required WalletSubstrateNetwork network,
    required CryptoCoins coin,
    required String identifier,
    required BaseSubstrateAddress address,
    required SubstrateMultisigAccountInfo multiSignatureAddress,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return ISubstrateMultiSigAddress._(
        coin: coin,
        address: address.address,
        networkAddress: address,
        multiSignatureAddress: multiSignatureAddress,
        network: network,
        identifier: identifier,
        database: database,
        id: id);
  }

  factory ISubstrateMultiSigAddress.deserialize(
      {required WalletSubstrateNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.substrateMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final SubstrateMultisigAccountInfo multiSignatureAddress =
        SubstrateMultisigAccountInfo.deserialize(
            object: values.objectAt<CborTagValue>(1));
    final SubstrateAddress networkAddress =
        BaseSubstrateAddress.deserializeIAddress(bytes: values.rawValueAt(2)).cast();
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(4);
    return ISubstrateMultiSigAddress._(
        coin: coin,
        address: networkAddress.address,
        multiSignatureAddress: multiSignatureAddress,
        network: network.cast(),
        database: database,
        networkAddress: networkAddress,
        identifier: identifier,
        id: id);
  }
  ISubstrateMultiSigAddress._(
      {required super.coin,
      required super.address,
      required this.multiSignatureAddress,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required super.database,
      required super.id})
      : super._(publicKey: const [], derivationIndex: MultiSigAddressIndex());

  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  final SubstrateMultisigAccountInfo multiSignatureAddress;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.substrateMultisigAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        identifier.toCbor()
      ];

  @override
  List get variables => [multiSignatureAddress];

  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return [];
  }

  @override
  NewAccountParams toAccountParams() {
    return SubstrateMultiSigNewAddressParams(
        coin: coin,
        multiSignatureAddress: multiSignatureAddress,
        address: networkAddress);
  }

  List<BaseSubstrateAddress> signers() {
    if (networkAddress.type.isSubstrate) {
      return multiSignatureAddress.addresses(
          ss58Format: networkAddress.cast<SubstrateAddress>().ss58Format);
    }
    return multiSignatureAddress.addresses();
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByPublicKey;
}

base mixin SubstrateChainAccountRepository on ChainAccount<BaseSubstrateAddress,
    SubstrateToken, NFTCore, SubstrateWalletTransaction, WalletSubstrateNetwork> {
  /// new api
  Future<IResult<List<SubstrateMultisigCall>>> _storageGetAccountMultisigs() async {
    final storagekey = SubstrateNetworkStorageId.multisigTransactions;
    final data = await _storage.queriesNetworkStorage(storage: storagekey);
    return data.andThen((data) {
      return IResult.callSync(() => data.map((e) {
            final data = e.data;
            if (data == null) return null;
            final dec = IResult.callSync(
              () => SubstrateMultisigCall.deserialize(bytes: data),
              onError: (exception, trace) => AppLogData(
                  runtime: runtimeType,
                  function: "_storageGetAccountMultisigs",
                  err: exception,
                  trace: trace.toString()),
            );
            return dec.fold(
                onOk: (e) => e,
                onErr: (err) {
                  _storage.removeNetworkStorageOperation(e.toRemoveOperation());
                  return null;
                });
          }).toList());
    }).map((e) => e.whereType<SubstrateMultisigCall>().toList());
  }

  Future<IResult<void>> _storageSaveAccountMultisig(SubstrateMultisigCall call) async {
    final storagekey = SubstrateNetworkStorageId.multisigTransactions;
    return await _storage.insertNetworkStorage(
        storage: storagekey, keyA: call.callHashHex, value: call);
  }

  Future<IResult<void>> _storageCleanAccountAllMultisigs() async {
    final storagekey = SubstrateNetworkStorageId.multisigTransactions;
    return await _storage.removeNetworkStorage(storage: storagekey);
  }

  Future<IResult<void>> _storageCleanAccountMultisigs(List<String> callHashes) async {
    if (callHashes.isEmpty) return ResultOk(null);
    final storagekey = SubstrateNetworkStorageId.multisigTransactions;
    final results = await Future.wait(callHashes.map((e) => _storage.removeNetworkStorage(
        storage: storagekey, keyA: StringUtils.normalizeHex(e))));
    return results.firstWhere((e) => e.isErr, orElse: () => ResultOk.okVoid);
  }
}
