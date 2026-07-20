import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

import 'provider.dart';

mixin SubstrateTransactionFeeController on SubstrateTransactionApiController {
  WalletSubstrateNetwork get network;
  final Cancelable _cancelable = Cancelable();
  final _lock = SafeAtomicLock();

  late final SubstrateTransactionFeeData txFee = SubstrateTransactionFeeData(
      select: SubstrateTransactionFee.init(network.token), feeToken: network.token);

  void setDefaultFee({String? error, Token? token}) {
    txFee.setFee(SubstrateTransactionFee.init(token ?? network.token, error: error));
  }

  Future<SubstrateEstimateTransaction> simulateTransaction();

  Future<SubstrateTransactionFee> simulateFee() async {
    final signexTx = await simulateTransaction();
    final feeInfo = await client.queryFeeInfo(extrinsic: signexTx.extrinsic.serialize());
    final dryRun = await client.dryRunCall(
        owner: signexTx.owner, callData: signexTx.extrinsic.payload.methodBytes);
    SubstrateTransactionAssetFee? assetFee;
    final feeConfig = signexTx.fee;
    if (feeConfig != null) {
      final fee = await client.quotePriceTokensForExactTokens(
          baseAsset: feeConfig.baseFee.location,
          asset: feeConfig.assetLocation.getLocation(),
          amount: feeInfo.partialFee);
      assetFee = SubstrateTransactionAssetFee(config: feeConfig, amount: fee);
    }
    return SubstrateTransactionFee.fromFeeDetails(
        network: network, info: feeInfo, dryRun: dryRun, assetFeeInfo: assetFee);
  }

  Future<void> estimateFee() async {
    // 007181
    _cancelable.cancel();
    await _lock.run(() async {
      setDefaultFee();
      txFee.setPending();
      final fee = await IResult.call(() async => await simulateFee());
      if (fee.err()?.canceled() ?? false) return;
      if (fee.isErr) {
        setDefaultFee(error: fee.unwrapErr().localizationError);
        return;
      }
      SubstrateTransactionFee finalFee = fee.unwrap();
      final dryRun = finalFee.dryRun;
      final dryRunSuccess = dryRun?.ok?.executionResult.type.isOk ?? false;
      final assetFee = finalFee.assetFeeInfo;
      if (dryRun != null && !dryRunSuccess) {
        finalFee = finalFee.copyWith(
            error: "transaction_dry_run_failed".tr,
            fee: finalFee.fee.clone(balance: BigInt.zero));
      } else if (assetFee != null && assetFee.convertedAmount == null) {
        finalFee = finalFee.copyWith(
            error: "convert_fee_amount_failed_to_token"
                .tr
                .replaceOne(assetFee.config.token.symbol));
      }
      txFee.setFee(finalFee);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
  }
}
