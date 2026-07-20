import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';

class Web3TronChainAccount extends Web3ChainAccount<TronAddress> {
  @override
  final int id;
  final List<int>? publicKey;
  Web3TronChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required super.identifier,
      required List<int>? publicKey})
      : publicKey = publicKey?.asImmutableBytes;
  @override
  Web3TronChainAccount clone(
      {DerivationIndex? derivationIndex,
      TronAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      String? identifier}) {
    return Web3TronChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3TronChainAccount.fromChainAccount(
      {required ITronAddress address, required int id, required bool isDefault}) {
    return Web3TronChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.multiSigAccount ? null : address.publicKey,
        identifier: address.identifier);
  }

  factory Web3TronChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3TronAccount);
    return Web3TronChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: TronAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3TronAccount;

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

class Web3TronChainIdnetifier extends Web3ChainIdnetifier {
  final int chainId;
  final String solidityNode;
  final String fullNode;

  Web3TronChainIdnetifier(
      {required this.chainId,
      required super.id,
      required this.solidityNode,
      required this.fullNode,
      required super.wsIdentifier,
      required super.caip2});
  factory Web3TronChainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3TronChainIdentifier);
    return Web3TronChainIdnetifier(
        chainId: values.rawValueAt(0),
        id: values.rawValueAt(1),
        fullNode: values.rawValueAt(2),
        solidityNode: values.rawValueAt(3),
        wsIdentifier: values.rawValueAt(4),
        caip2: values.rawValueAt(5));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3TronChainIdentifier;

  @override
  List<CborObject?> get serializationItems => [
        chainId.toCbor(),
        id.toCbor(),
        fullNode.toCbor(),
        solidityNode.toCbor(),
        wsIdentifier.toCbor(),
        caip2.toCbor()
      ];
}

class Web3TronChainAuthenticated extends Web3ChainAuthenticated<Web3TronChainAccount> {
  @override
  final List<Web3TronChainIdnetifier> networks;
  @override
  final Web3TronChainIdnetifier currentNetwork;
  Web3TronChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3TronChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.tron);

  factory Web3TronChainAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.tron.identifier);
    return Web3TronChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3TronChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3TronChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork:
          Web3TronChainIdnetifier.deserialize(object: values.objectAt<CborTagValue>(2)),
    );
  }
}
