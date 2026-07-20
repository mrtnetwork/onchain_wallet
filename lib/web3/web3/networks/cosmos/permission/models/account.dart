import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3CosmosChainAccount extends Web3ChainAccount<CosmosBaseAddress> {
  @override
  final int id;
  final List<int> publicKey;
  final CosmosKeysAlgs algo;
  Web3CosmosChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required this.algo,
      required super.identifier,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;

  @override
  Web3CosmosChainAccount clone({
    DerivationIndex? derivationIndex,
    CosmosBaseAddress? address,
    bool? defaultAddress,
    int? id,
    CosmosKeysAlgs? algo,
    List<int>? publicKey,
    String? identifier,
  }) {
    return Web3CosmosChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        algo: algo ?? this.algo,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3CosmosChainAccount.fromChainAccount(
      {required ICosmosAddress address, required int id, required bool isDefault}) {
    return Web3CosmosChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.publicKey,
        algo: address.algorithm,
        identifier: address.identifier);
  }

  factory Web3CosmosChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3CosmosAccount);
    return Web3CosmosChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: CosmosBaseAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        algo: CosmosKeysAlgs.fromValue(values.rawValueAt(5)),
        identifier: values.rawValueAt(6));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3CosmosAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        CborBytesValue(publicKey),
        algo.value.toCbor(),
        identifier.toCbor()
      ];
}

class Web3CosmoshainIdnetifier extends Web3ChainIdnetifier {
  final String chainId;
  final String hrp;

  Web3CosmoshainIdnetifier(
      {required this.chainId,
      required super.wsIdentifier,
      required super.caip2,
      required super.id,
      required this.hrp});
  factory Web3CosmoshainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3CosmosChainIdentifier);
    return Web3CosmoshainIdnetifier(
        chainId: values.rawValueAt(0),
        id: values.rawValueAt(1),
        wsIdentifier: values.rawValueAt(2),
        caip2: values.rawValueAt(3),
        hrp: values.rawValueAt(4));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3CosmosChainIdentifier;

  @override
  List<CborObject?> get serializationItems => [
        chainId.toCbor(),
        id.toCbor(),
        wsIdentifier.toCbor(),
        caip2.toCbor(),
        hrp.toCbor()
      ];
}

class Web3CosmosChainAuthenticated
    extends Web3ChainAuthenticated<Web3CosmosChainAccount> {
  @override
  final List<Web3CosmoshainIdnetifier> networks;
  @override
  final Web3CosmoshainIdnetifier currentNetwork;
  Web3CosmosChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3CosmoshainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.cosmos);

  factory Web3CosmosChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.cosmos.identifier);
    return Web3CosmosChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3CosmosChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3CosmoshainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork:
          Web3CosmoshainIdnetifier.deserialize(object: values.objectAt<CborTagValue>(2)),
    );
  }
}
