part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class BitcoinNewAddressParams extends NewDerivableAccountParams<IBitcoinAddress> {
  @override
  final DerivableIndex deriveIndex;
  final BitcoinAddressType bitcoinAddressType;
  final PubKeyModes keyType;
  @override
  final CryptoCoins coin;

  const BitcoinNewAddressParams._(
      {required this.deriveIndex,
      required this.bitcoinAddressType,
      required this.coin,
      required this.keyType});
  factory BitcoinNewAddressParams(
      {required DerivableIndex deriveIndex,
      required BitcoinAddressType bitcoinAddressType,
      required CryptoCoins coin,
      required PubKeyModes keyType}) {
    return BitcoinNewAddressParams._(
        deriveIndex: deriveIndex,
        bitcoinAddressType: bitcoinAddressType,
        coin: coin,
        keyType: keyType);
  }
  factory BitcoinNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.bitcoinNewAddressParams.tag);
    return BitcoinNewAddressParams(
        deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        bitcoinAddressType: BitcoinAddressType.fromTag(values.rawValueAt(1)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
        keyType: PubKeyModes.fromValue(values.rawValueAt(3)));
  }

  @override
  IBitcoinAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletBitcoinNetwork ||
        network.coinParam.transacationNetwork is BitcoinCashNetwork) {
      throw WalletExceptionConst.invalidAccountData("BitcoinNewAddressParams.toAccount");
    }
    final pubkeyBytes = publicKey.keyBytes(mode: keyType, immutable: true);
    final address = BlockchainAddressUtils.publicKeyToBitcoinNetworkAddress(
        publicKey: pubkeyBytes,
        coin: coin,
        addressType: bitcoinAddressType,
        keyType: keyType,
        network: network.coinParam.transacationNetwork);
    return IBitcoinAddress._newAccount(
        publicKey: publicKey.keyBytes(mode: keyType),
        database: database,
        network: network,
        address: address,
        addressType: bitcoinAddressType,
        derivationIndex: deriveIndex,
        coin: coin,
        pubKeyMode: keyType,
        identifier: NewAccountParams.toIdentifier(address.address),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        deriveIndex.toCbor(),
        bitcoinAddressType.id.toCbor(),
        coin.identifier.toCbor(),
        CborIntValue(keyType.value)
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.bitcoinNewAddressParams;
}

final class BitcoinMultiSigNewAddressParams extends NewAccountParams<IBitcoinAddress> {
  final BitcoinAddressType bitcoinAddressType;
  final BitcoinMultiSignatureAddress multiSignatureAddress;

  @override
  final CryptoCoins coin;

  BitcoinMultiSigNewAddressParams._({
    required this.bitcoinAddressType,
    required this.multiSignatureAddress,
    required this.coin,
  });

  factory BitcoinMultiSigNewAddressParams({
    required BitcoinAddressType bitcoinAddressType,
    required BitcoinMultiSignatureAddress multiSignatureAddress,
    required CryptoCoins coin,
  }) {
    return BitcoinMultiSigNewAddressParams._(
        bitcoinAddressType: bitcoinAddressType,
        multiSignatureAddress: multiSignatureAddress,
        coin: coin);
  }

  factory BitcoinMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.bitcoinMultiSigNewAddressParams.tag);
    return BitcoinMultiSigNewAddressParams(
      bitcoinAddressType: BitcoinAddressType.fromTag(values.rawValueAt(0)),
      multiSignatureAddress: BitcoinMultiSignatureAddress.deserialize(
          object: values.objectAt<CborTagValue>(1)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }

  @override
  IBitcoinAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (network is! WalletBitcoinNetwork ||
        network.coinParam.transacationNetwork is BitcoinCashNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "BitcoinMultiSigNewAddressParams.toAccount");
    }
    final address = multiSignatureAddress.fromType(
        network: network.coinParam.transacationNetwork, addressType: bitcoinAddressType);
    return IBitcoinMultiSigAddress._newAccount(
        database: database,
        address: BitcoinNetworkAddress.fromBaseAddress(
            address: address, network: network.coinParam.transacationNetwork),
        coin: coin,
        multiSignatureAddress: multiSignatureAddress,
        network: network,
        addressType: bitcoinAddressType,
        identifier: NewAccountParams.toIdentifier(
            address.toAddress(network.coinParam.transacationNetwork)),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        bitcoinAddressType.id.toCbor(),
        multiSignatureAddress.toCbor(),
        coin.identifier.toCbor()
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.bitcoinMultiSigNewAddressParams;
}

final class BitcoinCashNewAddressParams
    extends NewDerivableAccountParams<IBitcoinCashAddress> {
  @override
  final DerivableIndex deriveIndex;
  final BitcoinAddressType bitcoinAddressType;
  @override
  final CryptoCoins coin;
  final PubKeyModes keyType;

  BitcoinCashNewAddressParams._(
      {required this.deriveIndex,
      required this.bitcoinAddressType,
      required this.coin,
      required this.keyType});
  factory BitcoinCashNewAddressParams(
      {required DerivableIndex deriveIndex,
      required BitcoinAddressType bitcoinAddressType,
      required CryptoCoins coin,
      required PubKeyModes keyType}) {
    return BitcoinCashNewAddressParams._(
        deriveIndex: deriveIndex,
        bitcoinAddressType: bitcoinAddressType,
        coin: coin,
        keyType: keyType);
  }
  factory BitcoinCashNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.bitcoinCashNewAddressParams.tag);
    return BitcoinCashNewAddressParams(
        deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        bitcoinAddressType: BitcoinAddressType.fromTag(values.rawValueAt(1)),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
        keyType: PubKeyModes.fromValue(values.rawValueAt(3),
            defaultValue: PubKeyModes.compressed));
  }

  @override
  IBitcoinCashAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    final pubKey = publicKey.keyBytes(mode: keyType, immutable: true);
    if (network is! WalletBitcoinCashNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "BitcoinCashNewAddressParams.toAccount");
    }
    final BitcoinCashAddress addr =
        BlockchainAddressUtils.publicKeyToBitcoinNetworkAddress(
                publicKey: pubKey,
                coin: coin,
                addressType: bitcoinAddressType,
                keyType: keyType,
                network: network.coinParam.transacationNetwork)
            .cast();
    return IBitcoinCashAddress._newAccount(
        database: database,
        identifier: NewAccountParams.toIdentifier(addr.address),
        coin: coin,
        addressType: bitcoinAddressType,
        derivationIndex: deriveIndex,
        pubkeyMode: keyType,
        address: addr,
        publicKey: pubKey,
        network: network,
        id: id);
  }

  @override
  List<CborObject?> get serializationItems => [
        deriveIndex.toCbor(),
        bitcoinAddressType.id.toCbor(),
        coin.identifier.toCbor(),
        CborIntValue(keyType.value)
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.bitcoinCashNewAddressParams;
}

final class BitcoinCashMultiSigNewAddressParams
    extends NewAccountParams<IBitcoinCashAddress> {
  final BitcoinAddressType bitcoinAddressType;
  final BitcoinMultiSignatureAddress multiSignatureAddress;

  @override
  final CryptoCoins coin;
  BitcoinCashMultiSigNewAddressParams._(
      {required this.bitcoinAddressType,
      required this.multiSignatureAddress,
      required this.coin});
  factory BitcoinCashMultiSigNewAddressParams(
      {required BitcoinAddressType bitcoinAddressType,
      required BitcoinMultiSignatureAddress multiSignatureAddress,
      required CryptoCoins coin}) {
    return BitcoinCashMultiSigNewAddressParams._(
        bitcoinAddressType: bitcoinAddressType,
        multiSignatureAddress: multiSignatureAddress,
        coin: coin);
  }
  factory BitcoinCashMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.bitcoinCashMultiSigNewAddressParams.tag);
    return BitcoinCashMultiSigNewAddressParams(
      bitcoinAddressType: BitcoinAddressType.fromTag(values.rawValueAt(0)),
      multiSignatureAddress: BitcoinMultiSignatureAddress.deserialize(
          object: values.objectAt<CborTagValue>(1)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }

  @override
  IBitcoinCashAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (network is! WalletBitcoinCashNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "BitcoinCashMultiSigNewAddressParams.toAccount");
    }
    final address = multiSignatureAddress.fromType(
        network: network.coinParam.transacationNetwork, addressType: bitcoinAddressType);
    final bchAddr = BitcoinCashAddress.fromBaseAddress(address,
        network: network.coinParam.transacationNetwork as BitcoinCashNetwork);
    return IBitcoinCashMultiSigAddress._newAccount(
        address: bchAddr,
        database: database,
        coin: coin,
        multiSignatureAddress: multiSignatureAddress,
        identifier: NewAccountParams.toIdentifier(bchAddr.address),
        id: id,
        network: network);
  }

  @override
  List<CborObject?> get serializationItems => [
        bitcoinAddressType.id.toCbor(),
        multiSignatureAddress.toCbor(),
        coin.identifier.toCbor()
      ];
  @override
  NewAccountParamsType get type =>
      NewAccountParamsType.bitcoinCashMultiSigNewAddressParams;
}
