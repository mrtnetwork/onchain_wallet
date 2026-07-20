import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

mixin BitcoinTransactionFeeController on BtocinTransactionApiController {
  @override
  WalletBitcoinNetwork get network;
  final _lock = SafeAtomicLock();
  final _cancelabe = Cancelable();
  bool get supportRbf => network.coinParam.rbfSupport;

  late final BitcoinTransactionFeeData txFee = BitcoinTransactionFeeData(
      select: BitcoinTransactionFee(
          type: TxFeeTypes.normal,
          feeToken: network.token,
          feePerKB: BigInt.zero,
          transactionSize: 0),
      feeToken: network.token);

  void setFees({BitcoinFeeRate? feeRate, int? transactionSize}) {
    List<BitcoinTransactionFee> fees = [];
    transactionSize ??= txFee.transactionSize ?? 200;

    if (feeRate == null) {
      fees.add(BitcoinTransactionFee(
          type: TxFeeTypes.normal,
          feeToken: network.token,
          feePerKB: BigInt.zero,
          transactionSize: 0,
          error: "fee_estimate_failed".tr));
    } else {
      final feeRates = {feeRate.low, feeRate.medium, feeRate.high};
      if (feeRates.length == 1) {
        fees.add(BitcoinTransactionFee(
            type: TxFeeTypes.normal,
            feeToken: network.token,
            feePerKB: feeRates.elementAt(0),
            transactionSize: transactionSize));
      } else {
        for (int i = 0; i < feeRates.length; i++) {
          fees.add(BitcoinTransactionFee(
              type: switch (i) {
                0 => TxFeeTypes.slow,
                1 => TxFeeTypes.normal,
                _ => TxFeeTypes.high
              },
              feeToken: network.token,
              feePerKB: feeRates.elementAt(i),
              transactionSize: transactionSize));
        }
      }
    }
    txFee.setDefaultFees(fees);
  }

  BigInt getMaxFeeInput();

  Future<BtcTransaction> buildSimulateTransaction();

  Future<(int, BitcoinFeeRate?)> simulateFee() async {
    final feeRate = await getFeeRate();

    final signedTx = await buildSimulateTransaction();
    return (signedTx.getVSize(), feeRate);
  }

  Future<void> estimateFee() async {
    _cancelabe.cancel();
    await _lock.run(() async {
      txFee.setPending();
      final size = await IResult.call(() async {
        return await simulateFee();
      });
      if (size.err()?.canceled() ?? false) {
        return;
      }
      if (size.isErr) {
        setFees();
        return;
      }
      final feeData = size.unwrap();
      txFee.onUpdateTransactionSize(feeData.$1);
      setFees(transactionSize: feeData.$1, feeRate: feeData.$2);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelabe.cancel();
    txFee.dispose();
  }
}
