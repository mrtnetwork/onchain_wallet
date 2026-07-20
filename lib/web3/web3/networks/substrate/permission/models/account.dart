import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class Web3SubstrateChainAccount extends Web3ChainAccount<BaseSubstrateAddress> {
  @override
  final int id;
  final List<int> publicKey;
  Web3SubstrateChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required super.identifier,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;
  @override
  Web3SubstrateChainAccount clone({
    DerivationIndex? derivationIndex,
    BaseSubstrateAddress? address,
    bool? defaultAddress,
    int? id,
    List<int>? publicKey,
    String? identifier,
  }) {
    return Web3SubstrateChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  factory Web3SubstrateChainAccount.fromChainAccount(
      {required ISubstrateAddress address, required int id, required bool isDefault}) {
    return Web3SubstrateChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.publicKey,
        identifier: address.identifier);
  }

  factory Web3SubstrateChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3SubstrateAccount);
    return Web3SubstrateChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: BaseSubstrateAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5));
  }

  @override
  String get addressStr => address.toString();

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3SubstrateAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        publicKey.toCborBytes(),
        identifier.toCbor()
      ];
}

class Web3SubstrateChainIdnetifier extends Web3ChainIdnetifier {
  final String genesisHash;
  final int specVersion;
  final SubstrateChainType type;
  final int ss58Fromat;
  Web3SubstrateChainIdnetifier(
      {required String genesisHash,
      required this.specVersion,
      required super.id,
      required super.wsIdentifier,
      required super.caip2,
      required this.type,
      required this.ss58Fromat})
      : genesisHash = StringUtils.add0x(genesisHash);
  factory Web3SubstrateChainIdnetifier.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3SubstrateChainIdentifier);
    return Web3SubstrateChainIdnetifier(
        genesisHash: values.rawValueAt(0),
        specVersion: values.rawValueAt(1),
        id: values.rawValueAt(2),
        wsIdentifier: values.rawValueAt(3),
        caip2: values.rawValueAt(4),
        type: SubstrateChainType.fromValue(values.rawValueAt(5)),
        ss58Fromat: values.rawValueAt(6));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3SubstrateChainIdentifier;

  @override
  List<CborObject?> get serializationItems => [
        genesisHash.toCbor(),
        specVersion.toCbor(),
        id.toCbor(),
        wsIdentifier.toCbor(),
        caip2.toCbor(),
        type.value.toCbor(),
        ss58Fromat.toCbor()
      ];
}

class Web3SubstrateChainAuthenticated
    extends Web3ChainAuthenticated<Web3SubstrateChainAccount> {
  @override
  final List<Web3SubstrateChainIdnetifier> networks;
  @override
  final Web3SubstrateChainIdnetifier currentNetwork;
  Web3SubstrateChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3SubstrateChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.substrate);

  factory Web3SubstrateChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: NetworkType.substrate.identifier);
    return Web3SubstrateChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3SubstrateChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3SubstrateChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork: Web3SubstrateChainIdnetifier.deserialize(
          object: values.objectAt<CborTagValue>(2)),
    );
  }
}
