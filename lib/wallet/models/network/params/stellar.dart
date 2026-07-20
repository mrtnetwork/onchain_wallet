import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:stellar_dart/stellar_dart.dart';

enum StellarChainType {
  testnet(1),
  pubnet(2);

  const StellarChainType(this.value);
  final int value;
  String get identifier => "stellar:$name";
  static StellarChainType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("StellarChainType"),
    );
  }

  List<int> get passphraseHash {
    return switch (this) {
      testnet => StellarNetwork.testnet.passphraseHash,
      pubnet => StellarNetwork.mainnet.passphraseHash
    };
  }

  String get passphrase {
    return switch (this) {
      testnet => StellarNetwork.testnet.passphrase,
      pubnet => StellarNetwork.mainnet.passphrase
    };
  }
}

class StellarNetworkParams extends NetworkCoinParams {
  final StellarChainType stellarChainType;

  factory StellarNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.stellar.identifier);

    return StellarNetworkParams(
      token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
      chainType: ChainType.fromValue(values.rawValueAt(1)),
      addressExplorer: values.rawValueAt(2),
      transactionExplorer: values.rawValueAt(3),
      stellarChainType: StellarChainType.fromValue(values.rawValueAt(4)),
    );
  }
  const StellarNetworkParams(
      {required super.token,
      required super.chainType,
      required this.stellarChainType,
      super.addressExplorer,
      super.transactionExplorer});

  StellarNetworkParams copyWith(
      {ChainType? chainType,
      String? transactionExplorer,
      String? addressExplorer,
      Token? token,
      StellarChainType? stellarChainType}) {
    return StellarNetworkParams(
        chainType: chainType ?? this.chainType,
        token: token ?? this.token,
        stellarChainType: stellarChainType ?? this.stellarChainType);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.stellar.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor(),
        stellarChainType.value.toCbor()
      ];
  StellarChainType get identifier => stellarChainType;

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return StellarNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        stellarChainType: stellarChainType,
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer);
  }
}
