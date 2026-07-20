import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3BitcoinChainAccount extends Web3ChainAccount<BitcoinNetworkAddress> {
  @override
  final int id;
  BitcoinAddressType get type => address.type;
  BasedUtxoNetwork get baseNetwork => address.network;
  final List<int> publicKey;
  final String? witnessScript;
  final String? redeemScript;

  Web3BitcoinChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required super.identifier,
      required this.id,
      required this.witnessScript,
      required this.redeemScript,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;

  @override
  Web3BitcoinChainAccount clone(
      {DerivationIndex? derivationIndex,
      BitcoinNetworkAddress? address,
      bool? defaultAddress,
      int? id,
      int? signingScheme,
      String? witnessScript,
      String? redeemScript,
      List<int>? publicKey,
      String? identifier}) {
    return Web3BitcoinChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        witnessScript: witnessScript ?? this.witnessScript,
        redeemScript: redeemScript ?? this.redeemScript,
        identifier: identifier ?? this.identifier);
  }

  factory Web3BitcoinChainAccount.fromChainAccount(
      {required IBitcoinAddress address,
      required bool isDefault,
      required WalletBitcoinNetwork network}) {
    return Web3BitcoinChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: network.value,
        defaultAddress: isDefault,
        publicKey: address.multiSigAccount ? [] : address.publicKey,
        witnessScript: address.witnessScript()?.toHex(),
        redeemScript: address.redeemScript()?.toHex(),
        identifier: address.identifier);
  }
  factory Web3BitcoinChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3BitcoinAccount);
    return Web3BitcoinChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: BitcoinNetworkAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        witnessScript: values.rawValueAt(5),
        redeemScript: values.rawValueAt(6),
        identifier: values.rawValueAt(7));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3BitcoinAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        CborIntValue(id),
        CborBoleanValue(defaultAddress),
        CborBytesValue(publicKey),
        witnessScript?.toCbor(),
        redeemScript?.toCbor(),
        identifier.toCbor()
      ];
}

class Web3BitcoinChainIdnetifier extends Web3ChainIdnetifier {
  final BasedUtxoNetwork network;

  Web3BitcoinChainIdnetifier(
      {required this.network,
      required super.wsIdentifier,
      required super.caip2,
      required super.id});

  factory Web3BitcoinChainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3BitcoinChainIdentifier);
    return Web3BitcoinChainIdnetifier(
        network: BasedUtxoNetwork.fromTag(values.rawValueAt(0)),
        id: values.rawValueAt(1),
        wsIdentifier: values.rawValueAt(2),
        caip2: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3BitcoinChainIdentifier;

  @override
  List<CborObject?> get serializationItems =>
      [network.tag.toCbor(), id.toCbor(), wsIdentifier.toCbor(), caip2.toCbor()];
}

class Web3BitcoinChainAuthenticated
    extends Web3ChainAuthenticated<Web3BitcoinChainAccount> {
  @override
  final List<Web3BitcoinChainIdnetifier> networks;
  @override
  final Web3BitcoinChainIdnetifier currentNetwork;
  Web3BitcoinChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3BitcoinChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.bitcoinAndForked);

  factory Web3BitcoinChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: NetworkType.bitcoinAndForked.identifier);
    return Web3BitcoinChainAuthenticated(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => Web3BitcoinChainAccount.deserialize(object: e))
            .toList(),
        networks: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3BitcoinChainIdnetifier.deserialize(object: e))
            .toList(),
        currentNetwork: Web3BitcoinChainIdnetifier.deserialize(
            object: values.objectAt<CborTagValue>(2)));
  }

  @override
  NetworkType get networkType => NetworkType.bitcoinAndForked;
}
