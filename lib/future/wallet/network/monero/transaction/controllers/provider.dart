import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/non_encrypted/requests/monero_generate_ring_output.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin MoneroTransactionApiController on DisposableMixin {
  MoneroNetworkClient get client;
  WalletProvider get walletProvider;
  WalletMoneroNetwork get network;

  late final CachedObject<DaemonGetEstimateFeeResponse> _estimateFee =
      CachedObject(interval: Duration(seconds: network.coinParam.averageBlockTime));

  Future<List<SpendablePayment<MoneroLockedPayment>>> buildRingOutput(
      List<MoneroLockedPayment> payments) async {
    BigInt maxGlobalIndex = BigInt.zero;
    for (final i in payments) {
      final globalIndex = i.globalIndex;
      if (globalIndex > maxGlobalIndex) {
        maxGlobalIndex = globalIndex;
      }
    }
    final result = (await walletProvider.wallet.doAction(WalletActionCryptoRequest(
            request: NoneEncryptedRequestGenerateRingOutput(
                provider: client.networkProvider.provider,
                payments: payments,
                maxGlobalIndex: maxGlobalIndex))))
        .unwrap();
    return result.payments;
  }

  Future<DaemonGetEstimateFeeResponse> getFeeEstimate() async {
    return _estimateFee.get(onFetch: () async => await client.getFeeEstimate());
  }
}
