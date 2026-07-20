part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class IZcashAddress extends ChainAccount<ZcashAddress, TokenCore, NFTCore,
    ZcashWalletTransaction, WalletZcashNetwork> with ZcashChainAccountRepository {
  @override
  final ZcashDerivedAccountInfo account;
  IZcashAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required this.account,
      required super.id});

  factory IZcashAddress._newAccount({
    required WalletZcashNetwork network,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required String identifier,
    required CryptoCoins coin,
    required ZcashDerivedAccountInfo account,
    required String? id,
  }) {
    final address = account.address;
    return IZcashAddress._(
        coin: coin,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        identifier: identifier,
        account: account,
        id: id);
  }

  factory IZcashAddress.deserialize(
      {required WalletZcashNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final decode =
        AppSerialization.decode<CborTagValue>(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.zcashMultisigAccount.isValidTags(decode.tags)) {
      return IZcashMultisigAddress.deserialize(
          network: network, id: id, object: decode, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: decode, identifier: AppSerializationIdentifier.zcashAccount);

    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final account =
        ZcashDerivedAccountInfo.deserialize(object: values.objectAt<CborTagValue>(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(4);
    return IZcashAddress._(
        coin: coin,
        address: account.address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: account.address,
        network: network,
        identifier: identifier,
        account: account,
        id: id);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        account.toCbor(),
        network.value.toCbor(),
        identifier.toCbor(),
      ];
  @override
  List get variables {
    return [derivationIndex, network.value, account];
  }

  @override
  String? get type => account.addressType.tr;

  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return account.accountDerivationIndexes(request: request);
  }

  @override
  ReadAccountPublicKeyRequest createViewKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return account.createViewKeyRequest(request: request);
  }

  @override
  ReadAccountPrivateKeyRequest createSecretKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return account.createSecretKeyRequest(request: request);
  }

  @override
  NewAccountParams<IZcashAddress> toAccountParams() {
    final creationParams = account.toCreationParams();
    if (creationParams.isEmpty) {
      throw WalletExceptionConst.invalidAccountData("IZcashAdress toAccountParams");
    }
    final network = account.address.network;
    if (creationParams.length > 1) {
      return ZcashNewAddressParamsUnified(
          network: account.address.network,
          coin: coin,
          params: creationParams,
          currentHeight: 0);
    }
    return switch (creationParams[0]) {
      ZcashAccountCreationParamsSapling sapling => ZcashNewAddressParamsSapling(
          network: network, coin: coin, param: sapling, currentHeight: 0),
      ZcashAccountCreationParamsUnified unified => ZcashNewAddressParamsUnified(
          network: account.address.network,
          coin: coin,
          params: [unified],
          currentHeight: 0),
      ZcashAccountCreationParamsP2pkh transparent => ZcashNewAddressParamsTransparent(
          network: network, coin: coin, param: transparent),
      ZcashAccountCreationParamsP2shStandard transparent =>
        ZcashNewAddressParamsTransparent(
            network: network, coin: coin, param: transparent),
      ZcashAccountCreationParamsP2shMultisig multisig =>
        ZcashNewAddressParamsTransparentMultisignature(
            network: network, coin: coin, param: multisig),
    };
  }

  final OnceRunnerWithData<ZcashTransparentAddressUtxos> _transparentAccountRunner =
      OnceRunnerWithData();

  Future<IResult<ZcashTransparentAddressUtxos>>
      _getTransparentAccountUtxosController() async {
    return _transparentAccountRunner.get(onFetch: _storageGetTransparentUtxos);
  }

  Future<IResult<List<ZcashUtxoTransparent>>> _getAccountTransparetUtxos() async {
    final controller = await _getTransparentAccountUtxosController();
    return controller.map((controller) => controller.utxos);
  }

  Future<IResult<List<ZcashUtxoTransparent>>> _updateAccountTransparentUtxos(
      List<ZcashUtxoTransparent> utxos) async {
    final controller = await _getTransparentAccountUtxosController();
    return controller.andThenAsync((controller) async {
      final cUtxos = controller.utxos;
      final update = controller.updateUtxos(utxos);
      if (!update) return ResultOk([]);
      final result = await _storageSaveAccountTransparentUtxos(controller);
      return result.map((_) {
        List<ZcashUtxoTransparent> newUtxos = [];
        for (final i in utxos) {
          if (!cUtxos.contains(i)) newUtxos.add(i);
        }
        return newUtxos;
      });
    });
  }

  @override
  void _dispose() {
    super._dispose();
    _transparentAccountRunner.dispose();
  }
}

final class IZcashMultisigAddress extends IZcashAddress {
  IZcashMultisigAddress._(
      {required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required super.account,
      required super.database,
      required super.id})
      : super._(derivationIndex: const MultiSigAddressIndex());

  factory IZcashMultisigAddress._newAccount({
    required WalletZcashNetwork network,
    required String identifier,
    required CryptoCoins coin,
    required ZcashDerivedAccountInfo account,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    if (account.receivers.length != 1 ||
        account.receivers[0].type != ZcashAccountInfoType.p2shMsig) {
      throw WalletExceptionConst.invalidAccountData("ZcashNewAddressParams.toAccount");
    }
    final address = account.address;
    return IZcashMultisigAddress._(
        coin: coin,
        address: address.address,
        networkAddress: address,
        network: network,
        database: database,
        identifier: identifier,
        account: account,
        id: id);
  }

  factory IZcashMultisigAddress.deserialize(
      {required WalletZcashNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final account =
        ZcashDerivedAccountInfo.deserialize(object: values.objectAt<CborTagValue>(1));
    final int networkId = values.rawValueAt(2);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(3);
    return IZcashMultisigAddress._(
        coin: coin,
        id: id,
        database: database,
        address: account.address.address,
        networkAddress: account.address,
        network: network.cast(),
        identifier: identifier,
        account: account);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashMultisigAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        account.toCbor(),
        network.value.toCbor(),
        identifier.toCbor(),
      ];
  @override
  List get variables {
    return [derivationIndex, network.value, account];
  }

  @override
  String get type => account.addressType.tr;

  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return account.accountDerivationIndexes(request: request);
  }
}

base mixin ZcashChainAccountRepository on ChainAccount<ZcashAddress, TokenCore, NFTCore,
    ZcashWalletTransaction, WalletZcashNetwork> {
  ZcashDerivedAccountInfo get account;

  Future<IResult<ZcashTransparentAddressUtxos>> _storageGetTransparentUtxos() async {
    if (!account.hasPotocol(ZcashProtocol.transparent)) {
      return ResultOk(ZcashTransparentAddressUtxos());
    }
    final data = await _storage.queryNetworkStorage(
        storage: ZcashNetworkStorageId.transparentUtxos);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (data == null || bytes == null) return ResultOk(ZcashTransparentAddressUtxos());
      final result = IResult.callSync(
        () => ZcashTransparentAddressUtxos.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "resultQueryNetworkStorage_",
            err: exception,
            trace: trace.toString()),
      );
      return result.and((utxos, err) {
        if (err != null) {
          _storage.removeNetworkStorageOperation(data.toRemoveOperation());
        }
        return ResultOk(utxos ?? ZcashTransparentAddressUtxos());
      });
    });
  }

  Future<IResult<void>> _storageSaveAccountTransparentUtxos(
      ZcashTransparentAddressUtxos utxos) async {
    final storageKey = ZcashNetworkStorageId.transparentUtxos;
    return await _storage.insertNetworkStorage(value: utxos, storage: storageKey);
  }
}
