part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class AptosNewAddressParams extends NewDerivableAccountParams<IAptosAddress> {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;
  final AptosSupportKeyScheme keyScheme;
  final AptosAddress? address;
  AptosNewAddressParams._(
      {required this.deriveIndex,
      required this.coin,
      this.address,
      required this.keyScheme});
  factory AptosNewAddressParams(
      {required DerivableIndex deriveIndex,
      required CryptoCoins coin,
      required AptosSupportKeyScheme keyScheme}) {
    return AptosNewAddressParams._(
        deriveIndex: deriveIndex, coin: coin, keyScheme: keyScheme);
  }

  AptosNewAddressParams updateAddress(AptosAddress address) {
    assert(this.address == null, "Address must be null.");
    return AptosNewAddressParams._(
        deriveIndex: deriveIndex, coin: coin, address: address, keyScheme: keyScheme);
  }

  factory AptosNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.aptosNewAddressParams.tag);
    return AptosNewAddressParams._(
        deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
        address: values.maybeObjectAt<AptosAddress, CborStringValue>(
            2, (e) => AptosAddress(e.value)),
        keyScheme: AptosSupportKeyScheme.fromValue(values.rawValueAt(3)));
  }
  AptosAccountPublicKey aptosPublicKey(List<int> publicKey) {
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
  IAptosAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    final address = this.address;
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }

    if (address == null) {
      throw WalletExceptionConst.invalidAccountData("AptosNewAddressParams.toAccount");
    }
    return IAptosAddress._newAccount(
        coin: coin,
        derivationIndex: deriveIndex,
        keyScheme: keyScheme,
        address: address,
        identifier: NewAccountParams.toIdentifier(address.address),
        network: network.cast(),
        publicKey: publicKey.normalizedComprossedBytes,
        database: database,
        id: id);
  }

  @override
  NewAccountParamsType get type => NewAccountParamsType.aptosNewAddressParams;

  @override
  List<CborObject?> get serializationItems => [
        deriveIndex.toCbor(),
        coin.identifier.toCbor(),
        address?.address.toCbor(),
        keyScheme.value.toCbor()
      ];
}

final class AptosMultiSigNewAddressParams extends NewAccountParams<IAptosAddress> {
  @override
  final CryptoCoins coin;
  final AptosAddress address;

  final AptosMultisigAccountInfo multiSignatureAddress;

  AptosMultiSigNewAddressParams._({
    required this.multiSignatureAddress,
    required this.coin,
    required this.address,
  }) : super();
  factory AptosMultiSigNewAddressParams({
    required AptosMultisigAccountInfo multiSignatureAddress,
    required CryptoCoins coin,
  }) {
    return AptosMultiSigNewAddressParams._(
        multiSignatureAddress: multiSignatureAddress,
        coin: coin,
        address: multiSignatureAddress.generateAddress());
  }

  factory AptosMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.aptosMultisigNewAddressParams.tag);
    return AptosMultiSigNewAddressParams._(
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(0)),
        multiSignatureAddress: AptosMultisigAccountInfo.deserialize(
            object: values.objectAt<CborTagValue>(1)),
        address: AptosAddress(values.rawValueAt(2)));
  }

  @override
  NewAccountParamsType get type => NewAccountParamsType.aptosMultisigNewAddressParams;

  AptosSupportKeyScheme get keyScheme => multiSignatureAddress.keyScheme;

  @override
  IAptosAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    final address = this.address;
    if (network is! WalletAptosNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "AptosMultiSigNewAddressParams.toAccount");
    }
    return IAptosMultiSigAddress._newAccount(
        network: network.cast(),
        database: database,
        address: address,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        keyScheme: keyScheme,
        multiSignatureAddress: multiSignatureAddress,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborStringValue(address.address),
      ];
}
