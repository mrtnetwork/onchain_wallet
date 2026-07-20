import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

mixin ZcashTransactionFeeController on DisposableMixin {
  WalletZcashNetwork get network;
  final _lock = SafeAtomicLock();
  final _cancelabe = Cancelable();
  final Zip317FeeRole _feeRole = Zip317FeeRole();
  late final ZcashTransactionFeeData txFee = ZcashTransactionFeeData(
      select: ZcashTransactionFee(
          type: TxFeeTypes.normal, fee: IntegerBalance.zero(network.token)),
      feeToken: network.token);

  Future<ZcashTransactionFeeInfo> buildFeeData();
  void setFees({BigInt? fee}) {
    txFee.setDefaultFees([
      ZcashTransactionFee(
          type: TxFeeTypes.normal,
          fee: IntegerBalance.token(fee ?? BigInt.zero, network.token),
          error: fee == null ? "fee_estimate_failed".tr : null)
    ]);
  }

  BigInt getMaxFeeInput();

  Future<void> estimateFee() async {
    _cancelabe.cancel();
    await _lock.run(() async {
      txFee.setPending();
      final fee = await IResult.call(() async {
        final feeData = await buildFeeData();
        return _feeRole.feeRequired(
            trasparentInputSizes: feeData.trasparentInputSizes,
            transparentOutputSizes: feeData.transparentOutputSizes,
            saplingInputCount: feeData.saplingInputCount,
            saplingOutputCount: txFee.saplingBundle.numOutputs(
                numSpends: feeData.saplingInputCount,
                numOutputs: feeData.saplingOutputCount),
            orchardActionCount: txFee.orchardBundle.numActions(
                numSpends: feeData.orchardInputCount,
                numOutputs: feeData.orchardOutputCount));
      }, cancelable: _cancelabe);
      if (fee.err()?.canceled() ?? false) return;
      if (fee.isErr) {
        setFees();
        return;
      }
      setFees(fee: fee.unwrap().toZatoshi());
    });
  }
}
