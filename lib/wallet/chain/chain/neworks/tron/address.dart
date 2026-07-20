part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ITronAddress extends ChainAccount<TronAddress, TronToken, NFTCore,
    TronWalletTransaction, WalletTronNetwork> with TronChainAccountRepository {
  ITronAddress._(
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

  factory ITronAddress._newAccount({
    required List<int> publicKey,
    required WalletTronNetwork network,
    required TronAddress address,
    required String identifier,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required CryptoCoins coin,
    required String? id,
  }) {
    return ITronAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.toAddress(),
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        identifier: identifier,
        id: id);
  }

  factory ITronAddress.deserialize(
      {required WalletTronNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue toCborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.tronMultisigAccount.isValidTags(toCborTag.tags)) {
      return ITronMultisigAddress.deserialize(
          network: network, id: id, object: toCborTag, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: toCborTag, identifier: AppSerializationIdentifier.tronAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final List<int> publicKey = values.rawValueAt(2);

    final TronAddress tronAddress =
        TronAddress.deserializeIAddress(bytes: values.rawValueAt(3));
    final int networkId = values.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(5);

    return ITronAddress._(
        coin: coin,
        publicKey: publicKey,
        address: tronAddress.toAddress(),
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: tronAddress,
        network: network,
        identifier: identifier,
        id: id);
  }
  final List<int> publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(publicKey),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        identifier.toCbor(),
      ];
  @override
  List get variables {
    return [derivationIndex, network.value];
  }

  @override
  String? get type => null;

  // TronAccountResourceInfo? _accountResources;
  // TronAccountInfo? _accountInfo;
  // final OnceRunner<void> _tronAccountRunner = OnceRunner();
  // Future<void> _getAccountInfo() async {
  //   await _tronAccountRunner.get(
  //       onFetch: () async {
  //         _accountInfo = await _getTronAccountInfoStorage();
  //         _accountResources = await _getTronAccountResourceStorage();
  //       },
  //       onFetched: () {});
  // }

  // Future<TronAccountInfo?> getAccountInfo() async {
  //   await _getAccountInfo();
  //   return _accountInfo;
  // }

  // Future<TronAccountResourceInfo?> getAccountResource() async {
  //   await _getAccountInfo();
  //   return _accountResources;
  // }

  // Future<void> _updateAccountResource(TronAccountResourceInfo? accResource) async {
  //   await _getAccountInfo();
  //   if (accResource != _accountResources) {
  //     _accountResources = accResource;
  //     await _saveTronAccountResource(_accountResources);
  //   }
  // }

  // Future<void> _updateTronAccount(TronAccountInfo? tronAcc) async {
  //   await _getAccountInfo();
  //   if (tronAcc != _accountInfo) {
  //     await _setTronAccount(tronAcc);
  //     await _saveTronAccountInfo(tronAcc);
  //   }
  // }

  // Future<void> _setTronAccount(TronAccountInfo? tronAcc) async {
  //   _accountInfo = tronAcc;
  //   _updateAddressBalance(_accountInfo?.balance ?? BigInt.zero);
  //   if (tronAcc != null) {
  //     final tokens = await getTokens();
  //     final trc10Tokens = tokens.where((e) => e.tronTokenType.isTrc10);
  //     for (final i in trc10Tokens) {
  //       final balance = tronAcc.assetV2.firstWhereNullable((e) => i.issuer == e.key);
  //       _updateTokenBalance(i, () => i._updateBalance(balance?.value ?? BigInt.zero));
  //     }
  //   }
  // }

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index => TronNewAddressParams(deriveIndex: index, coin: coin),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }

  /// newApi
  // TronAccountResourceInfo? _accountResources;
  // TronAccountInfo? _accountInfo;
  final OnceRunnerWithData<TronAccountInfo?> _tronAccountInfoRunner =
      OnceRunnerWithData();

  final OnceRunnerWithData<TronAccountResourceInfo?> _tronAccountResourceRunner =
      OnceRunnerWithData();
  Future<IResult<TronAccountInfo?>> getAccountInfo_() async {
    return _tronAccountInfoRunner.get(onFetch: () async {
      final account = await _storageGetAccountInfoStorage();
      return account.mapAsync((e) async {
        await _updateAccountBalance(e?.balance ?? BigInt.zero);
        return e;
      });
    });
  }

  Future<IResult<TronAccountResourceInfo?>> getAccountResource_() async {
    return _tronAccountResourceRunner.get(onFetch: _storageGetAccountResource);
  }

  Future<IResult<bool>> _updateAccountInfo(TronAccountInfo? tronAcc) async {
    final accountInfo = await getAccountInfo_();
    return accountInfo.andThenAsync((e) async {
      if (e == tronAcc) return ResultOk(false);
      final result = await _storageSaveTronAccountInfo(tronAcc);
      return result.andThenAsync((e) async {
        _tronAccountInfoRunner.setOk(tronAcc);
        final result = await _updateAccountBalance(tronAcc?.balance ?? BigInt.zero);
        return result.andThenAsync((e) async {
          if (tronAcc == null) return result;
          final tokens = await getAccountTokens();
          return tokens.andThenAsync((tokens) async {
            final trc10Tokens = tokens.where((e) => e.tronTokenType.isTrc10);
            for (final i in trc10Tokens) {
              final balance =
                  tronAcc.assetV2.firstWhereNullable((e) => i.issuer == e.key);
              final result = await _updateAccountTokenBalance(
                  i, () => i._updateBalance(balance?.value ?? BigInt.zero));
              if (result.isErr) return result;
              e |= result.unwrap();
            }
            return ResultOk(e);
          });
        });
      });
    });
    // if (accountInfo.isOk && accountInfo.ok() == tronAcc) {
    //   return ResultOk(null);
    // }

    // await _getAccountInfo();
    // if (tronAcc != _accountInfo) {
    //   await _setTronAccount(tronAcc);
    //   await _saveTronAccountInfo(tronAcc);
    // }
  }

  Future<IResult<bool>> _updateAccountResource_(TronAccountResourceInfo? resource) async {
    final accountInfo = await getAccountResource_();
    return accountInfo.andThenAsync((e) async {
      if (resource == e) return ResultOk(false);
      _tronAccountResourceRunner.setOk(resource);
      final result = await _storageSaveAccountResource(resource);
      return result.map((_) => false);
    });
  }

  @override
  void _dispose() {
    super._dispose();
    _tronAccountInfoRunner.dispose();
    _tronAccountResourceRunner.dispose();
  }
}

final class ITronMultisigAddress extends ITronAddress
    implements MultiSigCryptoAccountAddress {
  ITronMultisigAddress._(
      {required super.address,
      required super.network,
      required super.coin,
      required super.networkAddress,
      required super.identifier,
      required this.multiSignatureAccount,
      required super.database,
      required super.id})
      : super._(derivationIndex: MultiSigAddressIndex(), publicKey: const []);

  factory ITronMultisigAddress._newAccount({
    required CryptoCoins coin,
    required TronAddress address,
    required TronMultiSignatureAddress multiSigAccount,
    required WalletTronNetwork network,
    required String identifier,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return ITronMultisigAddress._(
        coin: coin,
        multiSignatureAccount: multiSigAccount,
        address: address.toAddress(),
        networkAddress: address,
        network: network,
        identifier: identifier,
        database: database,
        id: id);
  }

  factory ITronMultisigAddress.deserialize(
      {required WalletTronNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tronMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final TronMultiSignatureAddress multiSignatureAddress =
        TronMultiSignatureAddress.deserialize(object: values.objectAt<CborTagValue>(1));
    final TronAddress tronAddr =
        TronAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }

    final String identifier = values.rawValueAt(4);
    return ITronMultisigAddress._(
        coin: coin,
        multiSignatureAccount: multiSignatureAddress,
        address: tronAddr.toAddress(),
        networkAddress: tronAddr,
        network: network,
        identifier: identifier,
        database: database,
        id: id);
  }
  final TronMultiSignatureAddress multiSignatureAccount;
  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  @override
  List get variables {
    return [derivationIndex, network.value, multiSignatureAccount];
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronMultisigAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAccount.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        identifier.toCbor()
      ];
  @override
  bool get multiSigAccount => true;

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
  NewAccountParams toAccountParams() {
    return TronMultisigNewAddressParams(
        coin: coin,
        masterAddress: networkAddress,
        multiSigAccount: multiSignatureAccount);
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByAddress;
}

base mixin TronChainAccountRepository on ChainAccount<TronAddress, TronToken, NFTCore,
    TronWalletTransaction, WalletTronNetwork> {
  /// new api
  Future<IResult<TronAccountInfo?>> _storageGetAccountInfoStorage() async {
    final storagekey = TronNetworkStorageId.accountInfo;
    final data = await _storage.queryNetworkStorage(storage: storagekey);

    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(null);
      final result = IResult.callSync(
        () => TronAccountInfo.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "_storageGetAccountInfoStorage",
            err: exception,
            trace: trace.toString()),
      );
      return result.unwrapOrNull();
    });
  }

  Future<IResult<void>> _storageSaveTronAccountInfo(TronAccountInfo? accountInfo) async {
    final storageKey = TronNetworkStorageId.accountInfo;
    if (accountInfo == null) {
      return await _storage.removeNetworkStorage(storage: storageKey);
    }
    return await _storage.insertNetworkStorage(storage: storageKey, value: accountInfo);
  }

  Future<IResult<TronAccountResourceInfo?>> _storageGetAccountResource() async {
    final storagekey = TronNetworkStorageId.accountResource;
    final data = await _storage.queryNetworkStorage(storage: storagekey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(null);
      final result = IResult.callSync(
        () => TronAccountResourceInfo.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "_storageGetAccountResource",
            err: exception,
            trace: trace.toString()),
      );
      return result.unwrapOrNull();
    });
  }

  Future<IResult<void>> _storageSaveAccountResource(
      TronAccountResourceInfo? accountResource) async {
    final storagekey = TronNetworkStorageId.accountResource;
    if (accountResource == null) {
      return await _storage.removeNetworkStorage(storage: storagekey);
    }
    return await _storage.insertNetworkStorage(
        storage: storagekey, value: accountResource);
  }
}
