import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3StellarChainAccount extends Web3ChainAccount<StellarAddress> {
  @override
  final int id;
  final List<int> publicKey;
  // final StellarChainType network;
  Web3StellarChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required super.identifier,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;
  @override
  Web3StellarChainAccount clone({
    DerivationIndex? derivationIndex,
    StellarAddress? address,
    bool? defaultAddress,
    int? id,
    List<int>? publicKey,
    StellarChainType? network,
    String? identifier,
  }) {
    return Web3StellarChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3StellarChainAccount.fromChainAccount(
      {required IStellarAddress address,
      required int id,
      required bool isDefault,
      required StellarChainType network}) {
    return Web3StellarChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.publicKey,
        identifier: address.identifier);
  }

  factory Web3StellarChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3StellarAccount);
    return Web3StellarChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: StellarAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3StellarAccount;

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

class Web3StellarChainAuthenticated
    extends Web3ChainAuthenticated<Web3StellarChainAccount> {
  @override
  final List<Web3ChainDefaultIdnetifier> networks;
  @override
  final Web3ChainDefaultIdnetifier currentNetwork;
  Web3StellarChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ChainDefaultIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.stellar);

  factory Web3StellarChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.stellar.identifier);
    return Web3StellarChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3StellarChainAccount.deserialize(object: e))
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
