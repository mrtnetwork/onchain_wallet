import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/non_encrypted/requests/monero_build_fake_tx.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin MoneroTransactionFeeController on MoneroTransactionApiController {
  final Cancelable _cancelable = Cancelable();
  final _lock = SafeAtomicLock();

  late final MoneroTransactionFeeData txFee = MoneroTransactionFeeData(
      select: MoneroTransactionFee(
          fee: IntegerBalance.zero(network.token), type: TxFeeTypes.normal),
      feeToken: network.token);

  void setFees({required BigInt weight, required DaemonGetEstimateFeeResponse baseFee}) {
    List<BigInt> feesAmount = [];
    final feeTypes = MoneroFeePrority.getFeeProrities(baseFee);
    for (final i in feeTypes) {
      feesAmount.add(i.calcuateFee(weight: weight, baseFee: baseFee));
    }
    feesAmount = feesAmount.take(3).toList();
    feesAmount.sort((a, b) => a.compareTo(b));
    List<MoneroTransactionFee> fees = List.generate(feesAmount.length, (index) {
      final fee = feesAmount[index];
      return MoneroTransactionFee(
          type: switch (index) {
            0 => TxFeeTypes.slow,
            1 => TxFeeTypes.normal,
            _ => TxFeeTypes.high
          },
          fee: IntegerBalance.token(fee, network.token));
    });
    if (fees.length == 1) {
      txFee.setDefaultFees([fees.first.copyWith(type: TxFeeTypes.normal)]);
      return;
    }
    txFee.setDefaultFees(fees);
  }

  void setDefaultFee({String? error}) {
    final defaultFee = MoneroTransactionFee(
      error: error,
      fee: IntegerBalance.zero(network.token),
      type: TxFeeTypes.normal,
    );

    txFee.setDefaultFees([defaultFee]);
  }

  Future<IMoneroTransactionData> simulateTransaction();

  Future<(BigInt, DaemonGetEstimateFeeResponse)> simulateFee() async {
    final baseFee = await getFeeEstimate();
    final transaction = await simulateTransaction();
    final destinations = transaction.destinations;
    final fakePayments =
        transaction.payments.map((e) => e.toUnlockedFakePayment()).toList();
    final weight = await walletProvider.wallet.doAction(
      WalletActionCryptoRequest(
          request: NoneEncryptedRequestFakeMoneroTx(
              destinations: destinations
                  .map((e) => MoneroTxDestination(
                      amount: e.amount.balance, address: e.recipient.networkAddress))
                  .toList(),
              fee: txFee.fee.fee.balance,
              change: transaction.change,
              fakePayments: fakePayments)),
    );
    return (weight.unwrap().data + MoneroConst.extraTxWeight, baseFee);
  }

  Future<void> estimateFee() async {
    _cancelable.cancel();
    await _lock.run(() async {
      txFee.setPending();
      final weight = await IResult.call(() async => await simulateFee());
      if (weight.err()?.canceled() ?? false) return;
      if (weight.isErr) {
        setDefaultFee(error: weight.unwrapErr().localizationError);
        return;
      }
      final feeData = weight.unwrap();
      setFees(weight: feeData.$1, baseFee: feeData.$2);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
  }
}
