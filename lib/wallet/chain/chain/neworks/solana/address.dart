part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class ISolanaAddress extends ChainAccount<SolAddress, SolanaSPLToken, NFTCore,
    SolanaWalletTransaction, WalletSolanaNetwork> {
  ISolanaAddress._(
      {required super.derivationIndex,
      required super.database,
      required super.coin,
      required super.address,
      required super.network,
      required super.networkAddress,
      required super.identifier,
      required super.id});

  factory ISolanaAddress._newAccount({
    required List<int> publicKey,
    required WalletSolanaNetwork network,
    required DerivationIndex derivationIndex,
    required IAppDatabaseApi? database,
    required SolAddress address,
    required String identifier,
    required CryptoCoins coin,
    required String? id,
  }) {
    return ISolanaAddress._(
        coin: coin,
        address: address.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: address,
        network: network,
        identifier: identifier,
        id: id);
  }

  factory ISolanaAddress.deserialize(
      {required WalletSolanaNetwork network,
      required String? id,
      required IAppDatabaseApi? database,
      List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.solAccount);
    final CryptoCoins coin = CoinsUtils.getSerializationCoin(values.rawValueAt(0));
    final derivationIndex =
        DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1));
    final SolAddress solAddress =
        SolAddress.deserializeIAddress(bytes: values.rawValueAt(2));
    final int networkId = values.rawValueAt(3);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final String identifier = values.rawValueAt(4);
    return ISolanaAddress._(
        coin: coin,
        address: solAddress.address,
        derivationIndex: derivationIndex,
        database: database,
        networkAddress: solAddress,
        network: network,
        identifier: identifier,
        id: id);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.solAccount;
  @override
  List<CborObject?> get serializationItems => [
        coin.identifier.toCbor(),
        derivationIndex.toCbor(),
        CborBytesValue(networkAddress.encodeAsIAddress()),
        network.value.toCbor(),
        identifier.toCbor()
      ];
  @override
  List get variables {
    return [derivationIndex, network.value];
  }

  List<int> get publicKey => networkAddress.toBytes();

  @override
  String? get type => null;

  SolAddress associatedTokenAccount(
          {required SolAddress mint,
          SolAddress tokenProgramId = SPLTokenProgramConst.tokenProgramId}) =>
      AssociatedTokenAccountProgramUtils.associatedTokenAccount(
              mint: mint, owner: networkAddress, tokenProgramId: tokenProgramId)
          .address;

  @override
  SolanaNewAddressParams toAccountParams() {
    return switch (derivationIndex) {
      DerivableIndex index => SolanaNewAddressParams(deriveIndex: index, coin: coin),
      _ => throw AppCryptoExceptionConst.invalidDerivationKey
    };
  }
}
