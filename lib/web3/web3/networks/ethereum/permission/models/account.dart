import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain/ethereum/ethereum.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3EthereumChainAccount extends Web3ChainAccount<ETHAddress> {
  @override
  final int id;
  final List<int> publicKey;
  Web3EthereumChainAccount({
    required super.derivationIndex,
    required super.address,
    required super.defaultAddress,
    required this.id,
    required super.identifier,
    required List<int> publicKey,
  }) : publicKey = publicKey.asImmutableBytes;
  @override
  Web3EthereumChainAccount clone(
      {DerivationIndex? derivationIndex,
      ETHAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      String? identifier}) {
    return Web3EthereumChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3EthereumChainAccount.fromChainAccount(
      {required IEthereumAddress address, required int id, required bool isDefault}) {
    return Web3EthereumChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.publicKey,
        identifier: address.identifier);
  }

  factory Web3EthereumChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3EthereumAccount);
    return Web3EthereumChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: ETHAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3EthereumAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        CborBytesValue(publicKey),
        identifier.toCbor()
      ];
}

class Web3EthereumChainIdnetifier extends Web3ChainIdnetifier {
  final BigInt chainId;
  final bool supportEIP1559;
  Web3EthereumChainIdnetifier(
      {required this.chainId,
      required this.supportEIP1559,
      required super.wsIdentifier,
      required super.caip2,
      required super.id});
  factory Web3EthereumChainIdnetifier.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3EthereumChainIdentifier);
    return Web3EthereumChainIdnetifier(
        chainId: values.rawValueAt(0),
        supportEIP1559: values.rawValueAt(1),
        id: values.rawValueAt(2),
        wsIdentifier: values.rawValueAt(3),
        caip2: values.rawValueAt(4));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3EthereumChainIdentifier;

  @override
  List<CborObject?> get serializationItems => [
        chainId.toCbor(),
        supportEIP1559.toCbor(),
        id.toCbor(),
        wsIdentifier.toCbor(),
        caip2.toCbor()
      ];
}

class Web3EthereumChainAuthenticated
    extends Web3ChainAuthenticated<Web3EthereumChainAccount> {
  final DefaultAPIProvider? serviceIdentifier;
  @override
  final List<Web3EthereumChainIdnetifier> networks;
  @override
  final Web3EthereumChainIdnetifier currentNetwork;
  Web3EthereumChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required this.serviceIdentifier,
    required List<Web3EthereumChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.ethereum);

  factory Web3EthereumChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: NetworkType.ethereum.identifier);
    return Web3EthereumChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3EthereumChainAccount.deserialize(object: e))
          .toList(),
      serviceIdentifier: values.maybeObjectAt<DefaultAPIProvider, CborTagValue>(
          1, (p0) => DefaultAPIProvider.deserialize(object: p0)),
      networks: values
          .listAt<CborTagValue>(2)
          .map((e) => Web3EthereumChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork: Web3EthereumChainIdnetifier.deserialize(
          object: values.objectAt<CborTagValue>(3)),
    );
  }

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        serviceIdentifier?.toCbor(),
        AppSerialization.listFromObjects(networks.map((e) => e.toCbor()).toList()),
        currentNetwork.toCbor()
      ];
}
