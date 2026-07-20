part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class IBitcoinCashAddress extends IBitcoinAddress {
  IBitcoinCashAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.publicKey,
      required BitcoinCashAddress super.networkAddress,
      required super.address,
      required super.network,
      required super.keyType,
      required super.identifier,
      required super.id})
      : super();

  factory IBitcoinCashAddress._newAccount({
    required List<int> publicKey,
    required WalletBitcoinCashNetwork network,
    required CryptoCoins coin,
    required BitcoinAddressType addressType,
    required PubKeyModes pubkeyMode,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required BitcoinCashAddress address,
    required String identifier,
    required String? id,
  }) {
    final transactionNetwork = network.coinParam.transacationNetwork;
    if (transactionNetwork is! BitcoinCashNetwork) {
      throw WalletExceptionConst.invalidAccountData("IBitcoinCashAddress._newAccount");
    }
    return IBitcoinCashAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        keyType: pubkeyMode,
        identifier: identifier,
        id: id);
  }

  factory IBitcoinCashAddress.deserialize(
      {required WalletBitcoinCashNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue toCborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.bitcoinCashMultiSigAccount
        .isValidTags(toCborTag.tags)) {
      return IBitcoinCashMultiSigAddress.deserialize(
          network: network, id: id, object: toCborTag, database: database);
    }
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborObject: toCborTag, identifier: AppSerializationIdentifier.bitcoinCashAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(cbor.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(1));
    final List<int> publicKey = cbor.rawValueAt(2);
    final BitcoinCashAddress address =
        BitcoinNetworkAddress.deserializeIAddress(bytes: cbor.rawValueAt(3))
            .cast<BitcoinCashAddress>();
    final int networkId = cbor.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final keyType =
        PubKeyModes.fromValue(cbor.rawValueAt(5), defaultValue: PubKeyModes.compressed);
    final String identifier = cbor.rawValueAt(6);

    return IBitcoinCashAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        id: id,
        network: network,
        keyType: keyType,
        identifier: identifier);
  }

  @override
  String get type => addrType.name;

  // @override
  @override
  String get baseAddress => networkAddress.baseAddress.addressProgram;

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      Bip32DerivationIndex index => BitcoinCashNewAddressParams(
          deriveIndex: index, bitcoinAddressType: addrType, coin: coin, keyType: keyType),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinCashAccount;

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

final class IBitcoinCashMultiSigAddress extends IBitcoinCashAddress
    with BitcoinMultiSigBase
    implements MultiSigCryptoAccountAddress {
  factory IBitcoinCashMultiSigAddress._newAccount({
    required WalletBitcoinCashNetwork network,
    required CryptoCoins coin,
    required BitcoinCashAddress address,
    required BitcoinMultiSignatureAddress multiSignatureAddress,
    required String identifier,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    final transactionNetwork = network.coinParam.transacationNetwork;
    if (transactionNetwork is! BitcoinCashNetwork) {
      throw WalletExceptionConst.invalidAccountData("IBitcoinCashAddress._newAccount");
    }
    return IBitcoinCashMultiSigAddress._(
        coin: coin,
        address: address.address,
        multiSignatureAddress: multiSignatureAddress,
        networkAddress: address,
        network: network,
        database: database,
        derivationIndex: MultiSigAddressIndex(),
        identifier: identifier,
        id: id);
  }

  factory IBitcoinCashMultiSigAddress.deserialize(
      {required WalletBitcoinCashNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.bitcoinCashMultiSigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final BitcoinMultiSignatureAddress multiSignatureAddress =
        BitcoinMultiSignatureAddress.deserialize(
            object: values.objectAt<CborTagValue>(1));
    final BitcoinCashAddress address =
        BitcoinNetworkAddress.deserializeIAddress(bytes: values.rawValueAt(2)).cast();
    final int networkId = values.rawValueAt(3);

    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(4));
    final String identifier = values.rawValueAt(5);
    return IBitcoinCashMultiSigAddress._(
        coin: coin,
        address: address.address,
        networkAddress: address,
        multiSignatureAddress: multiSignatureAddress,
        network: network.cast(),
        derivationIndex: derivationIndex,
        database: database,
        identifier: identifier,
        id: id);
  }
  IBitcoinCashMultiSigAddress._({
    required super.coin,
    required super.networkAddress,
    required super.address,
    required this.multiSignatureAddress,
    required super.network,
    required super.derivationIndex,
    required super.database,
    required super.identifier,
    required super.id,
  }) : super._(publicKey: const [], keyType: PubKeyModes.compressed);

  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  @override
  PubKeyModes get keyType =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  @override
  final BitcoinMultiSignatureAddress multiSignatureAddress;
  @override
  Script? witnessScript() {
    return null;
  }

  @override
  Script? redeemScript() {
    if (!addrType.isP2sh) return null;
    switch (addrType) {
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkInP2sh32:
      case P2shAddressType.p2pkInP2shwt:
      case P2shAddressType.p2pkInP2sh32wt:
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return multiSignatureAddress.multiSigScript;
      default:
        return null;
    }
  }

  late final UtxoAddressDetails _toUtxoRequest = UtxoAddressDetails.multiSigAddress(
      multiSigAddress: multiSignatureAddress, address: networkAddress.baseAddress);
  @override
  UtxoAddressDetails get toUtxoRequest => _toUtxoRequest;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinCashMultiSigAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        derivationIndex.toCbor(),
        identifier.toCbor()
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
  String get baseAddress => networkAddress.baseAddress.addressProgram;

  @override
  NewAccountParams toAccountParams() {
    return BitcoinCashMultiSigNewAddressParams(
        multiSignatureAddress: multiSignatureAddress,
        bitcoinAddressType: addrType,
        coin: coin);
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByPublicKey;
}
