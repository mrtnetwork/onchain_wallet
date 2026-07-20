import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/constant/networks/bitcoin.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin BtocinTransactionApiController on DisposableMixin {
  BitcoinNetworkClient get client;
  WalletBitcoinNetwork get network;

  final CachedObject<BitcoinFeeRate?> _estimateFee =
      CachedObject(interval: Duration(seconds: 120));

  Future<BitcoinFeeRate?> getFeeRate() async {
    return _estimateFee.get(onFetch: () async {
      final fee = (await IResult.call(() => client.getFeeRate(),
              logOnDebug: true, mode: LoggerMode.info))
          .ok();
      if (fee == null && !network.coinParam.chainType.isMainnet) {
        return BitcoinFeeRate(
            high: BtcConst.minFeePerKb,
            medium: BtcConst.minFeePerKb,
            low: BtcConst.minFeePerKb);
      }
      return fee;
    });
  }
}
