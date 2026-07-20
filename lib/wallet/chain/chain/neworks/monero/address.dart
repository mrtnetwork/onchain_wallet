part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class IMoneroAddress extends ChainAccount<MoneroAddress, TokenCore, NFTCore,
    MoneroWalletTransaction, WalletMoneroNetwork> {
  factory IMoneroAddress._newAccount({
    required WalletMoneroNetwork network,
    required MoneroAddress address,
    required MoneroAccountIndex addressDetails,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required CryptoCoins coin,
    required String identifier,
    required String? id,
    required int? activationHeight,
  }) {
    return IMoneroAddress._(
        coin: coin,
        address: address.address,
        identifier: identifier,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        index: addressDetails,
        id: id,
        activationHeight: activationHeight);
  }

  factory IMoneroAddress.deserialize(
      {required WalletMoneroNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final index =
        MoneroAccountIndex.deserialize(object: values.objectAt<CborTagValue>(2));
    final networkAddress = MoneroAddress.deserializeIAddress(bytes: values.rawValueAt(3));
    final int networkId = values.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(5);
    final int? activationHeight = values.rawValueAt(6);
    return IMoneroAddress._(
        coin: coin,
        address: networkAddress.address,
        database: database,
        derivationIndex: derivationIndex.cast(),
        networkAddress: networkAddress,
        network: network,
        index: index,
        identifier: identifier,
        id: id,
        activationHeight: activationHeight);
  }
  IMoneroAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.networkAddress,
      required super.address,
      required super.network,
      required this.index,
      required super.identifier,
      required super.id,
      required this.activationHeight});

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        index.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        identifier.toCbor()
      ];
  final MoneroAccountIndex index;
  final int? activationHeight;

  @override
  List get variables => [index, derivationIndex, network.value];

  @override
  String get type => networkAddress.type.name;
  @override
  MoneroNewAddressParams toAccountParams() {
    return switch (derivationIndex) {
      Bip32DerivationIndex dIndex => MoneroNewAddressParams(
          deriveIndex: dIndex,
          major: index.index.major,
          minor: index.index.minor,
          activeHeight: activationHeight,
          coin: coin,
          network: network.coinParam.network),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }
}
