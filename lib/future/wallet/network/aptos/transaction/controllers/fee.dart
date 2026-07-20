import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain/aptos/src/transaction/constants/const.dart';
import 'package:on_chain/aptos/src/transaction/types/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

import 'provider.dart';

mixin AptosTransactionFeeController on AptosTransactionApiController {
  WalletAptosNetwork get network;
  final Cancelable _cancelable = Cancelable();
  final _lock = SafeAtomicLock();

  late final AptosTransactionFeeData txFee = AptosTransactionFeeData(
      select: AptosTransactionFee(gasUnitPrice: BigInt.zero, network: network),
      feeToken: network.token);
  void setDefaultFee({String? error}) {
    txFee.setFee(
        AptosTransactionFee(gasUnitPrice: BigInt.zero, network: network, error: error));
  }

  Future<AptosSignedTransaction> simulateTransaction(
      {required BigInt maxGasAmount, required BigInt gasUnitPrice});

  Future<IAptosTransactionSimulateInfo> simulateFee(BigInt? balance) async {
    final gasPrice = await getGasPrice();
    BigInt gasAmount = AptosConstants.defaultMaxGasAmount;
    if (balance != null && gasPrice != BigInt.zero) {
      gasAmount = balance ~/ gasPrice;
      if (gasAmount < AptosConstants.defaultMinGasAmount) {
        gasAmount = AptosConstants.defaultMinGasAmount;
      } else if (gasAmount > AptosConstants.defaultMaxGasAmount) {
        gasAmount = AptosConstants.defaultMaxGasAmount;
      }
    }
    final transaction =
        await simulateTransaction(gasUnitPrice: gasPrice, maxGasAmount: gasAmount);
    final simulateResult = await simulate(rawTransaction: transaction.rawTransaction);
    if (!simulateResult.success) {
      throw AppException(simulateResult.vmStatus);
    }
    return IAptosTransactionSimulateInfo(
        vmStatus: simulateResult.vmStatus, simulateTx: simulateResult);
  }

  Future<void> estimateFee({BigInt? accountBalance}) async {
    _cancelable.cancel();
    await _lock.run(() async {
      setDefaultFee();
      txFee.setPending();
      final fee = await IResult.call(() async => await simulateFee(accountBalance));
      if (fee.err()?.canceled() ?? false) return;
      if (fee.isErr) {
        setDefaultFee(error: fee.unwrapErr().localizationError);
        return;
      }
      final feeData = fee.unwrap();
      if (!feeData.isSuccess) {
        setDefaultFee(error: feeData.vmStatus);
        return;
      }
      txFee.setFee(AptosTransactionFee(
          gasUsed: feeData.simulateTx.gasUsed,
          gasUnitPrice: feeData.simulateTx.gasUnitPrice,
          simulateInfo: feeData,
          network: network));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
  }
}
