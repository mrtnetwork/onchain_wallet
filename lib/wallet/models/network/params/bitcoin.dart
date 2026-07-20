import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class BitcoinParams extends NetworkCoinParams {
  final BasedUtxoNetwork transacationNetwork;
  bool get isBCH => transacationNetwork is BitcoinCashNetwork;
  bool get isForked => isBCH || transacationNetwork is BitcoinSVNetwork;

  factory BitcoinParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NetworkType.bitcoinAndForked.identifier);
    final txNetwork = BasedUtxoNetwork.fromTag(values.rawValueAt(1));
    return BitcoinParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        transacationNetwork: txNetwork,
        addressExplorer: values.rawValueAt(2),
        transactionExplorer: values.rawValueAt(3),
        chainType: txNetwork.isMainnet ? ChainType.mainnet : ChainType.testnet);
  }
  const BitcoinParams({
    required super.token,
    required this.transacationNetwork,
    required super.chainType,
    super.addressExplorer,
    super.transactionExplorer,
  });

  @override
  SerializationIdentifier get serializationIdentifier =>
      NetworkType.bitcoinAndForked.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        transacationNetwork.tag.toCbor(),
        addressExplorer?.toCbor(),
        transactionExplorer?.toCbor(),
      ];

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return BitcoinParams(
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        addressExplorer: addressExplorer,
        transactionExplorer: transactionExplorer,
        transacationNetwork: transacationNetwork,
        chainType: chainType);
  }

  @override
  int get averageBlockTime {
    return switch (transacationNetwork) {
      BitcoinCashNetwork.mainnet ||
      BitcoinCashNetwork.testnet ||
      LitecoinNetwork.mainnet ||
      LitecoinNetwork.testnet =>
        150,
      DashNetwork.testnet => 60,
      _ => 8 * 60
    };
  }

  bool get rbfSupport {
    return switch (transacationNetwork) {
      BitcoinNetwork.mainnet ||
      BitcoinNetwork.testnet ||
      BitcoinNetwork.testnet4 ||
      LitecoinNetwork.mainnet ||
      LitecoinNetwork.testnet =>
        true,
      _ => false
    };
  }

  int? get maxMemoLength {
    return switch (transacationNetwork) {
      BitcoinCashNetwork.mainnet || BitcoinCashNetwork.testnet => 223,
      BitcoinSVNetwork.mainnet || BitcoinSVNetwork.testnet => null,
      _ => 80
    };
  }

  bool get supportMultipleOpReturn {
    return switch (transacationNetwork) {
      BitcoinCashNetwork.mainnet ||
      BitcoinCashNetwork.testnet ||
      BitcoinSVNetwork.mainnet ||
      BitcoinSVNetwork.testnet =>
        true,
      _ => false
    };
  }

  @override
  int get maxTxConfirmationBlock => 10;
}
