part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class IBitcoinAddress extends ChainAccount<BitcoinNetworkAddress, TokenCore,
        NFTCore, BitcoinWalletTransaction, WalletBitcoinNetwork>
    with BitcoinChainAccountRepository, BitcoinChainAccountController {
  factory IBitcoinAddress._newAccount({
    required List<int> publicKey,
    required WalletBitcoinNetwork network,
    required BitcoinNetworkAddress address,
    required CryptoCoins coin,
    required BitcoinAddressType addressType,
    required PubKeyModes pubKeyMode,
    required String identifier,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required String? id,
  }) {
    return IBitcoinAddress(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        keyType: pubKeyMode,
        identifier: identifier,
        id: id);
  }

  factory IBitcoinAddress.deserialize(
      {required WalletBitcoinNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue toCborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.bitcoinMultiSigAccount.isValidTags(toCborTag.tags)) {
      return IBitcoinMultiSigAddress.deserialize(
          network: network, id: id, object: toCborTag, database: database);
    }
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborObject: toCborTag, identifier: AppSerializationIdentifier.bitcoinAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(cbor.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(1));
    final List<int> publicKey = cbor.rawValueAt(2);
    final BitcoinNetworkAddress address =
        BitcoinNetworkAddress.deserializeIAddress(bytes: cbor.rawValueAt(3));
    final networkId = cbor.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final keyType =
        PubKeyModes.fromValue(cbor.rawValueAt(5), defaultValue: PubKeyModes.compressed);
    final String identifier = cbor.rawValueAt(6);
    return IBitcoinAddress(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        keyType: keyType,
        identifier: identifier,
        id: id);
  }
  // final BitcoinAddressUtxo _addressUtxos = BitcoinAddressUtxo();
  // final OnceRunner<BitcoinAddressUtxo> _utxosRunner = OnceRunner();

  // Future<BitcoinAddressUtxo> _getAddressUtxos() async {
  //   return _utxosRunner.get(onFetch: _getUtxosStorage, onFetched: () => _addressUtxos);
  // }

  // Future<void> _updateUtxos(Iterable<BitcoinUtxoWithStatus> utxos) async {
  //   if (_addressUtxos.updateUtxos(utxos)) {
  //     await _saveAddressUtxo(_addressUtxos);
  //   }
  //   await _updateAddressBalance(_addressUtxos.totalBalance);
  // }

  ///
  final OnceRunnerWithData<BitcoinAddressUtxo> _accountUtxosRunner = OnceRunnerWithData();

  Future<IResult<BitcoinAddressUtxo>> _getAccountUtxosController() async {
    return _accountUtxosRunner.get(onFetch: _storageGetAccountUtxos);
  }

  Future<IResult<Set<BitcoinUtxoWithSpendingInfo>>> _getAccountUtxos() async {
    final result = await _getAccountUtxosController();
    return result.map((e) => e.utxos);
  }

  Future<IResult<void>> _updateAccountUtxo(
      Iterable<BitcoinUtxoWithSpendingInfo> utxos) async {
    final controller = await _getAccountUtxosController();
    return controller.andThenAsync((controller) async {
      if (controller.updateUtxos(utxos)) {
        final save = await _storageSaveAccountUtxos(controller);
        return save.andThenAsync((e) => _updateAccountBalance(controller.totalBalance));
      }
      return await _updateAccountBalance(controller.totalBalance);
    });
  }

  IBitcoinAddress(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required List<int> publicKey,
      required super.networkAddress,
      required super.address,
      required super.network,
      required this.keyType,
      required super.identifier,
      required super.id})
      : publicKey = publicKey.asImmutableBytes;

  final List<int> publicKey;
  final PubKeyModes keyType;
  BitcoinAddressType get addrType => networkAddress.type;

  late final UtxoAddressDetails toUtxoRequest = UtxoAddressDetails(
      publicKey: BytesUtils.toHexString(publicKey), address: networkAddress.baseAddress);

  @override
  List get variables => [derivationIndex, network];

  List<String> get signers => [BytesUtils.toHexString(publicKey)];

  @override
  String get type => addrType.name;

  Script? witnessScript() {
    switch (addrType) {
      case SegwitAddressType.p2wsh:
      case P2shAddressType.p2wshInP2sh:
        final publicKey = ECPublic.fromBytes(this.publicKey);
        return publicKey.toP2wshScript();
      default:
        return null;
    }
  }

  List<int>? xOnly() {
    if (addrType.isP2tr) {
      final publicKey = ECPublic.fromBytes(this.publicKey);
      return publicKey.toXOnly();
    }
    return null;
  }

  Script? tapScript() {
    return null;
  }

  Script? redeemScript() {
    if (!addrType.isP2sh) return null;
    final publicKey = ECPublic.fromBytes(this.publicKey);
    switch (addrType) {
      case P2shAddressType.p2wshInP2sh:
        return publicKey.toP2wshAddress().toScriptPubKey();
      case P2shAddressType.p2wpkhInP2sh:
        return publicKey.toSegwitAddress().toScriptPubKey();
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkInP2sh32:
      case P2shAddressType.p2pkInP2shwt:
      case P2shAddressType.p2pkInP2sh32wt:
        return publicKey.toRedeemScript(mode: keyType);
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return publicKey.toAddress(mode: keyType).toScriptPubKey();
      default:
        return null;
    }
  }

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      Bip32DerivationIndex index => BitcoinNewAddressParams(
          deriveIndex: index, bitcoinAddressType: addrType, coin: coin, keyType: keyType),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        publicKey.toCborBytes(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        keyType.value.toCbor(),
        identifier.toCbor()
      ];
}

final class IBitcoinMultiSigAddress extends IBitcoinAddress
    with BitcoinMultiSigBase
    implements MultiSigCryptoAccountAddress {
  factory IBitcoinMultiSigAddress._newAccount({
    required WalletBitcoinNetwork network,
    required BitcoinNetworkAddress address,
    required CryptoCoins coin,
    required BitcoinMultiSignatureAddress multiSignatureAddress,
    required String identifier,
    required BitcoinAddressType addressType,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return IBitcoinMultiSigAddress._(
        coin: coin,
        address: address.address,
        multiSignatureAddress: multiSignatureAddress,
        bitcoinAddress: address,
        network: network,
        derivationIndex: MultiSigAddressIndex(),
        identifier: identifier,
        database: database,
        id: id);
  }

  factory IBitcoinMultiSigAddress.deserialize(
      {required WalletBitcoinNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.bitcoinMultiSigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(cbor.rawValueAt(0));
    final BitcoinMultiSignatureAddress multiSignatureAddress =
        BitcoinMultiSignatureAddress.deserialize(object: cbor.objectAt<CborTagValue>(1));
    final BitcoinNetworkAddress address =
        BitcoinNetworkAddress.deserializeIAddress(bytes: cbor.rawValueAt(2));
    final int networkId = cbor.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final derivationIndex =
        DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(4));
    final String identifier = cbor.rawValueAt(5);

    return IBitcoinMultiSigAddress._(
        coin: coin,
        address: address.address,
        bitcoinAddress: address,
        multiSignatureAddress: multiSignatureAddress,
        network: network.cast(),
        derivationIndex: derivationIndex,
        database: database,
        id: id,
        identifier: identifier);
  }
  IBitcoinMultiSigAddress._({
    required super.coin,
    required BitcoinNetworkAddress bitcoinAddress,
    required super.address,
    required this.multiSignatureAddress,
    required super.network,
    required super.derivationIndex,
    required super.database,
    required super.identifier,
    required super.id,
  }) : super(
            publicKey: const [],
            networkAddress: bitcoinAddress,
            keyType: PubKeyModes.uncompressed);

  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;
  @override
  PubKeyModes get keyType =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;
  @override
  final BitcoinMultiSignatureAddress multiSignatureAddress;

  late final UtxoAddressDetails _toUtxoRequest = UtxoAddressDetails.multiSigAddress(
      multiSigAddress: multiSignatureAddress, address: networkAddress.baseAddress);
  @override
  UtxoAddressDetails get toUtxoRequest => _toUtxoRequest;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinMultiSigAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        derivationIndex.toCbor(),
        identifier.toCbor(),
      ];
  @override
  List get variables =>
      [addrType, derivationIndex, network, multiSignatureAddress.multiSigScript.toHex()];

  @override
  List<String> get signers =>
      multiSignatureAddress.signers.map((e) => e.publicKey).toList();

  @override
  List<DerivableIndex> derivableIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    switch (request) {
      case null:
      case AccountDerivationIndexRequestSigners():
        return multiSignatureAddress.signers.map((e) => e.derivationIndex).toList();
      case AccountDerivationIndexRequestAddress():
        return [];
      default:
        throw AppInternalError.internalError("Invalid request");
    }
  }

  @override
  BitcoinMultiSigNewAddressParams toAccountParams() {
    return BitcoinMultiSigNewAddressParams(
        multiSignatureAddress: multiSignatureAddress,
        bitcoinAddressType: addrType,
        coin: coin);
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByPublicKey;

  @override
  Script? witnessScript() {
    switch (addrType) {
      case SegwitAddressType.p2wsh:
      case P2shAddressType.p2wshInP2sh:
        return multiSignatureAddress.multiSigScript;
      default:
        return null;
    }
  }

  @override
  Script? redeemScript() {
    if (!addrType.isP2sh) return null;
    switch (addrType) {
      case P2shAddressType.p2wshInP2sh:
        return P2wshAddress.fromScript(script: multiSignatureAddress.multiSigScript)
            .toScriptPubKey();
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkInP2sh32:
      case P2shAddressType.p2pkInP2shwt:
      case P2shAddressType.p2pkInP2sh32wt:
        return multiSignatureAddress.multiSigScript;
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return multiSignatureAddress.multiSigScript;
      default:
        return null;
    }
  }

  @override
  void _dispose() {
    super._dispose();
    _accountUtxosRunner.dispose();
  }
}

base mixin BitcoinChainAccountController
    on
        ChainAccount<BitcoinNetworkAddress, TokenCore, NFTCore, BitcoinWalletTransaction,
            WalletBitcoinNetwork>,
        BitcoinChainAccountRepository {}
base mixin BitcoinChainAccountRepository on ChainAccount<BitcoinNetworkAddress, TokenCore,
    NFTCore, BitcoinWalletTransaction, WalletBitcoinNetwork> {
  Future<IResult<void>> _storageSaveAccountUtxos(BitcoinAddressUtxo utxos) async {
    final storagekey = BitcoinNetworkStorageId.utxos;
    return await _storage.insertNetworkStorage(storage: storagekey, value: utxos);
  }

  Future<IResult<BitcoinAddressUtxo>> _storageGetAccountUtxos() async {
    final storagekey = BitcoinNetworkStorageId.utxos;
    final data = await _storage.queryNetworkStorage(storage: storagekey);
    return data.andThen((final data) {
      final bytes = data?.data;
      if (bytes == null) return ResultOk(BitcoinAddressUtxo());
      final result = IResult.callSync(
        () => BitcoinAddressUtxo.deserialize(bytes: bytes),
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "_storageGetAccountUtxos",
            err: exception,
            trace: trace.toString()),
      );
      return result.and((utxos, _) => ResultOk(utxos ?? BitcoinAddressUtxo()));
    });
  }
}
