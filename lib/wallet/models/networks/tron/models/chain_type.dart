import 'package:on_chain_wallet/app/core.dart';

enum TronChainType {
  mainnet(id: 1001, genesisBlockNumber: 728126428),
  shasta(id: 1002, genesisBlockNumber: 2494104990),
  nile(id: 1003, genesisBlockNumber: 3448148188);

  const TronChainType({required this.id, required this.genesisBlockNumber});

  final int id;
  final int genesisBlockNumber;

  static TronChainType fromId(int? id) {
    return values.firstWhere((e) => e.id == id,
        orElse: () => throw AppInternalError.internalError("TronChainType"));
  }
}
