part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

enum StellarAddressType {
  muxedAddress("muxed_address"),
  pubkey("pubkey_address");

  final String value;
  const StellarAddressType(this.value);
}

final class IStellarAddress extends ChainAccount<StellarAddress, StellarIssueToken,
    NFTCore, StellarWalletTransaction, WalletStellarNetwork> {
  IStellarAddress._({
    required super.derivationIndex,
    required super.database,
    required super.coin,
    required List<int> publicKey,
    required super.address,
    required super.network,
    required super.networkAddress,
    required BigInt? muxedId,
    required super.identifier,
    required super.id,
  })  : publicKey = publicKey.asImmutableBytes,
        id = muxedId,
        addressType =
            muxedId == null ? StellarAddressType.pubkey : StellarAddressType.muxedAddress;

  factory IStellarAddress._newAccount({
    // required StellarNewAddressParams accountParams,
    required List<int> publicKey,
    required WalletStellarNetwork network,
    required StellarAddress address,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required CryptoCoins coin,
    required BigInt? muxId,
    required String identifier,
    required String? id,
  }) {
    return IStellarAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        muxedId: muxId,
        identifier: identifier,
        id: id);
  }

  factory IStellarAddress.deserialize(
      {required WalletStellarNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborTagValue toCborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);

    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: toCborTag, identifier: AppSerializationIdentifier.stellarAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final List<int> publicKey = values.rawValueAt(2);
    final StellarAddress stellarAddress =
        StellarAddress.deserializeIAddress(bytes: values.rawValueAt(3));

    final BigInt? muxedId = values.rawValueAt(4);
    final int networkId = values.rawValueAt(5);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(6);
    return IStellarAddress._(
        coin: coin,
        publicKey: publicKey,
        address: stellarAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: stellarAddress,
        network: network,
        muxedId: muxedId,
        id: id,
        identifier: identifier);
  }

  final List<int> publicKey;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.stellarAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        publicKey.toCborBytes(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        id?.toCbor(),
        network.value.toCbor(),
        identifier.toCbor()
      ];
  @override
  List get variables {
    return [id, derivationIndex, network.value];
  }

  final StellarAddressType addressType;
  final BigInt? id;

  @override
  String get type => addressType.value;

  @override
  String get baseAddress => networkAddress.baseAddress;

  @override
  StellarNewAddressParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index =>
        StellarNewAddressParams(deriveIndex: index, coin: coin, id: id),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }
}
