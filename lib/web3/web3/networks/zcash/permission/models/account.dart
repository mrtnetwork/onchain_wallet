import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:zcash_dart/zcash.dart';

class Web3ZcashChainAccount extends Web3ChainAccount<ZcashAddress> {
  @override
  final int id;

  Web3ZcashChainAccount({
    required super.derivationIndex,
    required super.address,
    required super.defaultAddress,
    required this.id,
    required super.identifier,
  });
  @override
  Web3ZcashChainAccount clone(
      {DerivationIndex? derivationIndex,
      ZcashAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      String? identifier}) {
    return Web3ZcashChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        identifier: identifier ?? this.identifier);
  }

  factory Web3ZcashChainAccount.fromChainAccount(
      {required IZcashAddress address, required int id, required bool isDefault}) {
    return Web3ZcashChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        identifier: address.identifier);
  }

  factory Web3ZcashChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3ZcashAccount);
    return Web3ZcashChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: ZcashAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        identifier: values.rawValueAt(4));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3ZcashAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        identifier.toCbor()
      ];
}

class Web3ZcashChainIdnetifier extends Web3ChainIdnetifier {
  final ZcashNetwork network;

  // factory Web3ZcashChainIdnetifier.from(WalletZcashNetwork network) {
  //   return Web3ZcashChainIdnetifier(
  //       id: network.value,
  //       wsIdentifier: network.wsIdentifier,
  //       caip2: network.caip,
  //       network: network.zcashNetwork);
  // }

  Web3ZcashChainIdnetifier(
      {required this.network,
      required super.wsIdentifier,
      required super.caip2,
      required super.id});
  factory Web3ZcashChainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3ZcashChainIdentifier);
    return Web3ZcashChainIdnetifier(
        network: ZcashNetwork.fromValue(values.rawValueAt(0)),
        id: values.rawValueAt(1),
        wsIdentifier: values.rawValueAt(2),
        caip2: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3ZcashChainIdentifier;

  @override
  List<CborObject?> get serializationItems =>
      [network.value.toCbor(), id.toCbor(), wsIdentifier.toCbor(), caip2.toCbor()];
}

class Web3ZcashChainAuthenticated extends Web3ChainAuthenticated<Web3ZcashChainAccount> {
  @override
  final List<Web3ZcashChainIdnetifier> networks;
  @override
  final Web3ZcashChainIdnetifier currentNetwork;
  Web3ZcashChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ZcashChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.zcash);

  factory Web3ZcashChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.zcash.identifier);
    return Web3ZcashChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3ZcashChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3ZcashChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork:
          Web3ZcashChainIdnetifier.deserialize(object: values.objectAt<CborTagValue>(2)),
    );
  }
}
