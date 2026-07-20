import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';

mixin SolanaTransactionApiController on DisposableMixin {
  SolanaNetworkClient get client;
  Future<SolAddress> getTransactionBlockHash({bool simulate = false}) async {
    if (simulate) return SolAddress.defaultPubKey;
    final blockHash =
        await client.provider.request(const SolanaRequestGetLatestBlockhash());
    return blockHash.blockhash;
  }

  Future<SolanaMintAccount?> getMintAccount(SolAddress mintAddress) async {
    return await client.getMintAccount(mintAddress);
  }

  Future<SolanaAccountInfo?> getAccountInfo(SolAddress account) async {
    final info = await client.getAccountInfo(account);
    return info;
  }
}
