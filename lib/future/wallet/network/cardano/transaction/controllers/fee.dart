import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'provider.dart';

mixin ADATransactionFeeController
    on BaseADATransactionController, ADATransactionApiController {
  final Cancelable _cancelable = Cancelable();
  final _lock = SafeAtomicLock();
  @override
  late final ADATransactionFeeData txFee = ADATransactionFeeData(
      select: ADATransactionFee(
          fee: IntegerBalance.zero(network.token), type: TxFeeTypes.normal),
      feeToken: network.token);

  Future<ADATransactionFee> simulateFee() async {
    final params = await latestEpochProtocolParameters();
    final transaction = await buildTransaction(simulate: true);
    final signedTx = await signTransaction(transaction, fakeSignature: true);
    final size = signedTx.finalTransactionData.size;
    final fee = params.calculateFee(size);
    return ADATransactionFee(
        type: TxFeeTypes.normal, fee: IntegerBalance.token(fee, network.token));
  }

  @override
  Future<void> estimateFee() async {
    _cancelable.cancel();
    await _lock.run(() async {
      txFee.setPending();

      final fee = await IResult.call(() async => await simulateFee());
      if (fee.err()?.canceled() ?? false) return;
      if (fee.isErr) {
        txFee.setDefaultFees([
          ADATransactionFee(
              type: TxFeeTypes.normal,
              fee: IntegerBalance.zero(network.token),
              error: fee.unwrapErr().localizationError)
        ]);
        return;
      }
      txFee.setDefaultFees([fee.unwrap()]);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
  }
}
