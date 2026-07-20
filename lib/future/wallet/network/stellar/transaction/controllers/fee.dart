import 'dart:async';

import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/constant/constant.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:stellar_dart/stellar_dart.dart';

import 'provider.dart';

mixin StellarTransactionFeeController
    on BaseStellarTransactionController, StellarTransactionApiController {
  final Cancelable _cancelable = Cancelable();
  StreamSubscription<StellarFetchedFeeStats>? _listener;
  late StellarTransactionFee _defaultFee = StellarTransactionFee(
      fee: IntegerBalance.zero(network.token), type: TxFeeTypes.normal);
  @override
  late final StellarTransactionFeeData txFee =
      StellarTransactionFeeData(select: _defaultFee, feeToken: network.token);

  @override
  BigInt getMaxFeeInput() {
    final max = super.getMaxFeeInput();
    if (max > StellarConst.maxFee) {
      return StellarConst.maxFee;
    }
    return max;
  }

  void setDefaultFee({String? error}) {
    txFee.setFee(_defaultFee.copyWith(error: error));
  }

  StellarTransactionFee _calculateFee(
      {required TxFeeTypes mode,
      required StellarFeeStatsResponse feeStats,
      required int operations}) {
    int minFee = int.parse(feeStats.maxFee.p10);
    switch (mode) {
      case TxFeeTypes.normal:
        minFee = int.parse(feeStats.maxFee.p50);
        break;
      case TxFeeTypes.high:
        minFee = int.parse(feeStats.maxFee.p90);
        break;
      default:
        break;
    }
    final fee = minFee * (operations == 0 ? 1 : operations);
    return StellarTransactionFee(
        fee: IntegerBalance.token(BigInt.from(fee), network.token), type: mode);
  }

  List<StellarTransactionFee> _buildFees(
      StellarFeeStatsResponse feeStats, int operations) {
    return [TxFeeTypes.slow, TxFeeTypes.normal, TxFeeTypes.high]
        .map((e) => _calculateFee(mode: e, feeStats: feeStats, operations: operations))
        .toList();
  }

  void _onUpdateFee(StellarFetchedFeeStats feeStats) {
    final fess = _buildFees(feeStats.stats, feeStats.operations);
    txFee.setDefaultFees(fess);
    _defaultFee = fess.firstWhere((e) => e.type == TxFeeTypes.normal);
  }

  void _estimateFee(int operations) {
    _listener?.cancel();
    _listener = null;
    _listener = _fetchGasFee(operations: operations).listen(_onUpdateFee);
  }

  @override
  Future<void> estimateFee({int operations = 1}) async {
    _estimateFee(operations);
  }

  Future<StellarFetchedFeeStats> simulateFee({int operations = 1}) async {
    final feeState = await this.feeState();
    return StellarFetchedFeeStats(stats: feeState, operations: operations);
  }

  Stream<StellarFetchedFeeStats> _fetchGasFee({int operations = 1}) {
    final controller = SafeStreamController<StellarFetchedFeeStats>(
        name: "StellarTransactionFeeController");
    bool isClosed = false;
    Future<void> poll() async {
      if (isClosed) return;
      txFee.setPending();
      final feeState = await () async {
        try {
          return await simulateFee(operations: operations);
        } catch (_) {
          return null;
        }
      }();
      if (feeState != null && !isClosed) {
        controller.add(feeState);
      }

      if (!isClosed) {
        await Future.delayed(
            Duration(seconds: feeState == null ? 3 : network.coinParam.averageBlockTime));
        poll();
      }
    }

    controller.onListenListener(poll);
    controller.onCancelListener(() {
      isClosed = true;
    });

    return controller.stream();
  }

  Future<void> initFee() async {
    final feeState = await this.feeState();
    final fess = _buildFees(feeState, 1);
    txFee.setDefaultFees(fess);
    _defaultFee = fess.firstWhere((e) => e.type == TxFeeTypes.normal);
    _estimateFee(1);
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
    _listener?.cancel();
  }
}
