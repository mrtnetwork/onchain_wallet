part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class RippleNewAddressParams extends NewDerivableAccountParams<IXRPAddress> {
  EllipticCurveTypes get curve => coin.conf.type;
  @override
  final DerivableIndex deriveIndex;

  final int? tag;
  @override
  final CryptoCoins coin;
  const RippleNewAddressParams._(
      {required this.deriveIndex, required this.coin, this.tag});
  factory RippleNewAddressParams(
      {required DerivableIndex deriveIndex, required CryptoCoins coin, int? tag}) {
    return RippleNewAddressParams._(deriveIndex: deriveIndex, coin: coin, tag: tag);
  }

  factory RippleNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.rippleNewAddressParams.tag);
    return RippleNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
      tag: values.rawValueAt(1),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }
  @override
  IXRPAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey, String? id,
      IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletXRPNetwork) {
      throw WalletExceptionConst.invalidAccountData("RippleNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.normalizedComprossedBytes.asImmutableBytes;
    final keyAlgorithm = XRPKeyAlgorithm.values.firstWhere((e) => e.curveType == curve,
        orElse: () => throw WalletExceptionConst.invalidAccountData(
            "RippleNewAddressParams.toAccount"));
    final address = RippleUtils.publicKeyToRippleAddress(keyBytes,
        algorithm: keyAlgorithm, tag: tag, isTenstNet: !network.coinParam.mainnet);
    return IXRPAddress._newAccount(
        publicKey: keyBytes,
        network: network,
        database: database,
        address: address,
        coin: coin,
        derivationIndex: deriveIndex,
        tag: tag,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), tag?.toCbor(), coin.identifier.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.rippleNewAddressParams;
}

final class RippleMultiSigNewAddressParams extends NewAccountParams<IXRPAddress> {
  final XRPBaseAddress masterAddress;

  final RippleMultiSignatureAddress multiSigAccount;

  final int? tag;

  @override
  final CryptoCoins coin;

  RippleMultiSigNewAddressParams._(
      {required this.multiSigAccount,
      required this.masterAddress,
      required this.coin,
      this.tag});
  factory RippleMultiSigNewAddressParams(
      {required RippleMultiSignatureAddress multiSigAccount,
      required XRPBaseAddress masterAddress,
      required CryptoCoins coin}) {
    return RippleMultiSigNewAddressParams._(
        multiSigAccount: multiSigAccount,
        masterAddress: masterAddress,
        coin: coin,
        tag: masterAddress.tag);
  }
  factory RippleMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.rippleMultiSigNewAddressParams.tag);
    return RippleMultiSigNewAddressParams._(
      masterAddress: XRPBaseAddress(values.rawValueAt(0)),
      multiSigAccount: RippleMultiSignatureAddress.deserialize(
          object: values.objectAt<CborTagValue>(1)),
      tag: values.rawValueAt(1),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }

  @override
  IXRPMultisigAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (network is! WalletXRPNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "RippleMultiSigNewAddressParams.toAccount");
    }

    return IXRPMultisigAddress._newAccount(
        network: network,
        database: database,
        address: masterAddress,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(masterAddress.address,
            multisigAddress: multiSigAccount.toCbor().encode()),
        multiSigAccount: multiSigAccount,
        tag: tag,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        masterAddress.classicAddress.toCbor(),
        multiSigAccount.toCbor(),
        tag?.toCbor(),
        coin.identifier.toCbor()
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.rippleMultiSigNewAddressParams;
}
