part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ICosmosAddress extends ChainAccount<CosmosBaseAddress, CW20Token, NFTCore,
    CosmosWalletTransaction, WalletCosmosNetwork> {
  ICosmosAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required List<int> publicKey,
      required super.address,
      required super.network,
      required super.networkAddress,
      required this.algorithm,
      required super.identifier,
      required super.id,
      this.ethAddress})
      : publicKey = publicKey.asImmutableBytes;

  factory ICosmosAddress._newAccount({
    required List<int> publicKey,
    required WalletCosmosNetwork network,
    required CosmosKeysAlgs algorithm,
    required CosmosBaseAddress address,
    required CryptoCoins coin,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required String identifier,
    required String? id,
    ETHAddress? ethAddress,
  }) {
    return ICosmosAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        algorithm: algorithm,
        identifier: identifier,
        id: id,
        ethAddress: ethAddress);
  }

  factory ICosmosAddress.deserialize(
      {required WalletCosmosNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cosmosAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final List<int> publicKey = values.rawValueAt(2);
    final CosmosBaseAddress cosmosAddr =
        CosmosBaseAddress.deserializeIAddress(bytes: values.rawValueAt(3));
    final int networkId = values.rawValueAt(4);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final algorithm = CosmosKeysAlgs.fromValue(values.rawValueAt(5));
    final String identifier = values.rawValueAt(6);
    final ETHAddress? ethAddress = values.maybeObjectAt<ETHAddress, CborBytesValue>(
        7, (e) => ETHAddress.deserializeIAddress(bytes: e.value));
    return ICosmosAddress._(
        coin: coin,
        publicKey: publicKey,
        address: cosmosAddr.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: cosmosAddr,
        network: network,
        algorithm: algorithm,
        identifier: identifier,
        id: id,
        ethAddress: ethAddress);
  }

  final List<int> publicKey;

  final CosmosKeysAlgs algorithm;

  final ETHAddress? ethAddress;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cosmosAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        publicKey.toCborBytes(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        algorithm.value.toCbor(),
        identifier.toCbor(),
        ethAddress?.encodeAsIAddress().toCborBytes(),
      ];
  @override
  List get variables {
    return [derivationIndex, network.value];
  }

  @override
  String? get type => null;

  CosmosPublicKey toCosmosPublicKey() {
    return CosmosPublicKey.fromBytes(keyBytes: publicKey, algorithm: algorithm);
  }

  SignerInfo get signerInfo => SignerInfo(
      publicKey:
          CosmosPublicKey.fromBytes(keyBytes: publicKey, algorithm: algorithm).toAny(),
      modeInfo: const ModeInfo(single: ModeInfoSingle(mode: SignMode.signModeDirect)),
      sequence: BigInt.zero);

  @override
  CosmosNewAddressParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index =>
        CosmosNewAddressParams(deriveIndex: index, coin: coin, algorithm: algorithm),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }
}
