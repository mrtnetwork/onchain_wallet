import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:zcash_dart/zcash.dart'
    show DefaultUpgradeActivationProvider, ZcashNetworkProtocol;

class ZcashNetworkParams extends NetworkCoinParams {
  final ZcashNetwork network;
  const ZcashNetworkParams(
      {required super.token,
      required super.chainType,
      required this.network,
      super.addressExplorer,
      super.transactionExplorer});
  factory ZcashNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.zcash.identifier);

    return ZcashNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt<int>(1)),
        addressExplorer: values.rawValueAt(2),
        transactionExplorer: values.rawValueAt(3),
        network: ZcashNetwork.fromValue(values.rawValueAt(4)));
  }
  String get web3ChainIdentifier {
    return network.name.toLowerCase();
  }

  @override
  ZcashNetworkParams updateParams({
    Token? token,
    String? transactionExplorer,
    String? addressExplorer,
    int? bip32CoinType,
  }) {
    return ZcashNetworkParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer,
        chainType: chainType,
        network: network);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.zcash.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor(),
        network.value.toCbor(),
      ];

  @override
  int get averageBlockTime => 20;
  @override
  int get maxTxConfirmationBlock => 5;

  int get syncingBlockInterval => 90;

  int getNu6ActiveHeight() {
    if (network == ZcashNetwork.regtest) return 1;
    final activationProvider = DefaultUpgradeActivationProvider();
    return activationProvider.activationHeight(ZcashNetworkProtocol.nu6, network);
  }
}
