part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class MoneroNewAddressParams extends NewDerivableAccountParams<IMoneroAddress> {
  @override
  final Bip32DerivationIndex deriveIndex;
  @override
  final CryptoCoins coin;
  final int minor;
  final int major;
  final MoneroViewPrimaryAccountDetails? masterKey;
  final MoneroAccountIndex? index;
  final MoneroNetwork network;
  final int? activeHeight;
  // final int currentHeight;

  const MoneroNewAddressParams._({
    required this.deriveIndex,
    required this.minor,
    required this.major,
    required this.coin,
    this.masterKey,
    this.index,
    required this.network,
    required this.activeHeight,
    // required this.currentHeight,
  });
  factory MoneroNewAddressParams({
    required Bip32DerivationIndex deriveIndex,
    required int minor,
    required int major,
    required CryptoCoins coin,
    MoneroViewPrimaryAccountDetails? masterKey,
    MoneroAccountIndex? index,
    required MoneroNetwork network,
    required int? activeHeight,
  }) {
    return MoneroNewAddressParams._(
        deriveIndex: deriveIndex,
        minor: minor,
        major: major,
        coin: coin,
        network: network,
        index: index,
        masterKey: masterKey,
        activeHeight: activeHeight);
  }
  MoneroNewAddressParams copyWith(
      {CryptoCoins? coin,
      int? minor,
      int? major,
      Bip32DerivationIndex? deriveIndex,
      MoneroViewPrimaryAccountDetails? masterKey,
      MoneroAccountIndex? index,
      MoneroNetwork? network,
      int? activationHeight}) {
    return MoneroNewAddressParams(
        deriveIndex: deriveIndex ?? this.deriveIndex,
        minor: minor ?? this.minor,
        major: major ?? this.major,
        coin: coin ?? this.coin,
        masterKey: masterKey ?? this.masterKey,
        index: index ?? this.index,
        network: network ?? this.network,
        activeHeight: activationHeight ?? activeHeight);
  }

  factory MoneroNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.moneroNewAddressParams.tag);
    return MoneroNewAddressParams(
        deriveIndex:
            Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        major: values.rawValueAt(1),
        minor: values.rawValueAt(2),
        coin: CoinsUtils.getSerializationCoin(values.rawValueAt(3)),
        network: MoneroNetwork.fromName(values.rawValueAt(4)),
        masterKey: values.maybeObjectAt<MoneroViewPrimaryAccountDetails, CborTagValue>(
            5, (e) => MoneroViewPrimaryAccountDetails.deserialize(object: e)),
        index: values.maybeObjectAt<MoneroAccountIndex, CborTagValue>(
            6, (e) => MoneroAccountIndex.deserialize(object: e)),
        activeHeight: values.rawValueAt(7));
  }
  MoneroAddress toAddress(
      {required WalletMoneroNetwork network,
      required MoneroViewPrimaryAccountDetails masterKey,
      required MoneroAccountIndex index}) {
    final keys =
        masterKey.account.scubaddr.computeKeys(index.index.minor, index.index.major);
    return MoneroAccountAddress.fromPubKeys(
        pubSpendKey: keys.pubSKey.key,
        pubViewKey: keys.pubVKey.key,
        network: network.coinParam.network,
        type: index.addrType);
  }

  @override
  IMoneroAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    final masterKey = this.masterKey;
    final index = this.index;
    if (masterKey == null || index == null) {
      throw WalletExceptionConst.invalidAccountData("MoneroNewAddressParams.toAccount");
    }
    if (network is! WalletMoneroNetwork) {
      throw WalletExceptionConst.invalidAccountData("MoneroNewAddressParams.toAccount");
    }
    final address = toAddress(network: network, masterKey: masterKey, index: index);
    return IMoneroAddress._newAccount(
        network: network,
        address: address,
        addressDetails: index,
        database: database,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.address),
        derivationIndex: deriveIndex,
        id: id,
        activationHeight: activeHeight);
  }

  @override
  List<CborObject?> get serializationItems => [
        deriveIndex.toCbor(),
        CborIntValue(major),
        CborIntValue(minor),
        coin.identifier.toCbor(),
        CborStringValue(network.name),
        masterKey?.toCbor(),
        index?.toCbor(),
        activeHeight?.toCbor()
      ];
  @override
  NewAccountParamsType get type => NewAccountParamsType.moneroNewAddressParams;
}
