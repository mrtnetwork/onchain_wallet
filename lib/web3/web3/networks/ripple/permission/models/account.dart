import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class Web3XRPChainAccount extends Web3ChainAccount<XRPBaseAddress> {
  @override
  final int id;
  final List<int>? publicKey;
  Web3XRPChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required super.identifier,
      this.publicKey});
  @override
  Web3XRPChainAccount clone({
    DerivationIndex? derivationIndex,
    XRPBaseAddress? address,
    bool? defaultAddress,
    int? id,
    List<int>? publicKey,
    String? identifier,
  }) {
    return Web3XRPChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3XRPChainAccount.fromChainAccount(
      {required IXRPAddress address, required int id, required bool isDefault}) {
    return Web3XRPChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.toXrplPublicKeyBytes(),
        identifier: address.identifier);
  }

  factory Web3XRPChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3XRPAccount);
    return Web3XRPChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: XRPBaseAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5));
  }

  @override
  String get addressStr => address.classicAddress;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3XRPAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.toClassicAddress().encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        publicKey?.toCborBytes(),
        identifier.toCbor()
      ];
}

class Web3XRPChainAuthenticated extends Web3ChainAuthenticated<Web3XRPChainAccount> {
  @override
  final List<Web3ChainDefaultIdnetifier> networks;
  @override
  final Web3ChainDefaultIdnetifier currentNetwork;
  Web3XRPChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ChainDefaultIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.xrpl);

  factory Web3XRPChainAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.xrpl.identifier);
    return Web3XRPChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3XRPChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3ChainDefaultIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork: Web3ChainDefaultIdnetifier.deserialize(
          object: values.objectAt<CborTagValue>(2)),
    );
  }
}
