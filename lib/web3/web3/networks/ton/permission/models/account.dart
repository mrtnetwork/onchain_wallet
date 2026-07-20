import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3TonChainAccount extends Web3ChainAccount<TonAddress> {
  @override
  final int id;
  final List<int> accountState;
  final List<int> publicKey;
  final int maxMessageLength;

  Web3TonChainAccount._(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required List<int> publicKey,
      required this.accountState,
      required super.identifier,
      required this.maxMessageLength})
      : publicKey = publicKey.asImmutableBytes;
  @override
  Web3TonChainAccount clone(
      {DerivationIndex? derivationIndex,
      TonAddress? address,
      bool? defaultAddress,
      int? id,
      List<int>? publicKey,
      List<int>? accountState,
      String? identifier,
      int? maxMessageLength}) {
    return Web3TonChainAccount._(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        accountState: accountState ?? this.accountState,
        identifier: identifier ?? this.identifier,
        maxMessageLength: maxMessageLength ?? this.maxMessageLength);
  }

  factory Web3TonChainAccount.fromChainAccount(
      {required ITonAddress address, required int id, required bool isDefault}) {
    return Web3TonChainAccount._(
        derivationIndex: address.derivationIndex,
        address: address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        accountState: address.context
            .toWalletContract(address.publicKey)
            .state!
            .initialState()
            .serialize()
            .toBoc(),
        publicKey: address.publicKey,
        identifier: address.identifier,
        maxMessageLength: address.context.version.maxMessageLength);
  }

  factory Web3TonChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3TonAccount);
    return Web3TonChainAccount._(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: TonAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        accountState: values.rawValueAt(4),
        publicKey: values.rawValueAt(5),
        identifier: values.rawValueAt(6),
        maxMessageLength: values.rawValueAt(7));
  }

  @override
  String get addressStr => address.address;

  // List<int> get accountState =>
  //     accountState.toWalletContract(publicKey).state!.initialState().serialize().toBoc();

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3TonAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        accountState.toCborBytes(),
        CborBytesValue(publicKey),
        identifier.toCbor(),
        maxMessageLength.toCbor()
      ];
}

class Web3TonChainAuthenticated extends Web3ChainAuthenticated<Web3TonChainAccount> {
  @override
  final List<Web3ChainDefaultIdnetifier> networks;
  @override
  final Web3ChainDefaultIdnetifier currentNetwork;
  Web3TonChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ChainDefaultIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.ton);

  factory Web3TonChainAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.ton.identifier);
    return Web3TonChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3TonChainAccount.deserialize(object: e))
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
