import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin SolanaTransactionFeeController on BaseSolanaTransactionController {
  final Cancelable _cancelable = Cancelable();

  @override
  late final SolanaTransactionFeeData txFee = SolanaTransactionFeeData(
      select: SolanaTransactionFee.defaultFee(feeToken: network.token),
      feeToken: network.token);

  void setDefaultFee({String? error}) {
    txFee.setFee(SolanaTransactionFee.defaultFee(feeToken: network.token, error: error));
  }

  Future<SolanaTransactionFee> simulateFee(
      {required BigInt accountBalance, required BigInt totalTxLamports}) async {
    final transaction = await buildTransaction(simulate: true);
    final simulate = await client.simulate(
        transaction: transaction.transaction, account: address.networkAddress);
    if (simulate.accounts?.length != 1) {
      throw AppException("transaction_simulation_failed");
    }
    if (simulate.err != null) {
      if (simulate.logs?.isNotEmpty ?? false) {
        throw AppException(simulate.logs!.join(", "));
      }
      throw AppException(simulate.err.toString());
    }
    final change = accountBalance - simulate.accounts![0]!.lamports;
    final fee = change - totalTxLamports;
    return SolanaTransactionFee(fee: IntegerBalance.token(fee, network.token));
  }

  @override
  Future<void> estimateFee({BigInt? accountBalance, BigInt? totalTxLamports}) async {
    if (accountBalance == null || totalTxLamports == null) return;
    _cancelable.cancel();
    setDefaultFee();
    txFee.setPending();

    final fee = await IResult.call(() async => await simulateFee(
        accountBalance: accountBalance, totalTxLamports: totalTxLamports));
    if (fee.err()?.canceled() ?? false) return;
    if (fee.isErr) {
      setDefaultFee(error: fee.unwrapErr().localizationError);
      return;
    }
    txFee.setFee(fee.unwrap());
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
  }
}
