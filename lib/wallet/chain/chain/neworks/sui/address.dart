part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ISuiAddress extends ChainAccount<SuiAddress, SuiToken, NFTCore,
    SuiWalletTransaction, WalletSuiNetwork> {
  ISuiAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required List<int> publicKey,
      required this.keyScheme,
      required super.identifier,
      required super.id})
      : publicKey = publicKey.asImmutableBytes;

  factory ISuiAddress._newAccount({
    // required SuiNewAddressParams accountParams,
    required SuiAddress address,
    required WalletSuiNetwork network,
    required List<int> publicKey,
    required CryptoCoins coin,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required SuiSupportKeyScheme keyScheme,
    required String identifier,
    required String? id,
  }) {
    return ISuiAddress._(
        coin: coin,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        keyScheme: keyScheme,
        publicKey: publicKey,
        identifier: identifier,
        id: id);
  }

  factory ISuiAddress.deserialize(
      {required WalletSuiNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue cborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.suiMultisigAccount.isValidTags(cborTag.tags)) {
      return ISuiMultiSigAddress.deserialize(
          network: network, id: id, object: cborTag, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.suiAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final SuiAddress suiAddress =
        SuiAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final SuiSupportKeyScheme keyScheme =
        SuiSupportKeyScheme.fromValue(values.rawValueAt(4));
    final List<int> publicKey = values.rawValueAt(5);
    final String identifier = values.rawValueAt(6);
    return ISuiAddress._(
        coin: coin,
        address: suiAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: suiAddress,
        network: network,
        keyScheme: keyScheme,
        publicKey: publicKey,
        identifier: identifier,
        id: id);
  }

  final SuiSupportKeyScheme keyScheme;

  final List<int> publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.suiAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        keyScheme.value.toCbor(),
        CborBytesValue(publicKey),
        identifier.toCbor(),
      ];
  @override
  List get variables {
    return [derivationIndex, network.value, keyScheme];
  }

  @override
  String? get type => keyScheme.name;

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index =>
        SuiNewAddressParams(deriveIndex: index, coin: coin, keyScheme: keyScheme),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }

  SuiAccountPublicKey toSuiPublicKey() {
    final SuiCryptoPublicKey publicKey = SuiCryptoPublicKey.fromBytes(
        keyBytes: this.publicKey, algorithm: keyScheme.suiKeyAlgorithm);
    switch (keyScheme) {
      case SuiSupportKeyScheme.ed25519:
        return SuiEd25519AccountPublicKey(publicKey.cast());
      case SuiSupportKeyScheme.secp256k1:
        return SuiSecp256k1AccountPublicKey(publicKey.cast());
      case SuiSupportKeyScheme.secp256r1:
        return SuiSecp256r1AccountPublicKey(publicKey.cast());
      default:
        throw WalletExceptionConst.invalidAccountData("ISuiAddress.toSuiPublicKey");
    }
  }

  SuiBaseSignature createTransactionAuthenticated(List<SuiGenericSignature> signatures) {
    if (signatures.length != 1) {
      throw AppCryptoException("invalid_signature");
    }
    final SuiCryptoPublicKey publicKey = SuiCryptoPublicKey.fromBytes(
        keyBytes: this.publicKey, algorithm: keyScheme.suiKeyAlgorithm);
    switch (keyScheme) {
      case SuiSupportKeyScheme.ed25519:
        return SuiEd25519Signature(
            publicKey: publicKey.cast(), signature: signatures.first);
      case SuiSupportKeyScheme.secp256k1:
        return SuiSecp256k1Signature(
            publicKey: publicKey.cast(), signature: signatures.first);
      case SuiSupportKeyScheme.secp256r1:
        return SuiSecp256r1Signature(
            publicKey: publicKey.cast(), signature: signatures.first);
      default:
        throw WalletExceptionConst.invalidAccountData(
            "ISuiAddress.createTransactionAuthenticated");
    }
  }
}

final class ISuiMultiSigAddress extends ISuiAddress
    implements MultiSigCryptoAccountAddress {
  factory ISuiMultiSigAddress._newAccount({
    required WalletSuiNetwork network,
    required CryptoCoins coin,
    required String identifier,
    required SuiAddress address,
    required SuiMultisigAccountInfo multiSignatureAddress,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return ISuiMultiSigAddress._(
        coin: coin,
        address: address.address,
        networkAddress: address,
        multiSignatureAddress: multiSignatureAddress,
        network: network,
        database: database,
        id: id,
        identifier: identifier);
  }

  factory ISuiMultiSigAddress.deserialize(
      {required WalletSuiNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.suiMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final SuiMultisigAccountInfo multiSignatureAddress =
        SuiMultisigAccountInfo.deserialize(object: values.objectAt<CborTagValue>(1));
    final SuiAddress networkAddress =
        SuiAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(4);
    return ISuiMultiSigAddress._(
        coin: coin,
        address: networkAddress.address,
        multiSignatureAddress: multiSignatureAddress,
        network: network,
        networkAddress: networkAddress,
        database: database,
        identifier: identifier,
        id: id);
  }
  ISuiMultiSigAddress._(
      {required super.coin,
      required super.address,
      required this.multiSignatureAddress,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required super.database,
      required super.id})
      : super._(
            publicKey: const [],
            derivationIndex: MultiSigAddressIndex(),
            keyScheme: SuiSupportKeyScheme.multisig);

  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  final SuiMultisigAccountInfo multiSignatureAddress;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.suiMultisigAccount;
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
    switch (request) {
      case null:
      case AccountDerivationIndexRequestSigners():
        return multiSignatureAddress.publicKeys.map((e) => e.derivationIndex).toList();
      case AccountDerivationIndexRequestAddress():
        return [];
      default:
        throw AppInternalError.internalError("Invalid request");
    }
  }

  @override
  NewAccountParams toAccountParams() {
    return SuiMultiSigNewAddressParams(
        coin: coin,
        multiSignatureAddress: multiSignatureAddress,
        address: networkAddress);
  }

  @override
  SuiAccountPublicKey toSuiPublicKey() {
    return multiSignatureAddress.toSuiMutlisigPublicKey();
  }

  @override
  SuiBaseSignature createTransactionAuthenticated(List<SuiGenericSignature> signatures) {
    return multiSignatureAddress.createTransactionAuthenticated(signatures);
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByPublicKey;
}
