part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

final class TronNewAddressParams extends NewDerivableAccountParams<ITronAddress> {
  @override
  final DerivableIndex deriveIndex;
  @override
  final CryptoCoins coin;
  TronNewAddressParams._({required this.deriveIndex, required this.coin});
  factory TronNewAddressParams(
      {required DerivableIndex deriveIndex, required CryptoCoins coin}) {
    return TronNewAddressParams._(deriveIndex: deriveIndex, coin: coin);
  }
  factory TronNewAddressParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.tronNewAddressParams.tag);
    return TronNewAddressParams(
      deriveIndex: DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(1)),
    );
  }
  @override
  ITronAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    if (network is! WalletTronNetwork) {
      throw WalletExceptionConst.invalidAccountData("TronNewAddressParams.toAccount");
    }
    final keyBytes = publicKey.keyBytes(immutable: true);
    final address = TronAddress.fromPublicKey(keyBytes);
    return ITronAddress._newAccount(
        publicKey: keyBytes,
        network: network,
        address: address,
        database: database,
        derivationIndex: deriveIndex,
        coin: coin,
        identifier: NewAccountParams.toIdentifier(address.toAddress()),
        id: id);
  }

  @override
  List<CborObject?> get serializationItems =>
      [deriveIndex.toCbor(), coin.identifier.toCbor()];
  @override
  NewAccountParamsType get type => NewAccountParamsType.tronNewAddressParams;
}

final class TronMultisigNewAddressParams extends NewAccountParams<ITronAddress> {
  TronMultisigNewAddressParams._(
      {required this.multiSigAccount, required this.masterAddress, required this.coin});
  factory TronMultisigNewAddressParams(
      {required TronMultiSignatureAddress multiSigAccount,
      required TronAddress masterAddress,
      required CryptoCoins coin}) {
    return TronMultisigNewAddressParams._(
        multiSigAccount: multiSigAccount, masterAddress: masterAddress, coin: coin);
  }

  final TronAddress masterAddress;

  final TronMultiSignatureAddress multiSigAccount;
  @override
  final CryptoCoins coin;

  factory TronMultisigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NewAccountParamsType.tronMultisigNewAddressParams.tag);
    return TronMultisigNewAddressParams(
      masterAddress: TronAddress(values.rawValueAt(0)),
      multiSigAccount:
          TronMultiSignatureAddress.deserialize(object: values.objectAt<CborTagValue>(1)),
      coin: CoinsUtils.getSerializationCoin(values.rawValueAt(2)),
    );
  }

  @override
  List<CborObject?> get serializationItems => [
        masterAddress.toAddress().toCbor(),
        multiSigAccount.toCbor(),
        coin.identifier.toCbor()
      ];
  @override
  ITronMultisigAddress toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey,
      String? id, IAppDatabaseApi? database) {
    if (network is! WalletTronNetwork) {
      throw WalletExceptionConst.invalidAccountData(
          "TronMultisigNewAddressParams.toAccount");
    }
    return ITronMultisigAddress._newAccount(
        address: masterAddress,
        coin: coin,
        database: database,
        identifier: NewAccountParams.toIdentifier(masterAddress.toAddress(),
            multisigAddress: multiSigAccount.toCbor().encode()),
        multiSigAccount: multiSigAccount,
        network: network,
        id: id);
  }

  @override
  NewAccountParamsType get type => NewAccountParamsType.tronMultisigNewAddressParams;
}
