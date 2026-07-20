part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class SubstrateNewAddressParams
    extends NewDerivableAccountParams<ISubstrateAddress> {
  @override
  CryptoCoins get coin => deriveIndex.currencyCoin;

  @override
  final DerivableIndex deriveIndex;

  const SubstrateNewAddressParams._({required this.deriveIndex});
  factory SubstrateNewAddressParams({required DerivableIndex deriveIndex}) {
    return SubstrateNewAddressParams._(deriveIndex: deriveIndex);
  }

  factory SubstrateNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.substrateNewAddressParams.tag);
    return SubstrateNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
    );
  }

  @override
  ISubstrateAddress toAccount(
    WalletNetwork network,
    CryptoPublicKeyData? publicKey,
    String? id,
    IAppDatabaseApi? database,
  ) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletSubstrateNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "SubstrateNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.normalizedComprossedBytes.asImmutableBytes;
    final address = SubstrateUtils.toAddress(
        publicKey: keyBytes,
        ss58Format: network.coinParam.ss58Format,
        curve: coin.conf.type,
        isEthereum: network.coinParam.substrateChainType.isEthereum);
    return ISubstrateAddress._newAccount(
        publicKey: keyBytes,
        network: network,
        address: address,
        database: database,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        derivationIndex: deriveIndex,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [deriveIndex.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.substrateNewAddressParams;
}

final class SubstrateMultiSigNewAddressParams
    extends NewAccountParams<ISubstrateAddress> {
  @override
  final CryptoCoins coin;
  final SubstrateMultisigAccountInfo multiSignatureAddress;
  final BaseSubstrateAddress address;

  SubstrateMultiSigNewAddressParams._({
    required this.multiSignatureAddress,
    required this.coin,
    required this.address,
  });

  factory SubstrateMultiSigNewAddressParams(
      {required SubstrateMultisigAccountInfo multiSignatureAddress,
      required CryptoCoins coin,
      required BaseSubstrateAddress address}) {
    return SubstrateMultiSigNewAddressParams._(
        multiSignatureAddress: multiSignatureAddress, coin: coin, address: address);
  }

  factory SubstrateMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.substrateMultisigNewAddressParams.tag);
    return SubstrateMultiSigNewAddressParams(
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(0)),
        multiSignatureAddress:
            SubstrateMultisigAccountInfo.deserialize(object: values.rawValueAt(1)),
        address: BaseSubstrateAddress(values.rawValueAt(2)));
  }

  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        multiSignatureAddress.toCbor(),
        CborStringValue(address.address),
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.substrateMultisigNewAddressParams;

  @override
  ISubstrateAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (network is! WalletSubstrateNetwork ||
        network.coinParam.substrateChainType.isEthereum) {
      throw WalletExceptionConst.invalidAccountData(
          "SubstrateNewAddressParams.toAccount");
    }

    return ISubstrateMultiSigAddress._newAccount(
        network: network,
        address: address.type.isSubstrate
            ? address.cast<SubstrateAddress>().toSS58(network.coinParam.ss58Format)
            : address,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        multiSignatureAddress: multiSignatureAddress,
        id: id,
        database: database);
  }
}
