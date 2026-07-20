import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3MoneroChainAccount extends Web3ChainAccount<MoneroAddress> {
  @override
  final int id;
  final List<int>? publicKey;
  Web3MoneroChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required super.identifier,
      this.publicKey});
  @override
  Web3MoneroChainAccount clone(
      {DerivationIndex? derivationIndex,
      MoneroAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      String? identifier}) {
    return Web3MoneroChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3MoneroChainAccount.fromChainAccount(
      {required IMoneroAddress address, required int id, required bool isDefault}) {
    return Web3MoneroChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        identifier: address.identifier,
        publicKey: address.index.isPrimary ? address.networkAddress.pubSpendKey : null);
  }

  factory Web3MoneroChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3MoneroAccount);
    return Web3MoneroChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: MoneroAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3MoneroAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        publicKey?.toCborBytes(),
        identifier.toCbor()
      ];
}

class Web3MoneroChainIdnetifier extends Web3ChainIdnetifier {
  final MoneroNetwork network;

  Web3MoneroChainIdnetifier(
      {required this.network,
      required super.wsIdentifier,
      required super.caip2,
      required super.id});
  factory Web3MoneroChainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3MoneroChainIdentifier);
    return Web3MoneroChainIdnetifier(
        network: MoneroNetwork.fromValue(values.rawValueAt(0)),
        id: values.rawValueAt(1),
        wsIdentifier: values.rawValueAt(2),
        caip2: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3MoneroChainIdentifier;

  @override
  List<CborObject?> get serializationItems =>
      [network.index.toCbor(), id.toCbor(), wsIdentifier.toCbor(), caip2.toCbor()];
}

class Web3MoneroChainAuthenticated
    extends Web3ChainAuthenticated<Web3MoneroChainAccount> {
  @override
  final List<Web3MoneroChainIdnetifier> networks;
  @override
  final Web3MoneroChainIdnetifier currentNetwork;
  Web3MoneroChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3MoneroChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.monero);

  factory Web3MoneroChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.monero.identifier);
    return Web3MoneroChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3MoneroChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3MoneroChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork:
          Web3MoneroChainIdnetifier.deserialize(object: values.objectAt<CborTagValue>(2)),
    );
  }
}
