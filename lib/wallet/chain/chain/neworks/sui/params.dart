part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class SuiNewAddressParams extends NewDerivableAccountParams<ISuiAddress> {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;
  final SuiAddress? address;
  final SuiSupportKeyScheme keyScheme;
  SuiNewAddressParams._(
      {required this.deriveIndex,
      required this.coin,
      this.address,
      required this.keyScheme});
  factory SuiNewAddressParams(
      {required DerivableIndex deriveIndex,
      required CryptoCoins coin,
      SuiAddress? address,
      required SuiSupportKeyScheme keyScheme}) {
    return SuiNewAddressParams._(
        deriveIndex: deriveIndex, coin: coin, keyScheme: keyScheme, address: address);
  }

  SuiNewAddressParams updateAddress(SuiAddress address) {
    assert(this.address == null, "Address must be null.");
    return SuiNewAddressParams(
        deriveIndex: deriveIndex, coin: coin, address: address, keyScheme: keyScheme);
  }

  factory SuiNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.suiNewAddressParams.tag);
    return SuiNewAddressParams(
        deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
        address: values.maybeObjectAt<SuiAddress, CborStringValue>(
            2, (e) => SuiAddress(e.value)),
        keyScheme: SuiSupportKeyScheme.fromValue(values.rawValueAt(3)));
  }

  @override
  ISuiAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey, String? id,
      IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    final address = this.address;
    if (address == null || network is! WalletSuiNetwork) {
      throw WalletExceptionConst.invalidAccountData("SuiNewAddressParams.toAccount");
    }
    return ISuiAddress._newAccount(
        network: network,
        database: database,
        address: address,
        publicKey: publicKey.normalizedComprossedBytes.asImmutableBytes,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        derivationIndex: deriveIndex,
        keyScheme: keyScheme,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        deriveIndex.toCbor(),
        coin.identifier.toCbor(),
        address?.address.toCbor(),
        keyScheme.value.toCbor()
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.suiNewAddressParams;
}

final class SuiMultiSigNewAddressParams extends NewAccountParams<ISuiAddress> {
  @override
  final CryptoCoins coin;
  final SuiMultisigAccountInfo multiSignatureAddress;
  final SuiAddress address;

  SuiMultiSigNewAddressParams._({
    required this.multiSignatureAddress,
    required this.coin,
    required this.address,
  });

  factory SuiMultiSigNewAddressParams(
      {required SuiMultisigAccountInfo multiSignatureAddress,
      required CryptoCoins coin,
      required SuiAddress address}) {
    return SuiMultiSigNewAddressParams._(
        multiSignatureAddress: multiSignatureAddress, coin: coin, address: address);
  }

  factory SuiMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.suiMultisigNewAddressParams.tag);
    return SuiMultiSigNewAddressParams(
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(0)),
        multiSignatureAddress:
            SuiMultisigAccountInfo.deserialize(object: values.rawValueAt(1)),
        address: SuiAddress(values.rawValueAt(2)));
  }

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborStringValue(address.address),
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.suiMultisigNewAddressParams;

  SuiSupportKeyScheme get keyScheme => SuiSupportKeyScheme.multisig;

  NewAccountParams updateAddress(SuiAddress address) {
    return SuiMultiSigNewAddressParams(
        multiSignatureAddress: multiSignatureAddress, coin: coin, address: address);
  }

  @override
  ISuiAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey, String? id,
      IAppDatabaseApi? database) {
    if (network is! WalletSuiNetwork) {
      throw WalletExceptionConst.invalidAccountData("SuiNewAddressParams.toAccount");
    }

    return ISuiMultiSigAddress._newAccount(
        network: network,
        address: address,
        database: database,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        multiSignatureAddress: multiSignatureAddress,
        id: id);
  }
}
