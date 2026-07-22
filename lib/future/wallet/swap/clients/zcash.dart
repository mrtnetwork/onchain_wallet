import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';

class ZcashSwapClinet implements BaseSwapZcashClient {
  final ZcashNetworkClient client;
  const ZcashSwapClinet(this.client);
  @override
  Future<BigInt?> getBlockHeight() async {
    final height = await client.getLatestBlockHeight();
    return BigInt.from(height);
  }

  @override
  Future<bool> initSwapClient() {
    return client.initSwapClient();
  }
}
