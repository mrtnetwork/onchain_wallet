import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/params/solana.dart'
    show SolanaNetworkType;
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3SolanaChainAccount extends Web3ChainAccount<SolAddress> {
  @override
  final int id;
  Web3SolanaChainAccount({
    required super.derivationIndex,
    required super.address,
    required super.defaultAddress,
    required this.id,
    required super.identifier,
  });
  @override
  Web3SolanaChainAccount clone(
      {DerivationIndex? derivationIndex,
      SolAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      String? identifier}) {
    return Web3SolanaChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        identifier: identifier ?? this.identifier);
  }

  factory Web3SolanaChainAccount.fromChainAccount(
      {required ISolanaAddress address,
      required int id,
      required SolanaNetworkType network,
      required bool isDefault}) {
    return Web3SolanaChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        identifier: address.identifier);
  }

  factory Web3SolanaChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3SolanaAccount);
    return Web3SolanaChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: SolAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        identifier: values.rawValueAt(4));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3SolanaAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        identifier.toCbor()
      ];
}

class Web3SolanaChainAuthenticated
    extends Web3ChainAuthenticated<Web3SolanaChainAccount> {
  @override
  final List<Web3ChainDefaultIdnetifier> networks;
  @override
  final Web3ChainDefaultIdnetifier currentNetwork;
  Web3SolanaChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ChainDefaultIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.solana);
  // factory Web3SolanaChainAuthenticated.defaultAuth() {}
  factory Web3SolanaChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.solana.identifier);
    return Web3SolanaChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3SolanaChainAccount.deserialize(object: e))
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
