import 'package:blockchain_utils/networks/types/network.dart';
import 'package:on_chain_wallet/app/core.dart';

enum NetworkType {
  bitcoinAndForked(
    name: "Bitcoin",
    identifier: AppSerializationIdentifier.bitconNetwork,
    mainNetworkId: 0,
    id: 10000,
    caip2: "bip122",
    network: BlockchainNetwork.bitcoinAndRelated,
  ),
  bitcoinCash(
    name: "BitcoinCash",
    identifier: AppSerializationIdentifier.bitcoinCashNetwork,
    mainNetworkId: 0,
    id: 10001,
    caip2: "bch",
    network: BlockchainNetwork.bitcoinAndRelated,
  ),
  xrpl(
    name: "XRPL",
    identifier: AppSerializationIdentifier.xrpNetwork,
    mainNetworkId: 30,
    id: 10002,
    caip2: "xrpl",
    network: BlockchainNetwork.xrpl,
  ),
  ethereum(
    name: "Ethereum",
    identifier: AppSerializationIdentifier.evmNetwork,
    mainNetworkId: 100,
    id: 10003,
    caip2: 'eip155',
    network: BlockchainNetwork.ethereum,
  ),

  tron(
    name: "Tron",
    identifier: AppSerializationIdentifier.tvmNetwork,
    mainNetworkId: 1001,
    id: 10004,
    caip2: 'tron',
    network: BlockchainNetwork.tron,
  ),

  solana(
    name: "Solana",
    identifier: AppSerializationIdentifier.solanaNetwork,
    mainNetworkId: 33,
    id: 10005,
    caip2: 'solana',
    network: BlockchainNetwork.solana,
  ),
  cardano(
    name: "Cardano",
    identifier: AppSerializationIdentifier.cardanoNetwork,
    mainNetworkId: 50,
    id: 10006,
    caip2: 'cip34',
    network: BlockchainNetwork.cardano,
  ),

  ton(
    name: "TON",
    identifier: AppSerializationIdentifier.tonNetwork,
    mainNetworkId: 300,
    id: 10008,
    caip2: 'tvm',
    network: BlockchainNetwork.ton,
  ),
  cosmos(
    name: "Cosmos",
    identifier: AppSerializationIdentifier.cosmosNetwork,
    mainNetworkId: 200,
    id: 10007,
    caip2: 'cosmos',
    network: BlockchainNetwork.cosmosAndRelated,
  ),

  substrate(
    name: "Substrate",
    identifier: AppSerializationIdentifier.substrateNetwork,
    mainNetworkId: 400,
    id: 10009,
    caip2: 'polkadot',
    network: BlockchainNetwork.substrateAndRelated,
  ),
  stellar(
    name: "Stellar",
    identifier: AppSerializationIdentifier.stellar,
    mainNetworkId: 600,
    id: 10010,
    caip2: 'stellar',
    network: BlockchainNetwork.stellar,
  ),
  monero(
    name: "Monero",
    identifier: AppSerializationIdentifier.monero,
    mainNetworkId: 700,
    id: 10011,
    caip2: 'monero',
    network: BlockchainNetwork.monero,
  ),
  aptos(
    name: "Aptos",
    identifier: AppSerializationIdentifier.aptos,
    mainNetworkId: 810,
    id: 10012,
    caip2: 'aptos',
    network: BlockchainNetwork.aptos,
  ),

  sui(
    name: "Sui",
    identifier: AppSerializationIdentifier.sui,
    mainNetworkId: 800,
    id: 10013,
    caip2: 'sui',
    network: BlockchainNetwork.sui,
  ),
  zcash(
      name: "Zcash",
      identifier: AppSerializationIdentifier.zcash,
      mainNetworkId: 900,
      id: 10014,
      network: BlockchainNetwork.zcash,
      caip2: 'zcash');

  final String name;
  final AppSerializationIdentifier identifier;
  final int mainNetworkId;
  final int id;
  final String caip2;
  final BlockchainNetwork network;
  // static const int tagLength = 3;
  bool get isBitcoin =>
      this == NetworkType.bitcoinAndForked || this == NetworkType.bitcoinCash;

  const NetworkType({
    required this.name,
    required this.identifier,
    required this.mainNetworkId,
    required this.id,
    required this.caip2,
    required this.network,
  });

  static NetworkType fromValue(int? value) {
    return values.firstWhere((e) => e.id == value,
        orElse: () => throw WalletExceptionConst.incorrectNetwork);
  }

  static NetworkType fromTags(List<int>? tags) {
    return values.firstWhere((e) => e.identifier.isValidTags(tags),
        orElse: () => throw WalletExceptionConst.incorrectNetwork);
  }

  static NetworkType fromIdentifier(int? identifier) {
    return values.firstWhere((e) => e.identifier.id == identifier,
        orElse: () => throw WalletExceptionConst.incorrectNetwork);
  }

  static NetworkType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw WalletExceptionConst.incorrectNetwork);
  }

  @override
  String toString() {
    return "NetworkType.$name";
  }
}
