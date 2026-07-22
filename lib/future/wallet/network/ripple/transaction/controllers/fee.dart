import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

import 'provider.dart';

mixin RippleTransactionFeeController on DisposableMixin, XRPTransactionApiController {
  WalletXRPNetwork get network;
  final _lock = SafeAtomicLock();
  final Cancelable _cancelable = Cancelable();
  FeeResult? _feeRate;
  String? _fulfillment;

  late final RippleTransactionFeeData txFee = RippleTransactionFeeData(
      select: RippleTransactionFee(
          fee: IntegerBalance.zero(network.token), type: TxFeeTypes.normal),
      feeToken: network.token);

  void _setFee({String? error}) {
    final fee = txFee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.normal);
    txFee.setDefaultFees([
      fee?.copyWith(error: error) ??
          RippleTransactionFee(
              fee: IntegerBalance.zero(network.token),
              type: TxFeeTypes.normal,
              error: error)
    ]);
  }

  List<RippleTransactionFee> _buildDefaultFees(FeeResult fee, {String? fulfillment}) {
    return XrplFeeType.values.map((e) {
      final f = RippleUtils.calculateFee(fee.getFeeType(type: e), txFee.transactionType,
          fulfillment: fulfillment, multiSigners: txFee.multiSigner);
      return RippleTransactionFee(
          type: switch (e) {
            XrplFeeType.open => TxFeeTypes.slow,
            XrplFeeType.minimum => TxFeeTypes.normal,
            _ => TxFeeTypes.high
          },
          fee: IntegerBalance.token(f, network.token));
    }).toList();
  }

  Future<SubmittableTransaction> simulateTransaction();

  Future<SubmittableTransaction> simulateFee() async {
    _feeRate ??= await getFeeData();
    final submitableTx = await simulateTransaction();
    if (submitableTx.transactionType == SubmittableTransactionType.escrowFinish) {
      final escrowFinis = submitableTx as EscrowFinish;
      if (_fulfillment != escrowFinis.fulfillment) {
        final fees = _buildDefaultFees(_feeRate!, fulfillment: escrowFinis.fulfillment);
        txFee.setDefaultFees(fees);
        _fulfillment = escrowFinis.fulfillment;
        return simulateFee();
      }
    }
    final result = await client.simulateTx(submitableTx);
    if (!result.isSuccess) {
      throw AppException(result.engineResult, localizedMessage: true);
    }
    return submitableTx;
  }

  Future<void> estimateFee() async {
    _cancelable.cancel();
    await _lock.run(() async {
      txFee.setPending();
      final transaction = await IResult.call(() async => await simulateFee());
      if (transaction.err()?.canceled() ?? false) return;
      if (transaction.isErr) {
        _setFee(error: transaction.unwrapErr().localizationError);
        return;
      }
      final submitableTx = transaction.unwrap();
      if (submitableTx.transactionType == SubmittableTransactionType.escrowFinish) {
        final escrowFinis = submitableTx as EscrowFinish;
        final fees = _buildDefaultFees(_feeRate!, fulfillment: escrowFinis.fulfillment);
        txFee.setDefaultFees(fees);
      }
      if (txFee.fee.hasError) {
        final fees = _buildDefaultFees(_feeRate!);
        txFee.setDefaultFees(fees);
      } else {
        txFee.setProcess();
      }
    });
  }

  Future<void> initFee(
      {required int multiSigner, required SubmittableTransactionType type}) async {
    txFee.init(multiSigner: multiSigner, transactionType: type);
    _feeRate = await getFeeData();
    final fees = _buildDefaultFees(_feeRate!);
    txFee.setDefaultFees(fees);
  }

  @override
  void dispose() {
    super.dispose();

    txFee.dispose();
  }
}
