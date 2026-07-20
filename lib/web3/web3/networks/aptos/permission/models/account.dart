import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/params/aptos.dart'
    show AptosChainType;
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3AptosChainAccount extends Web3ChainAccount<AptosAddress> {
  @override
  final int id;
  final List<int> publicKey;
  final int signingScheme;

  String get publicKeyHex {
    return BytesUtils.toHexString(publicKey, prefix: '0x');
  }

  Web3AptosChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required super.identifier,
      required this.id,
      required this.signingScheme,
      required List<int> publicKey})
      : publicKey = publicKey.asImmutableBytes;
  factory Web3AptosChainAccount.fromChainAccount({
    required IAptosAddress address,
    required int id,
    required bool isDefault,
    required AptosChainType network,
  }) {
    return Web3AptosChainAccount(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: address.aptosPublicKey().toBytes(),
        signingScheme: address.keyScheme.toSigningScheme.value,
        identifier: address.identifier);
  }

  factory Web3AptosChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3AptosAccount);
    return Web3AptosChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: AptosAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        signingScheme: values.rawValueAt(5),
        identifier: values.rawValueAt(6));
  }

  @override
  String get addressStr => address.address;

  @override
  Web3AptosChainAccount clone(
      {DerivationIndex? derivationIndex,
      AptosAddress? address,
      bool? defaultAddress,
      int? id,
      int? signingScheme,
      AptosChainType? network,
      List<int>? publicKey,
      String? identifier}) {
    return Web3AptosChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        signingScheme: signingScheme ?? this.signingScheme,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3AptosAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        CborIntValue(id),
        CborBoleanValue(defaultAddress),
        CborBytesValue(publicKey),
        CborIntValue(signingScheme),
        CborStringValue(identifier)
      ];
}

class Web3AptosChainIdnetifier extends Web3ChainIdnetifier {
  final int? chainId;
  late final AptosChainType aptosChain = AptosChainType.fromValue(chainId);

  Web3AptosChainIdnetifier(
      {required this.chainId,
      required super.wsIdentifier,
      required super.caip2,
      required super.id});
  factory Web3AptosChainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3AptosChainIdentifier);
    return Web3AptosChainIdnetifier(
        chainId: values.rawValueAt(0),
        id: values.rawValueAt(1),
        wsIdentifier: values.rawValueAt(2),
        caip2: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3AptosChainIdentifier;

  @override
  List<CborObject?> get serializationItems =>
      [chainId?.toCbor(), id.toCbor(), wsIdentifier.toCbor(), caip2.toCbor()];
}

class Web3AptosChainAuthenticated extends Web3ChainAuthenticated<Web3AptosChainAccount> {
  @override
  final List<Web3AptosChainIdnetifier> networks;
  @override
  final Web3AptosChainIdnetifier currentNetwork;
  Web3AptosChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3AptosChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.aptos);

  factory Web3AptosChainAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.aptos.identifier);
    return Web3AptosChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3AptosChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3AptosChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork:
          Web3AptosChainIdnetifier.deserialize(object: values.objectAt<CborTagValue>(2)),
    );
  }

  @override
  NetworkType get networkType => NetworkType.aptos;
}
