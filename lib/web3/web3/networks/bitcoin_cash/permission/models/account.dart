import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/permission/models/account.dart';

class Web3BitcoinCashChainAccount extends Web3BitcoinChainAccount {
  Web3BitcoinCashChainAccount._(
      {required super.derivationIndex,
      required BitcoinCashAddress super.address,
      required super.defaultAddress,
      required super.identifier,
      required super.id,
      required super.witnessScript,
      required super.redeemScript,
      required super.publicKey});

  @override
  Web3BitcoinCashChainAccount clone(
      {DerivationIndex? derivationIndex,
      BitcoinNetworkAddress? address,
      bool? defaultAddress,
      int? id,
      int? signingScheme,
      String? witnessScript,
      String? redeemScript,
      BasedUtxoNetwork? baseNetwork,
      String? addressProgram,
      List<int>? publicKey,
      BitcoinAddressType? type,
      String? identifier}) {
    return Web3BitcoinCashChainAccount._(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address?.cast<BitcoinCashAddress>() ??
            this.address.cast<BitcoinCashAddress>(),
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        witnessScript: witnessScript ?? this.witnessScript,
        redeemScript: redeemScript ?? this.redeemScript,
        identifier: identifier ?? this.identifier);
  }

  factory Web3BitcoinCashChainAccount.fromChainAccount(
      {required IBitcoinCashAddress address,
      required bool isDefault,
      required WalletBitcoinCashNetwork network}) {
    return Web3BitcoinCashChainAccount._(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress.cast(),
        id: network.value,
        defaultAddress: isDefault,
        publicKey: address.multiSigAccount ? [] : address.publicKey,
        witnessScript: address.witnessScript()?.toHex(),
        redeemScript: address.redeemScript()?.toHex(),
        identifier: address.identifier);
  }

  factory Web3BitcoinCashChainAccount.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3BitcoinCashAccount);
    return Web3BitcoinCashChainAccount._(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address:
            BitcoinNetworkAddress.deserializeIAddress(bytes: values.rawValueAt(1)).cast(),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        witnessScript: values.rawValueAt(5),
        redeemScript: values.rawValueAt(6),
        identifier: values.rawValueAt(7));
  }

  String get wcStyle {
    return switch (baseNetwork) {
      BitcoinCashNetwork.mainnet ||
      BitcoinCashNetwork.testnet =>
        addressStr.split(":").last,
      _ => addressStr
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3BitcoinCashAccount;

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

class Web3BitcoinCashChainIdnetifier extends Web3BitcoinChainIdnetifier {
  Web3BitcoinCashChainIdnetifier(
      {required BitcoinCashNetwork super.network,
      required super.wsIdentifier,
      required super.caip2,
      required super.id});
  factory Web3BitcoinCashChainIdnetifier.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3BitcoinCashChainIdentifier);
    return Web3BitcoinCashChainIdnetifier(
        network: BasedUtxoNetwork.fromTag(values.rawValueAt(0)) as BitcoinCashNetwork,
        id: values.rawValueAt(1),
        wsIdentifier: values.rawValueAt(2),
        caip2: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3BitcoinCashChainIdentifier;

  @override
  List<CborObject?> get serializationItems =>
      [network.tag.toCbor(), id.toCbor(), wsIdentifier.toCbor(), caip2.toCbor()];
}

class Web3BitcoinCashChainAuthenticated
    extends Web3ChainAuthenticated<Web3BitcoinCashChainAccount> {
  @override
  final List<Web3BitcoinCashChainIdnetifier> networks;
  @override
  final Web3BitcoinCashChainIdnetifier currentNetwork;
  Web3BitcoinCashChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3BitcoinCashChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.bitcoinCash);

  factory Web3BitcoinCashChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: NetworkType.bitcoinCash.identifier);
    return Web3BitcoinCashChainAuthenticated(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => Web3BitcoinCashChainAccount.deserialize(object: e))
            .toList(),
        networks: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3BitcoinCashChainIdnetifier.deserialize(object: e))
            .toList(),
        currentNetwork: Web3BitcoinCashChainIdnetifier.deserialize(
            object: values.objectAt<CborTagValue>(2)));
  }

  @override
  NetworkType get networkType => NetworkType.bitcoinCash;
}
