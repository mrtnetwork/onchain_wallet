import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/params/sui.dart' show SuiChainType;
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain/sui/src/address/address/address.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3SuiChainAccount extends Web3ChainAccount<SuiAddress> {
  @override
  final int id;
  final List<int> publicKey;
  final int signingScheme;
  // final SuiChainType network;
  @override
  Web3SuiChainAccount clone(
      {DerivationIndex? derivationIndex,
      SuiAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      int? signingScheme,
      String? identifier}) {
    return Web3SuiChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        signingScheme: signingScheme ?? this.signingScheme,
        identifier: identifier ?? this.identifier);
  }

  Web3SuiChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required this.signingScheme,
      required super.identifier,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;
  factory Web3SuiChainAccount.fromChainAccount(
      {required ISuiAddress address,
      required int id,
      required bool isDefault,
      required SuiChainType network}) {
    return Web3SuiChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.toSuiPublicKey().toVariantBcs(),
        signingScheme: address.keyScheme.value,
        identifier: address.identifier);
  }

  factory Web3SuiChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3SuiAccount);
    return Web3SuiChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: SuiAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        signingScheme: values.rawValueAt(5),
        identifier: values.rawValueAt(6));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3SuiAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        CborBytesValue(publicKey),
        signingScheme.toCbor(),
        identifier.toCbor()
      ];
}

class Web3SuiChainAuthenticated extends Web3ChainAuthenticated<Web3SuiChainAccount> {
  @override
  final List<Web3ChainDefaultIdnetifier> networks;
  @override
  final Web3ChainDefaultIdnetifier currentNetwork;
  Web3SuiChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ChainDefaultIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.sui);

  factory Web3SuiChainAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.sui.identifier);
    return Web3SuiChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3SuiChainAccount.deserialize(object: e))
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
