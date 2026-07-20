part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class CardanoNewAddressParams extends NewDerivableAccountParams<ICardanoAddress> {
  final ADAAddressType addressType;
  @override
  final DerivableIndex deriveIndex;
  final DerivableIndex? rewardKeyIndex;
  final CardanoAddrDetails? addressDetails;
  final String? customHdPath;
  final List<int>? customHdPathKey;
  bool get needStakeKey => addressType == ADAAddressType.base;

  @override
  final CryptoCoins coin;
  CardanoNewAddressParams._(
      {required this.addressType,
      required this.deriveIndex,
      required this.rewardKeyIndex,
      required this.coin,
      this.addressDetails,
      this.customHdPath,
      List<int>? customHdPathKey})
      : customHdPathKey = BytesUtils.tryToBytes(customHdPathKey, unmodifiable: true);
  factory CardanoNewAddressParams(
      {required ADAAddressType addressType,
      required DerivableIndex deriveIndex,
      required DerivableIndex? rewardKeyIndex,
      required CryptoCoins coin,
      CardanoAddrDetails? addressDetails,
      String? customHdPath,
      List<int>? customHdPathKey}) {
    return CardanoNewAddressParams._(
        addressType: addressType,
        deriveIndex: deriveIndex,
        rewardKeyIndex: rewardKeyIndex,
        coin: coin,
        addressDetails: addressDetails,
        customHdPath: customHdPath,
        customHdPathKey: customHdPathKey);
  }

  factory CardanoNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.cardanoNewAddressParams.tag);
    return CardanoNewAddressParams(
        addressType: ADAAddressType.fromHeader(values.rawValueAt(0)),
        deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(1)),
        rewardKeyIndex: values.maybeObjectAt<Bip32DerivationIndex, CborObject>(
            2, (e) => Bip32DerivationIndex.deserialize(object: e)),
        addressDetails: values.maybeObjectAt<CardanoAddrDetails, CborObject>(
            3, (e) => CardanoAddrDetails.deserialize(object: e)),
        customHdPath: values.rawValueAt(4),
        customHdPathKey: values.rawValueAt(5),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(6)));
  }
  CardanoNewAddressParams copyWith(
      {ADAAddressType? addressType,
      DerivableIndex? deriveIndex,
      CardanoAddrDetails? addressDetails,
      DerivableIndex? rewardKeyIndex,
      List<int>? publicKey,
      String? customHdPath,
      List<int>? customHdPathKey,
      CryptoCoins? coin}) {
    return CardanoNewAddressParams(
        addressType: addressType ?? this.addressType,
        deriveIndex: deriveIndex ?? this.deriveIndex,
        addressDetails: addressDetails ?? this.addressDetails,
        rewardKeyIndex: rewardKeyIndex ?? this.rewardKeyIndex,
        customHdPath: customHdPath,
        customHdPathKey: customHdPathKey,
        coin: coin ?? this.coin);
  }

  @override
  ICardanoAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    final addressDetails = this.addressDetails;
    if (addressDetails == null) {
      throw WalletExceptionConst.invalidAccountData("CardanoNewAddressParams.toAccount");
    }
    if (network is! WalletCardanoNetwork) {
      throw WalletExceptionConst.invalidAccountData("CardanoNewAddressParams.toAccount");
    }
    if (needStakeKey && rewardKeyIndex == null) {
      throw WalletExceptionConst.invalidAccountData("CardanoNewAddressParams.toAccount");
    }
    final address = addressDetails.toAddress(network.coinParam.networkType);
    return ICardanoAddress._newAccount(
        publicKey: addressDetails.publicKey,
        network: network,
        address: address,
        addressInfo: addressDetails,
        database: database,
        coin: coin,
        derivationIndex: deriveIndex,
        rewardIndex: rewardKeyIndex,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
  @override
  List<CborObject?> get serializationItems => [
        addressType.header.toCbor(),
        deriveIndex.toCbor(),
        rewardKeyIndex?.toCbor(),
        addressDetails?.toCbor(),
        customHdPath?.toCbor(),
        customHdPathKey?.toCborBytes(),
        coin.identifier.toCbor()
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.cardanoNewAddressParams;
}

final class CardanoMultisigNewAddressParams extends NewAccountParams<ICardanoAddress> {
  ADAAddressType get addressType => addressInfo.addressType;
  final CardanoMultiSignatureAddressDetails addressInfo;
  bool get needStakeKey => addressType == ADAAddressType.base;
  @override
  final CryptoCoins coin;
  CardanoMultisigNewAddressParams._({required this.addressInfo, required this.coin});
  factory CardanoMultisigNewAddressParams(
      {required CardanoMultiSignatureAddressDetails addressInfo,
      required CryptoCoins coin}) {
    return CardanoMultisigNewAddressParams._(addressInfo: addressInfo, coin: coin);
  }

  factory CardanoMultisigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.cardanoMultisigNewAddressParams.tag);
    return CardanoMultisigNewAddressParams(
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(0)),
        addressInfo: CardanoMultiSignatureAddressDetails.deserialize(
            object: values.objectAt<CborTagValue>(1)));
  }

  @override
  ICardanoAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (network is! WalletCardanoNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "CardanoMultisigNewAddressParams.toAccount");
    }
    final address = addressInfo.toAddress(network.coinParam.networkType);
    return ICardanoMultiSigAddress._newAccount(
        network: network,
        address: address,
        addressInfo: addressInfo,
        database: database,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
  @override
  List<CborObject?> get serializationItems =>
      [coin.identifier.toCbor(), addressInfo.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.cardanoMultisigNewAddressParams;
}
