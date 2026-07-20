part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class IAptosAddress extends ChainAccount<AptosAddress, AptosFATokens, NFTCore,
    AptosWalletTransaction, WalletAptosNetwork> {
  IAptosAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required this.keyScheme,
      required super.identifier,
      required super.id,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;

  factory IAptosAddress._newAccount({
    required AptosAddress address,
    required WalletAptosNetwork network,
    required List<int> publicKey,
    required String identifier,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required AptosSupportKeyScheme keyScheme,
    required CryptoCoins coin,
    required String? id,
  }) {
    return IAptosAddress._(
        coin: coin,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        keyScheme: keyScheme,
        networkAddress: address,
        network: network,
        publicKey: publicKey,
        identifier: identifier,
        id: id);
  }
  factory IAptosAddress.deserialize(
      {required WalletAptosNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue cborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    if (AppSerializationIdentifier.aptosMultisigAccount.isValidTags(cborTag.tags)) {
      return IAptosMultiSigAddress.deserialize(
          network: network, id: id, object: cborTag, database: database);
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: cborTag, identifier: AppSerializationIdentifier.aptosAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final AptosAddress networkAddress =
        AptosAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final AptosSupportKeyScheme keyScheme =
        AptosSupportKeyScheme.fromValue(values.rawValueAt(4));
    final List<int> publicKey = values.rawValueAt(5);
    final String identifier = values.rawValueAt(6);
    return IAptosAddress._(
        coin: coin,
        address: networkAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: networkAddress,
        network: network.cast(),
        keyScheme: keyScheme,
        publicKey: publicKey,
        identifier: identifier,
        id: id);
  }

  final AptosSupportKeyScheme keyScheme;
  final List<int> publicKey;

  @override
  List get variables {
    return [derivationIndex, network, keyScheme];
  }

  @override
  String? get type => keyScheme.name;

  @override
  NewAccountParams toAccountParams() {
    return switch (derivationIndex) {
      Bip32DerivationIndex index =>
        AptosNewAddressParams(deriveIndex: index, coin: coin, keyScheme: keyScheme),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }

  /// create transaction authenticated.
  AptosAccountAuthenticator createAccountAuthenticated(
      List<AptosAnySignature> signatures) {
    if (signatures.length != 1) {
      throw AppCryptoException("invalid_signature");
    }
    final signature = signatures[0];
    switch (keyScheme) {
      case AptosSupportKeyScheme.ed25519:
        return AptosAccountAuthenticatorEd25519(
            publicKey: AptosED25519PublicKey.fromBytes(publicKey),
            signature: AptosEd25519Signature(signature.signatureBytes()));
      case AptosSupportKeyScheme.signleKeyEd25519:
      case AptosSupportKeyScheme.signleKeySecp256k1:
        return AptosAccountAuthenticatorSingleKey(
            publicKey: AptosCryptoPublicKey.fromBytes(
                publicKeyBytes: publicKey, algorithm: keyScheme.curve),
            signature: signature);
      default:
        throw WalletExceptionConst.invalidAccountData("createAccountAuthenticated");
    }
  }

  AptosAccountPublicKey aptosPublicKey() {
    switch (keyScheme) {
      case AptosSupportKeyScheme.ed25519:
        return AptosEd25519AccountPublicKey(AptosED25519PublicKey.fromBytes(publicKey));
      case AptosSupportKeyScheme.signleKeyEd25519:
      case AptosSupportKeyScheme.signleKeySecp256k1:
        return AptosSingleKeyAccountPublicKey(AptosCryptoPublicKey.fromBytes(
            publicKeyBytes: publicKey, algorithm: keyScheme.curve));
      default:
        throw WalletExceptionConst.invalidAccountData("aptosPublicKey");
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.aptosAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        keyScheme.value.toCbor(),
        CborBytesValue(publicKey),
        identifier.toCbor()
      ];
}

final class IAptosMultiSigAddress extends IAptosAddress
    implements MultiSigCryptoAccountAddress {
  factory IAptosMultiSigAddress._newAccount({
    required WalletAptosNetwork network,
    required AptosAddress address,
    required AptosMultisigAccountInfo multiSignatureAddress,
    required String identifier,
    required AptosSupportKeyScheme keyScheme,
    required CryptoCoins coin,
    required String? id,
    required IAppDatabaseApi? database,
  }) {
    return IAptosMultiSigAddress._(
        coin: coin,
        address: address.address,
        networkAddress: address,
        multiSignatureAddress: multiSignatureAddress,
        network: network,
        keyScheme: keyScheme,
        identifier: identifier,
        database: database,
        id: id);
  }

  factory IAptosMultiSigAddress.deserialize(
      {required WalletAptosNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.aptosMultisigAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final AptosMultisigAccountInfo multiSignatureAddress =
        AptosMultisigAccountInfo.deserialize(object: values.objectAt<CborTagValue>(1));
    final AptosAddress networkAddress =
        AptosAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final keyScheme = AptosSupportKeyScheme.fromValue(values.rawValueAt(4));
    if (keyScheme != multiSignatureAddress.keyScheme) {
      throw WalletExceptionConst.invalidAccountData("IAptosMultiSigAddress.deserialize");
    }
    final String identifier = values.rawValueAt(5);
    return IAptosMultiSigAddress._(
        coin: coin,
        address: networkAddress.address,
        multiSignatureAddress: multiSignatureAddress,
        network: network.cast(),
        networkAddress: networkAddress,
        database: database,
        keyScheme: keyScheme,
        identifier: identifier,
        id: id);
  }
  IAptosMultiSigAddress._({
    required super.coin,
    required super.address,
    required this.multiSignatureAddress,
    required super.network,
    required super.keyScheme,
    required super.identifier,
    required super.networkAddress,
    required super.database,
    required super.id,
  }) : super._(publicKey: const [], derivationIndex: MultiSigAddressIndex());

  @override
  List<int> get publicKey =>
      throw WalletExceptionConst.featureUnavailableForMultiSignature;

  final AptosMultisigAccountInfo multiSignatureAddress;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.aptosMultisigAccount;

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        keyScheme.value.toCbor(),
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
    return AptosMultiSigNewAddressParams(
        coin: coin, multiSignatureAddress: multiSignatureAddress);
  }

  /// create transaction authenticated.
  @override
  AptosAccountAuthenticator createAccountAuthenticated(
      List<AptosAnySignature> signatures) {
    return multiSignatureAddress.createAccountAuthenticated(signatures);
  }

  @override
  AptosAccountPublicKey aptosPublicKey() {
    return multiSignatureAddress.toAptosMutlisigPublicKey();
  }

  @override
  IAdressType get iAddressType => IAdressType.multisigByPublicKey;
}
