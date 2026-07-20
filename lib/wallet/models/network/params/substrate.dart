import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateNetworkParams extends NetworkCoinParams {
  final int ss58Format;
  final int specVersion;
  final String? gnesisBlock;
  final SubstrateChainType substrateChainType;
  final List<SubstrateKeyAlgorithm> keyAlgorithms;
  final SubstrateRelaySystem? relaySystem;
  final SubstrateConsensusRole? consensusRole;
  bool get assetTransferEnabled => true;
  bool get xcmTransferEnabled => relaySystem != null && consensusRole != null;
  bool get allowMultisig => true;
  factory SubstrateNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NetworkType.substrate.identifier);

    return SubstrateNetworkParams(
      token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
      chainType: ChainType.fromValue(values.rawValueAt(1)),
      ss58Format: values.rawValueAt(2),
      substrateChainType: SubstrateChainType.fromValue(values.rawValueAt(3)),
      gnesisBlock: values.rawValueAt(4),
      bip32CoinType: values.rawValueAt(5),
      addressExplorer: values.rawValueAt(6),
      transactionExplorer: values.rawValueAt(7),
      keyAlgorithms: values
          .listAt<CborIntValue>(8)
          .map((e) => SubstrateKeyAlgorithm.fromValue(e.value))
          .toList(),
      specVersion: values.rawValueAt(9),
      relaySystem: values.maybeObjectAt<SubstrateRelaySystem, CborIntValue>(
          10, (value) => SubstrateRelaySystem.fromValue(value.value)),
      consensusRole: values.maybeObjectAt<SubstrateConsensusRole, CborIntValue>(
          11, (value) => SubstrateConsensusRole.fromValue(value.value)),
    );
  }
  const SubstrateNetworkParams(
      {required super.token,
      required super.chainType,
      required this.ss58Format,
      required this.specVersion,
      required this.relaySystem,
      required this.consensusRole,
      // this.chainId,
      this.gnesisBlock,
      required this.substrateChainType,
      super.bip32CoinType,
      super.addressExplorer,
      super.transactionExplorer,
      this.keyAlgorithms = const [
        SubstrateKeyAlgorithm.ecdsa,
        SubstrateKeyAlgorithm.sr25519,
        SubstrateKeyAlgorithm.ed25519
      ]});

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return SubstrateNetworkParams(
      token:
          NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
      addressExplorer: addressExplorer,
      transactionExplorer: transactionExplorer,
      chainType: chainType,
      ss58Format: ss58Format,
      gnesisBlock: gnesisBlock,
      substrateChainType: substrateChainType,
      bip32CoinType: bip32CoinType,
      keyAlgorithms: keyAlgorithms,
      specVersion: specVersion,
      consensusRole: consensusRole,
      relaySystem: relaySystem,
    );
  }

  SubstrateNetworkParams updateSpecVersion(int specVersion) {
    if (specVersion.isNegative || specVersion < this.specVersion) {
      throw WalletException.message("invalid_spec_version");
    }
    return SubstrateNetworkParams(
        token: token,
        chainType: chainType,
        ss58Format: ss58Format,
        specVersion: specVersion,
        substrateChainType: substrateChainType,
        addressExplorer: addressExplorer,
        bip32CoinType: bip32CoinType,
        gnesisBlock: gnesisBlock,
        keyAlgorithms: keyAlgorithms,
        transactionExplorer: transactionExplorer,
        relaySystem: relaySystem,
        consensusRole: consensusRole);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.substrate.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        ss58Format.toCbor(),
        substrateChainType.value.toCbor(),
        gnesisBlock?.toCbor(),
        bip32CoinType?.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor(),
        AppSerialization.listFromObjects(
            keyAlgorithms.map((e) => e.value.toCbor()).toList()),
        specVersion.toCbor(),
        relaySystem?.value.toCbor(),
        consensusRole?.value.toCbor(),
      ];
}
